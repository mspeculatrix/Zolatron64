; FUNCTIONS: LCD -- funcs_lcd.asm ----------------------------------------------
; v06 - 04 Nov 2021
;
.lcd_wait         ; check to see if LCD is ready to receive next byte
  pha             ; save current contents of A in stack, so it isn't corrupted
  lda #%00000000  ; Set Port B as input
  sta VIA_A_DDRB
.lcd_busy
  lda #LCD_RW
  sta VIA_A_PORTA
  lda #(LCD_RW OR LCD_EX) ; keep RW, set enable. RS=0 to access instr reg
  sta VIA_A_PORTA
  lda VIA_A_PORTB
  and #LCD_BUSY_FLAG  ; Sets zero flag - non-0 if LCD busy flag set
  bne lcd_busy        ; If result was non-0, keep looping
  lda #LCD_RW
  sta VIA_A_PORTA
  lda #%11111111  ; Set Port B as output
  sta VIA_A_DDRB
  pla             ; pull previous A contents back from stack
  rts

.lcd_cmd            ; send a command to the LCD
  pha               ; preserve A on the stack
  jsr lcd_wait      ; check LCD is ready to receive
  sta VIA_A_PORTB   ; assumes command byte is in A
  lda #0            ; Clear RS/RW/E bits. With RS 0, we're writing to instr reg
  sta VIA_A_PORTA
  lda #LCD_EX       ; Set E bit to send instruction
  sta VIA_A_PORTA
  lda #0            ; Clear RS/RW/E bits
  sta VIA_A_PORTA
  pla               ; recover original value of A from stack
  rts

.lcd_prt_chr              ; assumes character is in A
  jsr lcd_wait            ; check LCD is ready to receive
  sta VIA_A_PORTB
  lda #LCD_RS             ; Set RS to data; Clears RW & E bits
  sta VIA_A_PORTA
  lda #(LCD_RS OR LCD_EX) ; Keep RS & set E bit to send instruction
  sta VIA_A_PORTA
  lda #LCD_RS             ; Clear E bits
  sta VIA_A_PORTA
  rts 

.lcd_prt_msg	  ; assumes LSB of msg address at MSG_VEC, MSB at MSG_VEC+1
  ldy #0
.lcd_prt_msg_chr
  lda (MSG_VEC),Y         ; LDA sets zero flag if it's loaded with 0
  beq lcd_prt_msg_end     ; BEQ branches if zero flag set
  jsr lcd_prt_chr         ; display the character
  iny                     ; increment message string offset
  jmp lcd_prt_msg_chr     ; go around again
.lcd_prt_msg_end
  rts

;.lcd_set_cursor	          ; assumes X & Y co-ords have been put in X and Y
;  lda #LCD_CURS_HOME      ; send instruction to move the cursor to the home
;  jsr lcd_cmd             ; position. Doesn't affect existing text
  ; X should contain the X param in range 0-15.
  ; Y should be 0 or 1.
  ; If we want line 1, we do this by adding 39 to the value of X.
;  cpy #1
;  bcc lcd_move_curs       ; Y is less than 1
;  txa                     ; otherwise, we want line 1. Put X value in A
;  adc #39                 ; add 39
;  tax                     ; store back in X
;.lcd_move_curs
;  lda #LCD_CURS_R         ; load A with 'move cursor right' instruction
;.lcd_curs_next_move
;  cpx #0
;  beq lcd_set_curs_end    ; end if X = 0
;  jsr lcd_cmd             ; otherwise, executive the move cursor command
;  dex                     ; decrement X
;  jmp lcd_curs_next_move  ; go round again
;.lcd_set_curs_end
;  rts

.lcd_set_cursor	          ; assumes X & Y co-ords have been put in X and Y
  ; X should contain the X param in range 0-15.
  ; Y should be 0 or 1.
  txa                     ; A now contains X position
  cpy #1
  bcc lcd_move_curs       ; Y is less than 1
  adc $40                 ; if we want second line, add $40
.lcd_move_curs
  ora #LCD_SET_DDRAM      ; OR with LCD_SET_DDRAM command byte
  jsr lcd_cmd
  rts
