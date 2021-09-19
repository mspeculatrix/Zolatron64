; Zolatron 64
;
; Experimental ROM code for Zolatron 6502-based microcomputer.
; 
; This version:
;   - prints 'Zolatron 64' to the 16x2 LCD display
;   - sends a string across the serial port, repeatedly, in the main loop.
;   - Now working on serial receiving...
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
;
; Assemble with:
; beebasm -i z64-03.asm
;
; Write to EEPROM with:
; minipro -p AT28C256 -w z64-ROM-03.bin

; 6522 VIA register addresses
VIA_PORTA = $A001     ; VIA Port A data/instruction register
VIA_DDRA = $A003      ; Port A Data Direction Register
VIA_PORTB = $A000     ; VIA Port B data/instruction register
VIA_DDRB = $A002      ; Port B Data Direction Register

; ACIA addresses
ACIA_DATA_REG = $B000 ; transmit/receive data register
ACIA_STAT_REG = $B001 ; status register
ACIA_CMD_REG = $B002  ; command register
ACIA_CTRL_REG = $B003 ; control register
ACIA_RX_BUF = $0400   ; Serial receive buffer start address
ACIA_TX_BUF = $0300   ; Serial send buffer start address
ACIA_RX_IDX = $04FF   ; Location of RX buffer index
ACIA_TX_IDX = $03FF   ; Location of TX buffer index
ACIA_RX_BUF_LEN = 255
ACIA_TX_BUF_LEN = 255
; ACIA_INFO_REG = $0400 ; ??? don't know where this should go yet
; Following are values for the control register, setting eight data bits, 
; no parity, 1 stop bit and use of the internal baud rate generator
ACIA_8N1_2400 = %10011010
ACIA_8N1_9600 = %10011110
ACIA_8N1_19K2 = %10011111
; Value for the command register: No parity, echo normal, RTS low with no IRQ,
; IRQ enabled on receive, data terminal ready
ACIA_CMD_CFG = %00001011
; Mask values to be ANDed with status reg to check state of ACIA 
ACIA_IRQ_SET = %10000000
ACIA_TX_RDY_BIT = %00010000
ACIA_RX_RDY_BIT = %00001000

; LCD PANEL
EX = %10000000    ; Toggling this bit high enables execution of byte in register
RW = %01000000    ; Read/Write bit: 0 = read; 1 = write
RS = %00100000    ; Register select bit: 0 = instruction reg; 1 = data reg
BUSY_FLAG = %10000000 

; --------- INITIALISATION -----------------------------------------------------
ORG $8000         ; Using only the top 16KB of a 32KB EEPROM.
.startrom         ; This is where the ROM bytes start for the file, but...
ORG $C000         ; This is where the actual code starts.
.startcode

  ldx #$ff        ; set stack pointer to $01FF - only need to set
  txs             ; LSB as MSB is assumed to be $01

; SETUP VIA
  lda #%11111111  ; Set all pins on port B to output
  sta VIA_DDRB
  lda #%11100000  ; Set top 3 pins on port A to output
  sta VIA_DDRA

; SETUP ACIA
  lda #0
  sta ACIA_STAT_REG   ; reset ACIA
;  sta ACIA_INFO_REG   ; also zero-out info register
  sta ACIA_RX_IDX     ; zero buffer index
  sta ACIA_TX_IDX     ; zero buffer index
  lda #ACIA_8N1_9600  ; set control register config
  sta ACIA_CTRL_REG
  lda #ACIA_CMD_CFG   ; set command register config
  sta ACIA_CMD_REG

; SETUP LCD
  lda #%00111000  ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_cmd
  lda #%00001100  ; Display on; cursor off; blink off
  jsr lcd_cmd
  lda #%00000001  ; clear display, reset display memory
  jsr lcd_cmd

  cli             ; enable interrupts

; --------- MAIN PROGRAM -------------------------------------------------------

; LCD PRINT LOOP
  ldx #0              ; set message offset to 0
.print
  lda lcd_message,x   ; LDA sets zero flag if it's loaded with 0
  beq mainloop        ; BEQ branches if zero flag set
  jsr lcd_prt_chr
  inx                 ; increment message offset
  jmp print           ; go around again

; receiving - after calling acia_wait_byte_recvd,
; sta ACIA_DATA_REG
 
.mainloop             ; loop forever
  jsr serial_msg_send
  jsr delay
  jmp mainloop

; ------------------------------------------------------------------------------
; ----     SUBROUTINES                                                      ----
; ------------------------------------------------------------------------------
.delay
  sta $40 ; save the state of the A register in a handy zero-page location
  lda #0  ; set A to 0
  sta $41 ; using this location for the high byte of the loop
.delayloop
  adc #1  ; add 1 to A
  bne delayloop  ; loop if zero bit not set (will be set when A overflows)
  clc     ; reset carry flag - this is the outer loop
  inc $41
  bne delayloop ; branches until incrementing $41 overflows and zero bit gets set
  clc     ; clean up
  lda $40 ; restore state of A
  rts

; ---------SERIAL SUBROUTINES---------------------------------------------------

