\ LCD FUNCTIONS -- funcs_4x20_lcd.asm ------------------------------------------

\ Character addresses for 20x4 display:
\ Line 0 :  0 ($0)  -  19 ($13)
\ Line 1 : 64 ($40) -  83 ($53)
\ Line 2 : 20 ($14) -  39 ($27)
\ Line 3 : 84 ($54) - 103 ($67)


\ ------------------------------------------------------------------------------
\ ---  DELAY
\ ---  Implements: OSDELAY
\ ------------------------------------------------------------------------------
\ General-purpose delay function. Blocking.
\ ON ENTRY: Assumes a 16-bit value in LCDV_TIMER_INTVL. This number should be
\           the length of the desired delay in milliseconds.
.delay
  pha
  stz LCDV_TIMER_COUNT		    ; Zero-out counter
  stz LCDV_TIMER_COUNT + 1
  lda LCDV_IER
  ora #%11000000		          ; Bit 7 enables interrupts, bit 6 enables Timer 1
  sta LCDV_IER
  lda #%01000000              ; Set timer to free-run mode
  sta LCDV_ACL
  lda #$E6				  ; Going to use a base of 1ms. At 1MHz that's 1K cycles but,
  sta LCDV_T1CL     ; allowing for other operations, it's actually 998 ($03E6)
  lda #$03
  sta LCDV_T1CH		            ; Starts timer running
.delay_loop
  lda #100
.nop_loop                     ; Adding a small NOP loop to give the timer time
  nop                         ; to increase the counter
  dec A
  bne nop_loop
  jsr delay_timer_chk         ; Check how far our counter has got
  lda FUNC_RESULT
  cmp #LESS_THAN
  beq delay_loop              ; If still less than our target, go around again
  lda LCDV_IER
  and #%01111111              ; Disable TIMER 1 interrupts
  sta LCDV_IER
  pla
  stz FUNC_RESULT             ; Done with this, so zero out
  rts

.delay_timer_chk              ; Check to see if the counter has incremented
  sei                         ; to the same value as the set delay.
  lda LCDV_TIMER_COUNT+1      ; Compare the high bytes first as if they aren't
  cmp LCDV_TIMER_INTVL+1      ; equal, we don't need to compare the low bytes
  bcc delay_timer_chk_less_than                 ; Count is less than interval
  bne delay_timer_chk_more_than                 ; Count is more than interval
  lda LCDV_TIMER_COUNT        ; High bytes were equal - what about low bytes?
  cmp LCDV_TIMER_INTVL
  bcc delay_timer_chk_less_than
  bne delay_timer_chk_more_than
  lda #EQUAL				          ; COUNT = INTVL - this what we're looking for.
  jmp delay_timer_chk_end
.delay_timer_chk_less_than
  lda #LESS_THAN			        ; COUNT < INTVL - counter isn't big enough yet
  jmp delay_timer_chk_end     ; so let's bug out.
.delay_timer_chk_more_than
  lda #MORE_THAN			        ; COUNT > INTVL - shouldn't happen, but still...
.delay_timer_chk_end
  sta FUNC_RESULT
  cli
  rts

\ ------------------------------------------------------------------------------
\ ---  LCD_CLEAR_BUF
\ ------------------------------------------------------------------------------
\ Fill the LCD buffer with spaces
.lcd_clear_buf
  ldy #0
  lda #CHR_SPACE
.lcd_clear_buf_next
  sta LCD_BUF, Y
  iny
  cpy #LCD_BUF_SZ
  bne lcd_clear_buf_next
  rts

\ ------------------------------------------------------------------------------
\ ---  LCD_CLEAR_SIG
\ ------------------------------------------------------------------------------
\ Clear the RS, RW & E bits on PORT A
.lcd_clear_sig
  pha
  lda LCDV_PORTA
  and #%00011111
  sta LCDV_PORTA
  pla
  rts

\ ------------------------------------------------------------------------------
\ ---  LCD_CMD
\ ------------------------------------------------------------------------------
\ Send a command to the LCD
\ ON ENTRY: A must contain command byte
.lcd_cmd
;  pha                              ; preserve A on the stack
  jsr lcd_wait                      ; check LCD is ready to receive
  sta LCDV_PORTB                    ; assumes command byte is in A
  jsr lcd_clear_sig                 ; Clear RS/RW/E bits. Writing to instr reg
  LCD_SET_CTL LCD_EX                ; Set E bit to send instruction
  jsr lcd_clear_sig
;  pla
  rts

