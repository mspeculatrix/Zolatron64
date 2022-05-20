; FUNCTIONS: LCD -- funcs_lcd.asm ----------------------------------------------

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
;  pha                              ; preserve A on the stack
  jsr lcd_wait                      ; check LCD is ready to receive
  sta VIAA_PORTB                    ; assumes command byte is in A
  jsr lcd_clear_sig                 ; Clear RS/RW/E bits. Writing to instr reg
  LCD_SET_CTL LCD_EX                ; Set E bit to send instruction
  jsr lcd_clear_sig
;  pla
  rts

; ------------------------------------------------------------------------------
;  lcd_prt_linebuf  :  print a line from the buffer to the LCD           ---
; ------------------------------------------------------------------------------
.lcd_prt_linebuf
; Prints a line's worth from the LCD_BUF buffer. Which line is determined by the
; offset, which should be in Y (0 or 1 for a 2-line display, 0-3 for a 4-line).
  pha : phx : phy
  ldx #0                      ; Set cursor to start of line
  jsr lcd_set_cursor          ; Now done with X
  lda #0                      ; Use to calculate offset
.lcd_prt_linebuf_set_offset   ; Calculate the offset for LCD_BUF
  cpy #0                      ; If Y is (or has decremented to) 0, we're done.
  beq lcd_prt_linebuf_prt
  clc
  adc #LCD_LN_BUF_SZ          ; Otherwise, add line length to the offset
  dey                         ; and go around again
  jmp lcd_prt_linebuf_set_offset
.lcd_prt_linebuf_prt
  tay                         ; Store the offset in Y
  ldx #0                      ; to keep track of how many chars printed
.lcd_prt_linebuf_prtchr
  lda LCD_BUF,Y               ; Load a char from the buffer
  beq lcd_prt_linebuf_end     ; Finish if we loaded a null terminator
  jsr lcd_prt_chr             ; Display the character
  iny                         ; Increment buffer offset
  inx                         ; Increment character counter
  cpx #LCD_COLS               ; Have we printed a line's worth?
  beq lcd_prt_linebuf_end     ; If so, done.
  jmp lcd_prt_linebuf_prtchr  ; Else, go around again
.lcd_prt_linebuf_end
  ply : plx : pla
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

; ------------------------------------------------------------------------------
;  OS API Functions
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
;  lcd_prt_chr  :  PRINT CHARACTER
;  Implements: OSLCDCH
; ------------------------------------------------------------------------------
.lcd_prt_chr                        ; assumes character is in A
  pha
  jsr lcd_wait                      ; check LCD is ready to receive
  sta VIAA_PORTB
  LCD_SET_CTL LCD_RS 
  LCD_SET_CTL (LCD_RS OR LCD_EX)    ; Keep RS & set E bit to send instruction
  LCD_SET_CTL LCD_RS                ; Clear E bits
  pla
  rts 

; ------------------------------------------------------------------------------
;  lcd_cls  :  CLEAR SCREEN
;  Implements: OSLCDCLS
; ------------------------------------------------------------------------------
.lcd_cls
  jsr lcd_clear_buf
  lda #LCD_CLS          ; clear display, reset display memory
  jsr lcd_cmd
  rts

; ------------------------------------------------------------------------------
;  lcd_prt_err  :  PRINT ERROR
;  Implements: OSLCDERR
;  - Assumes error code is in FUNC_ERR
; ------------------------------------------------------------------------------
.lcd_prt_err
  lda FUNC_ERR
  dec A                   ; to get offset for table
  asl A                   ; shift left to multiply by 2
  tax                     ; move to X to use as offset
  lda err_ptrs,X          ; get LSB of relevant address from the cmd_ptrs table
  sta MSG_VEC             ; and put in MSG_VEC
  lda err_ptrs+1,X        ; get MSB
  sta MSG_VEC+1           ; and put in MSG_VEC high byte
  jsr lcd_println
  rts

; ------------------------------------------------------------------------------
;  lcd_println  :  PRINT LINE
;  Implements: OSLCDMSG
;  Prints text to the LCD. The address of the text to be printed is assumed
;  to be pointed to by MSG_VEC. The text is also written to the first line's
;  worth of the LCD_BUF buffer, with other lines first being moved down a 
;  line's worth. The last line's worth of existing text is overwritten.
; ------------------------------------------------------------------------------
.lcd_println
  pha : phx : phy
  ; First, we'll copy existing data in the buffer, so that each byte gets
  ; shifted one line's worth of bytes later in the buffer. As the last line
  ; of the buffer is going to be overwritten, and its original contents lost,
  ; we start with the penultimate line.
  ldx #LCD_MOVE_SRC           ; Offsets for source (39) & destination (79) for 
  ldy #LCD_MOVE_DST           ; moving characters within the buffer.
.lcd_println_move
  lda LCD_BUF,X               ; Move a character
  sta LCD_BUF,Y
  cpx #0                      ; If source is at beginning of buffer, we're done
  beq lcd_println_move_done
  dey                         ; Else, decrement offsets for next char positions
  dex
  jmp lcd_println_move
.lcd_println_move_done
  ldy #0
.lcd_println_move_msg         ; Move new message into start of buffer
  lda (MSG_VEC),Y    
  sta LCD_BUF,Y                    
  beq lcd_println_pad         ; If this char is a null, we're done
  iny                         ; else, increment offset
  cpy #LCD_LN_BUF_SZ          ; Have we done a line's worth?
  beq lcd_println_terminate
  jmp lcd_println_move_msg
.lcd_println_pad              ; Pad line with spaces
  lda #CHR_SPACE
.lcd_println_pad_next
  cpy #LCD_LN_BUF_SZ
  beq lcd_println_terminate
  sta LCD_BUF,Y 
  iny
  jmp lcd_println_pad_next
.lcd_println_terminate        ; Ensure last char in line buffer is a 0
  lda #0
  dey
  sta LCD_BUF,Y
.lcd_println_refresh          ; Rewrite all lines of display
  ldy #0
.lcd_println_refresh_next
  jsr lcd_prt_linebuf
  iny
  cpy #LCD_LINES
  bne lcd_println_refresh_next
  ply : plx : pla
  rts

; ------------------------------------------------------------------------------
;  lcd_print_byte  :  PRINT BYTE
;  Implements: OSLCDPRB
;  - Assumes byte value to be printed is in A. A is preserved.
; ------------------------------------------------------------------------------
.lcd_print_byte
  jsr byte_to_hex_str               ; Result in three bytes starting at STR_BUF
  lda STR_BUF
  jsr lcd_prt_chr
  lda STR_BUF + 1
  jsr lcd_prt_chr
  rts

; ------------------------------------------------------------------------------
;  lcd_set_cursor  :  SET CURSOR
;  Implements: OSLCDSC
;  - Assumes X & Y co-ords have been put in X and Y.
;  - X should contain the X param in range 0-15.
;  - Y should be 0 or 1.
; ------------------------------------------------------------------------------
.lcd_set_cursor
  txa                     ; A now contains X position
  cpy #1
  bcc lcd_move_curs       ; Y is less than 1
  ora #$40                ; if we want second line, add $40 by setting bit 6
.lcd_move_curs
  ora #LCD_SET_DDRAM      ; OR with LCD_SET_DDRAM command byte
  jsr lcd_cmd
  rts