.serial_msg_send
; This is for initial experiments only - will be dropped soon
; SERIAL MESSAGE LOOP
  ldx #0                  ; set message offset to 0
.send_char
  lda serial_msg,x        ; load next char
  beq serial_send_end     ; if char is 0, we've finished
  jsr acia_wait_send_clr
  sta ACIA_DATA_REG
  inx
  jmp send_char
.serial_send_end
  rts

.serial_send_buffer         ; sends contents of send buffer and clears it
  ldx #0                    ; offset index
 .send_next_char
  lda ACIA_TX_BUF,x         ; load next char
  beq serial_send_buf_end   ; if char is 0, we've finished
  jsr acia_wait_send_clr    ; wait until ACIA is ready for another byte
  sta ACIA_DATA_REG         ; write to Data Reg. This sends the byte
  inx                       ; increment offset index
  cpx ACIA_TX_IDX           ; check if we're at the buffer index
  beq serial_send_buf_end   ; if so, end it here
  cpx #ACIA_TX_BUF_LEN      ; check against max buffer size, to prevent overrun
  beq serial_send_buf_end   ; if so, end it here
  jmp send_next_char        ; otherwise do the next char
.serial_send_buf_end
  lda #0
  sta ACIA_TX_IDX           ; re-zero the index
  rts

.acia_wait_send_clr
  pha                     ; push A to stack to save it
.acia_wait_send_loop        
  lda ACIA_STAT_REG       ; get contents of status register
  and #ACIA_TX_RDY_BIT    ; and with ready bit
  beq acia_wait_send_loop ; if it's zero, we're not ready yet
  pla                     ; recover A from stack
  rts

.acia_wait_byte_recvd
  lda ACIA_STAT_REG
  and #ACIA_RX_RDY_BIT
  beq acia_wait_byte_recvd
  rts

; ---------LCD SUBROUTINES------------------------------------------------------
.lcd_wait         ; check to see if LCD is ready to receive next byte
  pha             ; save current contents of A in stack, so it isn't corrupted
  lda #%00000000  ; Set Port B as input
  sta VIA_DDRB
.lcd_busy
  lda #RW
  sta VIA_PORTA
  lda #(RW OR EX) ; keep RW bit & set enable bit. RS is 0 to access instr reg
  sta VIA_PORTA
  lda VIA_PORTB
  and #BUSY_FLAG  ; AND flag with A. Sets zero flag - non-0 if LCD busy flag set
  bne lcd_busy    ; If result was non-0, keep looping
  lda #RW
  sta VIA_PORTA
  lda #%11111111  ; Set Port B as output
  sta VIA_DDRB
  pla             ; pull previous A contents back from stack
  rts

.lcd_cmd          ; send a command to the LCD
  jsr lcd_wait    ; check LCD is ready to receive
  sta VIA_PORTB   ; assumes command byte is in A
  lda #0          ; Clear RS/RW/E bits. With RS 0, we're writing to instr reg
  sta VIA_PORTA
  lda #EX         ; Set E bit to send instruction
  sta VIA_PORTA
  lda #0          ; Clear RS/RW/E bits
  sta VIA_PORTA
  rts

.lcd_prt_chr      ; assumes character is in A
  jsr lcd_wait    ; check LCD is ready to receive
  sta VIA_PORTB
  lda #RS         ; Set RS to data; Clears RW & E bits
  sta VIA_PORTA
  lda #(RS OR EX) ; Keep RS & set E bit to send instruction
  sta VIA_PORTA
  lda #RS         ; Clear E bits
  sta VIA_PORTA
  rts 

; ---------INTERRUPT SERVICE ROUTINE (ISR)--------------------------------------
.ISR_handler
  pha             ; preserve CPU state on the stack
  txa             ;                
  pha             ;
  tya             ;
  pha             ;
  cld             ;

; Check which device caused the interrupt.
; Most devices use the most significant bit (bit 7) of a register to indicate
; an interrupt has happened, and the 6551 ACIA is no different, with its
; status register. So there's a trick we can use here. The BIT operator
; effectively ANDs an address with the A reg, setting the Z flag if the result
; is zero. But we don't care about that. We want one of its other effects: it
; also copies bit 6 of the target address into the overflow flag (V) and
; bit 7 - the one we care about - into the negative flag (N).

bit ACIA_STAT_REG ; if it was the ACIA that set IRQ low, the N flag is now set
bne acia_isr
; do other checks here, branching as appropriate
jmp exit_isr

.acia_isr
  lda ACIA_STAT_REG   ; this also resets the interrupt bit
  ; rest to come....

.exit_isr
  pla             ; resume original CPU state
  tay             ;
  pla             ;
  tax             ;
  pla             ;
  rti

.NMI_handler
.exit_nmi
  rti

; ---------DATA-----------------------------------------------------------------
.lcd_message
	equs "Zolatron 64"
	equb 0

.serial_msg
  equs "Zolatron 64 serial message"
  equb 10
  equb 0

ORG $fffa
  equw NMI_handler  ; vector for NMI
  equw startcode    ; reset vector to start of ROM code
  equw ISR_handler  ; vector for ISR

.endrom

SAVE "z64-ROM-03.bin", startrom, endrom