\ ------------------------------------------------------------------------------
\ ---  LCD_PRT_LINEBUF
\ ------------------------------------------------------------------------------
\ Prints a line's worth from the LCD_BUF buffer.
\ ON ENTRY: Y must contain line index - 0-3 for a 4-line display
.lcd_prt_linebuf
  pha : phx : phy
  ldx #0                      ; Set cursor to start of line
  jsr lcd_set_cursor          ; Now done with X
  lda #0                      ; Use to calculate offset
.lcd_prt_linebuf_set_offset   ; Calculate the offset for LCD_BUF
  cpy #0                      ; If Y is (or has decremented to) 0, we're done.
  beq lcd_prt_linebuf_prt
  clc
  adc #LCD_LN_BUF_SZ          ; Otherwise, add line length to the offset
  dey                         ; Decrement line number and go around again
  jmp lcd_prt_linebuf_set_offset
.lcd_prt_linebuf_prt
  tay                         ; Store the offset in Y
  ldx #0                      ; To keep track of how many chars printed
.lcd_prt_linebuf_prtchr
  lda LCD_BUF,Y               ; Load a char from the buffer
  beq lcd_prt_linebuf_end     ; Finish if we loaded a null terminator
  jsr lcd_prt_chr             ; Display the character
  iny                         ; Increment buffer offset
  inx                         ; Increment character counter
  cpx #LCD_LN_BUF_SZ          ; Have we printed a line's worth?
  beq lcd_prt_linebuf_end     ; If so, done.
  jmp lcd_prt_linebuf_prtchr  ; Else, go around again
.lcd_prt_linebuf_end
  ply : plx : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  LCD_WAIT
\ ------------------------------------------------------------------------------
\ Wait until LCD is ready to receive next byte. Blocking!
.lcd_wait         ; Check to see if LCD is ready to receive next byte
  pha             ; Save current contents of A in stack, so it isn't corrupted
  lda #%00000000  ; Set Port B as input
  sta LCDV_DDRB
.lcd_busy
  LCD_SET_CTL LCD_RW
  ora #(LCD_RW OR LCD_EX)
  sta LCDV_PORTA
  lda LCDV_PORTB
  and #LCD_BUSY_FLAG      ; Sets zero flag - non-0 if LCD busy flag set
  bne lcd_busy            ; If result was non-0, keep looping
  LCD_SET_CTL LCD_RW
  lda #%11111111          ; Set Port B as output
  sta LCDV_DDRB
  pla                     ; pull previous A contents back from stack
  rts

;.lcd_prt_msg	            ; assumes LSB of msg address at MSG_VEC
;  ldy #0                  ; and MSB at MSG_VEC+1
;.lcd_prt_msg_chr
;  lda (MSG_VEC),Y         ; LDA sets zero flag if it's loaded with 0
;  beq lcd_prt_msg_end     ; BEQ branches if zero flag set
;  jsr lcd_prt_chr         ; display the character
;  iny                     ; increment message string offset
;  jmp lcd_prt_msg_chr     ; go around again
;.lcd_prt_msg_end
;  rts

\ ------------------------------------------------------------------------------
\ ---  OS API Functions
\ ------------------------------------------------------------------------------

\ ------------------------------------------------------------------------------
\ ---  LCD_CLS
\ ---  Implements: OSLCDCLS
\ ------------------------------------------------------------------------------
\ Clear the LCD screen
.lcd_cls
  jsr lcd_clear_buf                       ; Overwrite LCD_BUF with spaces
  lda #LCD_CLS                            ; Clear display, reset display memory
  jsr lcd_cmd
  rts

\ ------------------------------------------------------------------------------
\ ---  LCD_PRINT_BYTE
\ ---  Implements: OSLCDB2HEX
\ ------------------------------------------------------------------------------
\ Prints an 8-bit value as a 2-char hex string
\ ON ENTRY: A must contain value of byte to be printed.
.lcd_print_byte
  jsr byte_to_hex_str               ; Results in three bytes starting at STR_BUF
  lda STR_BUF
  jsr lcd_prt_chr
  lda STR_BUF + 1
  jsr lcd_prt_chr
  rts

\ ------------------------------------------------------------------------------
\ ---  LCD_PRT_BUF
\ ---  Implements: OSLCDWRBUF
\ ------------------------------------------------------------------------------
\ Prints the contents of STDOUT_BUF to LCD
\ ON ENTRY: Expects a nul-terminated string in STDOUT_BUF
.lcd_prt_buf
  pha
  lda #<STDOUT_BUF
  sta MSG_VEC
  lda #>STDOUT_BUF                              ; MSB of message
  sta MSG_VEC+1
  jsr lcd_println
  pla
  rts

