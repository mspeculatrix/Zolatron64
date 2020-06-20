; Zolatron 64 code.
; Much inspired by Ben Eater's 6502 project.
; 
; Written for the Beebasm assembler.
;
; Assemble with:
; beebasm -i z64-01.asm
;
; Write to EEPROM with:
; minipro -p AT28C256 -w z64-01.bin

PORTB = $A000
PORTA = $A001
DDRB = $A002
DDRA = $A003

E  = %10000000
RW = %01000000
RS = %00100000

ORG $8000         ; Using only the top 16KB of a 32KB EEPROM.
.startrom         ; This is where the ROM bytes start.
ORG $C000         ; This is where the actual code starts.
.startcode

  ldx #$ff        ; set stack pointer to $01FF - only need to set
  txs             ; LSB as MSB is assumed to be $01

  lda #%11111111 ; Set all pins on port B to output
  sta DDRB

  lda #%11100000 ; Set top 3 pins on port A to output
  sta DDRA

  lda #%00111000  ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_cmd
  lda #%00001100 ; Display on; cursor off; blink off
  jsr lcd_cmd

.startprint
  lda #%00000001 ; clear display, reset display memory
  jsr lcd_cmd

  lda #'Z'
  jsr lcdprintchar
  lda #'o'
  jsr lcdprintchar
  lda #'l'
  jsr lcdprintchar
  lda #'a'
  jsr lcdprintchar
  lda #'t'
  jsr lcdprintchar
  lda #'r'
  jsr lcdprintchar
  lda #'o'
  jsr lcdprintchar
  lda #'n'
  jsr lcdprintchar
  lda #' '
  jsr lcdprintchar
  lda #'6'
  jsr lcdprintchar
  lda #'4'
  jsr lcdprintchar

.loop
  jmp loop
; -------- END OF PROGRAM --------------------------------------------

.lcd_cmd          ; send a command to the LCD
  sta PORTB       ; assumes command byte is in A
  lda #0          ; Clear RS/RW/E bits
  sta PORTA
  lda #E          ; Set E bit to send instruction
  sta PORTA
  lda #0          ; Clear RS/RW/E bits
  sta PORTA
  rts

.lcdprintchar     ; assumes character is in A
  sta PORTB
  lda #RS         ; Set rs; Clear rw/E bits
  sta PORTA
  lda #(RS OR E)  ; Set E bit to send instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
  rts 

ORG $fffc           ; reset vector to start of code
    equw startcode  ; write $C000 to $fffc
    equw $0000	    ; fill last two bytes with null values to fill ROM

.endrom

SAVE "z64-01.bin", startrom, endrom
