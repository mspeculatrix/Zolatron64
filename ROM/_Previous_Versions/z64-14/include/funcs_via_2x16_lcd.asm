; FUNCTIONS: LCD -- funcs_lcd.asm ----------------------------------------------
; v08 - 10 Nov 2021
;

; ---  delay  ------------------------------------------------------------------
; general-purpose delay function. Assumes a 16-bit value in VIAA_TIMER_INTVL.
; This number should be the length of the desired delay in milliseconds.
.delay
  pha
  stz VIAA_TIMER_COUNT		    ; zero-out counter
  stz VIAA_TIMER_COUNT + 1
  lda #%11000000		          ; bit 7 enables interrupts, bit 6 enables Timer 1
  sta VIAA_IER
  lda #%01000000              ; set timer to free-run mode
  sta VIAA_ACL			
  lda #$E6				  ; going to use a base of 1ms. At 1MHz that's 1K cycles but
  sta VIAA_T1CL     ; allowing for other operations, it's actually 998 ($03E6)
  lda #$03
  sta VIAA_T1CH		            ; starts timer running
.delay_loop
  lda #100
.nop_loop                     ; adding a NOP loop to give the processor time
  nop                         ; to increase the counter
  dec A 
  bne nop_loop
  jsr delay_timer_chk         ; check how far our counter has got
  lda FUNC_RESULT
  cmp #LESS_THAN
  beq delay_loop              ; if still less tha our target, go around again
  lda #%01000000              ; disable TIMER 1 interrupts
  sta VIAA_IER
  pla
  rts


.delay_timer_chk              ; check to see if the counter has incremented
  sei                         ; to the same value as the set delay. This is
  pha                         ; basically a standard 16-bit comparison.
  lda VIAA_TIMER_COUNT+1      ; compare the high bytes first as if they aren't
  cmp VIAA_TIMER_INTVL+1      ; equal, we don't need to compare the low bytes
  bcc delay_timer_chk_less_than  ; count is less than interval
  bne delay_timer_chk_more_than  ; count is more than interval
  lda VIAA_TIMER_COUNT        ; high bytes were equal - what about low bytes?
  cmp VIAA_TIMER_INTVL
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
  pla
  cli
  rts

.lcd_clear_buf                ; fill LCD buffer with spaces
  ldy #0
  lda #CHR_SPACE
.lcd_clear_buf_next
  sta LCD_BUF, Y
  iny
  cpy LCD_BUF_SZ
  bne lcd_clear_buf_next
  rts

.lcd_wait         ; check to see if LCD is ready to receive next byte
  pha             ; save current contents of A in stack, so it isn't corrupted
  lda #%00000000  ; Set Port B as input
  sta VIAA_DDRB
.lcd_busy
  LCD_SET_CTL LCD_RW
  ora #(LCD_RW OR LCD_EX)
  sta VIAA_PORTA
  lda VIAA_PORTB
  and #LCD_BUSY_FLAG      ; Sets zero flag - non-0 if LCD busy flag set
  bne lcd_busy            ; If result was non-0, keep looping
  LCD_SET_CTL LCD_RW
  lda #%11111111          ; Set Port B as output
  sta VIAA_DDRB
  pla                     ; pull previous A contents back from stack
  rts

.lcd_clear_sig                      ; clear the RS, RW & E bits on PORT A
  lda VIAA_PORTA
  and #%00011111
  sta VIAA_PORTA
  rts

.lcd_cmd                            ; send a command to the LCD
  pha                               ; preserve A on the stack
  jsr lcd_wait                      ; check LCD is ready to receive
  sta VIAA_PORTB                    ; assumes command byte is in A
  jsr lcd_clear_sig                 ; Clear RS/RW/E bits. Writing to instr reg
  LCD_SET_CTL LCD_EX                ; Set E bit to send instruction
  jsr lcd_clear_sig
  pla
  rts

; ------------------------------------------------------------------------------
; ---  lcd_prt_chr  :  print a character to the LCD                          ---
; ------------------------------------------------------------------------------
.lcd_prt_chr                        ; assumes character is in A
  jsr lcd_wait                      ; check LCD is ready to receive
  sta VIAA_PORTB
  LCD_SET_CTL LCD_RS 
  LCD_SET_CTL (LCD_RS OR LCD_EX)    ; Keep RS & set E bit to send instruction
  LCD_SET_CTL LCD_RS                ; Clear E bits
  rts 

; ------------------------------------------------------------------------------
; ---  lcd_prt_linebuf  :  print a line from the buffer to the LCD           ---
; ------------------------------------------------------------------------------
.lcd_prt_linebuf
; Prints a line's worth from the LCD_BUF buffer. Which line is determined by the
; offset, which should be in Y (0 or 1 for a 2-line display, 0-3 for a 4-line).
  pha : phx : phy
  ldx #0                      ; set cursor to start of line
  jsr lcd_set_cursor          ; now done with X
  lda #0                      ; use to calculate offset
