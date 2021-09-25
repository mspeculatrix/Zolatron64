; Zolatron 64 code - to test address decoding.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Based on Ben Eater's 6502 project:
; https://www.youtube.com/playlist?list=PLowKtXNTBypFbtuVMUVXNR0z1mu7dp7eH 
; 
; Refactored for the Beebasm assembler and the Zolatron's address decoding,
; which is different to Ben's - ie:
;               Ben Eater       Zolatron
;   ROM         $8000           $C000
;   6522 VIA    $6000           $A000
;
; Assemble with:
; beebasm -i z64-01.asm
;
; Write to EEPROM with:
; minipro -p AT28C256 -w z64-ROM-01.bin
;
; This code just prints a message to the LCD screen
; *** WORKING ***

; 6522 VIA register addresses
PORTB = $A000     ; VIA Port B data/instruction register
PORTA = $A001     ; VIA Port A data/instruction register
DDRB = $A002      ; Port B Data Direction Register
DDRA = $A003      ; Port A Data Direction Register

; LCD PANEL
EX  = %10000000    ; Toggling this bit high enables execution of byte in register
RW  = %01000000    ; Read/Write bit: 0 = read; 1 = write
RS  = %00100000    ; Register select bit: 0 = instruction reg; 1 = data reg
BUSY_FLAG = %10000000 

; ---------PROGRAM START -------------------------------------------------
ORG $8000         ; Using only the top 16KB of a 32KB EEPROM.
.startrom         ; This is where the ROM bytes start, but...
ORG $C000         ; This is where the actual code starts.
.startcode

  ldx #$ff        ; set stack pointer to $01FF - only need to set
  txs             ; LSB as MSB is assumed to be $01

; SETUP VIA
  lda #%11111111  ; Set all pins on port B to output
  sta DDRB
  lda #%11100000  ; Set top 3 pins on port A to output
  sta DDRA

; SETUP LCD
  lda #%00111000  ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_cmd
  lda #%00001100  ; Display on; cursor off; blink off
  jsr lcd_cmd
  lda #%00000001  ; clear display, reset display memory
  jsr lcd_cmd

; PRINT LOOP
  ldx #0          ; set message offset to 0
.print
  lda message,x   ; LDA sets zero flag if it's loaded with 0
  beq loop        ; BEQ branches if zero flag set
  jsr lcd_prt_chr
  inx             ; increment message offset
  jmp print       ; go around again

.loop             ; we're done, so loop forever
  jmp loop

; ---------SUBROUTINES----------------------------------------------------------

.lcd_wait         ; check to see if LCD is ready to receive next byte
  pha             ; save current contents of A in stack, so it isn't corrupted
  lda #%00000000  ; Set Port B as input
  sta DDRB
.lcd_busy
  lda #RW
  sta PORTA
  lda #(RW OR EX) ; keep RW bit & set enable bit. RS is 0 to access instr reg
  sta PORTA
  lda PORTB
  and #BUSY_FLAG  ; AND flag with A. Sets zero flag - non-0 if LCD busy flag set
  bne lcd_busy    ; If result was non-0, keep looping
  lda #RW
  sta PORTA
  lda #%11111111  ; Set Port B as output
  sta DDRB
  pla             ; pull previous A contents back from stack
  rts

.lcd_cmd          ; send a command to the LCD
  jsr lcd_wait    ; check LCD is ready to receive
  sta PORTB       ; assumes command byte is in A
  lda #0          ; Clear RS/RW/E bits. With RS 0, we're writing to instr reg
  sta PORTA
  lda #EX         ; Set E bit to send instruction
  sta PORTA
  lda #0          ; Clear RS/RW/E bits
  sta PORTA
  rts

.lcd_prt_chr      ; assumes character is in A
  jsr lcd_wait    ; check LCD is ready to receive
  sta PORTB
  lda #RS         ; Set RS to data; Clears RW & E bits
  sta PORTA
  lda #(RS OR EX) ; Keep RS & set E bit to send instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
  rts 

; ---------DATA-----------------------------------------------------------------
.message
	equs "Zolatron 64"
	equb 0

ORG $fffc         ; reset vector to start of code
  equw startcode  ; write $C000 to $fffc
  equw $0000	    ; fill last two bytes with null values to fill ROM

.endrom

SAVE "z64-ROM-01.bin", startrom, endrom