\ ------------------------------------------------------------------------------
\ ---  LCD_PRT_SBUF
\ ---  Implements: OSLCDSBUF
\ ------------------------------------------------------------------------------
\ Prints the contents of STR_BUF to LCD
\ ON ENTRY: Expects a nul-terminated string in STR_BUF
.lcd_prt_sbuf
  pha
  lda #<STR_BUF
  sta MSG_VEC
  lda #>STR_BUF                              ; MSB of message
  sta MSG_VEC+1
  jsr lcd_println
  pla
  rts

\ ------------------------------------------------------------------------------
\ ---  LCD_PRINTLN
\ ---  Implements: OSLCDMSG
\ ------------------------------------------------------------------------------
\ Prints text to the LCD.
\ ON ENTRY: MSG_VEC should point to location of text.
.lcd_println
  pha : phx : phy
  ; Start index, to start copying FROM is start of line 1
  ldx #LCD_LN_BUF_SZ
  ; Start index, for where we want to copy lines TO, is 0
  ldy #0
.lcd_println_shift_buf
  lda LCD_BUF,X                 ; X = FROM
  sta LCD_BUF,Y                 ; Y = TO
  inx
  iny
  cpx #LCD_BUF_SZ               ; At end of buffer?
  bne lcd_println_shift_buf     ; If not, loop
.lcd_println_newline
  tya                           ; Y contains LCD_BUF index
  tax                           ; Transfer this to X
  ldy #0                        ; Index for new text pointed to by MSG_VEC
.lcd_println_new_txt            ; Add new message to last line of buffer
  lda (MSG_VEC),Y               ; Get next char from new text
  beq lcd_println_pad           ; If this char is a null, go to padding
  sta LCD_BUF,X                 ; Otherwise store it in the LCD buffer
  iny                           ; Increment indexes
  inx
  cpy #LCD_LN_BUF_SZ            ; Have we done a line's worth?
  beq lcd_println_terminate     ; If yes, make sure we include a terminator
  jmp lcd_println_new_txt       ; Otherwise loop
.lcd_println_pad                ; Pad line with spaces
  lda #CHR_SPACE
.lcd_println_pad_next
  cpy #LCD_LN_BUF_SZ            ; Have we already got a line's worth?
  beq lcd_println_terminate     ; If so, ensure we have a terminator
  sta LCD_BUF,X                 ; Otherwise add the space to the buffer
  iny                           ; Increment indexes
  inx
  jmp lcd_println_pad_next      ; Loop
.lcd_println_terminate          ; Ensure last char in line buffer is a 0
  dex                           ; X is currently one MORE than index for EOL
  stz LCD_BUF,X
;.lcd_println_refresh            ; Rewrite all lines of display
  ldy #0                        ; Index of lines
.lcd_println_refresh
  jsr lcd_prt_linebuf
  iny
  cpy #LCD_LINES                ; Have we done all lines yet?
  bne lcd_println_refresh       ; If not, loop
  ply : plx : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  LCD_PRT_CHR
\ ---  Implements: OSLCDCH
\ ------------------------------------------------------------------------------
.lcd_prt_chr
  pha
  jsr lcd_wait                      ; check LCD is ready to receive
  sta LCDV_PORTB
  LCD_SET_CTL LCD_RS
  LCD_SET_CTL (LCD_RS OR LCD_EX)    ; Keep RS & set E bit to send instruction
  LCD_SET_CTL LCD_RS                ; Clear E bits
  pla
  rts

\ ------------------------------------------------------------------------------
\ ---  LCD_PRT_ERR
\ ---  Implements: OSLCDERR
\ ------------------------------------------------------------------------------
\ ON ENTRY: Assumes error code in FUNC_ERR
.lcd_prt_err
  lda FUNC_ERR
  dec A                   ; To get offset for table
  asl A                   ; Shift left to multiply by 2
  tax                     ; Move to X to use as offset
  lda err_ptrs,X          ; Get LSB of relevant address from the cmd_ptrs table
  sta MSG_VEC             ; and put in MSG_VEC
  lda err_ptrs+1,X        ; Get MSB
  sta MSG_VEC+1           ; and put in MSG_VEC high byte
  jsr lcd_println
  rts

\ ------------------------------------------------------------------------------
\ ---  LCD_SET_CURSOR
\ ---  Implements: OSLCDSC
\ ------------------------------------------------------------------------------
\ ON ENTRY: X & Y co-ords must be in X and Y.
\           - X should contain the X param in range 0-19.
\           - Y should be 0-3.
.lcd_set_cursor
  stx TMP_VAL
  lda lcd_ln_base_addr,Y  ; Base address for line, from lookup table
  clc
  adc TMP_VAL
  ora #LCD_SET_DDRAM      ; OR with LCD_SET_DDRAM command byte
  jsr lcd_cmd
  rts