.lcd_prt_linebuf_set_offset   ; calculate the offset for LCD_BUF
  cpy #0                      ; if Y is (or has decremented to) 0, we're done.
  beq lcd_prt_linebuf_prt
  clc
  adc #LCD_LN_BUF_SZ          ; otherwise, add line length to the offset
  dey                         ; and go around again
  jmp lcd_prt_linebuf_set_offset
.lcd_prt_linebuf_prt
  tay                         ; store the offset in Y
  ldx #0                      ; to keep track of how many chars printed
.lcd_prt_linebuf_prtchr
  lda LCD_BUF,Y               ; load a char from the buffer
  beq lcd_prt_linebuf_end     ; finish if we loaded a null terminator
  jsr lcd_prt_chr             ; display the character
  iny                         ; increment buffer offset
  inx                         ; increment character counter
;  cpx #LCD_LN_BUF_SZ          ; have we printed a line's worth?
  cpx #LCD_COLS               ; have we printed a line's worth?
  beq lcd_prt_linebuf_end     ; if so, done.
  jmp lcd_prt_linebuf_prtchr  ; else, go around again
.lcd_prt_linebuf_end
  ply : plx : pla
  rts

; ------------------------------------------------------------------------------
; ---  lcd_println  :  print a line of text. Scroll existing lines           ---
; ------------------------------------------------------------------------------
.lcd_println
  pha : phx : phy
  ; Prints text to the LCD. The address of the text to be printed is assumed
  ; to be pointed to by MSG_VEC. The text is also written to the first line's
  ; worth of the LCD_BUF buffer, with other lines first being moved down a 
  ; line's worth. The last line's worth of existing text is overwritten.

  ; First, we'll copy existing data in the buffer, so that each byte gets
  ; shifted one line's worth of bytes later in the buffer. As the last line
  ; of the buffer is going to be overwritten, and its original contents lost,
  ; we start with the penultimate line.
  ldx #LCD_MOVE_SRC           ; offsets for source & destination for moving
  ldy #LCD_MOVE_DST           ; characters within the buffer
.lcd_println_move
  lda LCD_BUF,X               ; move a character
  sta LCD_BUF,Y
  cpx #0                      ; if source is at beginning of buffer, we're done
  beq lcd_println_move_done
  dey                         ; else, decrement offsets for next char positions
  dex
  jmp lcd_println_move
.lcd_println_move_done
  ldy #0
.lcd_println_move_msg         ; move new message into start of buffer
  lda (MSG_VEC),Y    
  sta LCD_BUF,Y
  cmp #0                      ; if this char is a null, we're done
  beq lcd_println_pad
  iny                         ; else, increment offset
  cpy #LCD_LN_BUF_SZ          ; have we done a line's worth?
  beq lcd_println_terminate
  jmp lcd_println_move_msg
.lcd_println_pad              ; pad line with spaces
  lda #CHR_SPACE
.lcd_println_pad_next
  cpy #LCD_LN_BUF_SZ
  beq lcd_println_terminate
  sta LCD_BUF,Y 
  iny
  jmp lcd_println_pad_next
.lcd_println_terminate        ; ensure last char in line buffer is a 0
  lda #0
  dey
  sta LCD_BUF,Y
.lcd_println_refresh          ; rewrite all lines of display
  ldy #0
.lcd_println_refresh_next
  jsr lcd_prt_linebuf
  iny
  cpy #LCD_LINES
  bne lcd_println_refresh_next
  ply : plx : pla
  rts

.lcd_prt_msg	            ; assumes LSB of msg address at MSG_VEC
  ldy #0                  ; and MSB at MSG_VEC+1
.lcd_prt_msg_chr
  lda (MSG_VEC),Y         ; LDA sets zero flag if it's loaded with 0
  beq lcd_prt_msg_end     ; BEQ branches if zero flag set
  jsr lcd_prt_chr         ; display the character
  iny                     ; increment message string offset
  jmp lcd_prt_msg_chr     ; go around again
.lcd_prt_msg_end
  rts

.lcd_set_cursor	          ; assumes X & Y co-ords have been put in X and Y
  ; X should contain the X param in range 0-15.
  ; Y should be 0 or 1.
  txa                     ; A now contains X position
  cpy #1
  bcc lcd_move_curs       ; Y is less than 1
  ora #$40                ; if we want second line, add $40 by setting bit 6
.lcd_move_curs
  ora #LCD_SET_DDRAM      ; OR with LCD_SET_DDRAM command byte
  jsr lcd_cmd
  rts
