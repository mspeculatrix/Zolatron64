; Zolatron 64
;
; Experimental ROM code for Zolatron 6502-based microcomputer.
; 
; *** WORK IN PROGRESS - NOT WORKING YET ***
;
; This version:
;   - prints 'Zolatron 64' to the 16x2 LCD display
;   - sends a string across the serial port, repeatedly, in the main loop.
;   - Now working on serial receiving. Prints whatever comes down the line
;     to the LCD. Sent string can be terminated with either a null byte
;     (ASCII 0) or a carriage return (ASCII 13).
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
UART_RX_BUF = $0400   ; Serial receive buffer start address
UART_TX_BUF = $0300   ; Serial send buffer start address
UART_RX_IDX = $04FF   ; Location of RX buffer index
UART_TX_IDX = $03FF   ; Location of TX buffer index
UART_RX_BUF_LEN = $FF
UART_TX_BUF_LEN = $FF

UART_STATUS_REG = $0210 ; memory byte we'll use to store various flags
; masks for setting/reading flags
UART_FL_RX_BUF_DATA = %00000001   ; Receive buffer has data
UART_FL_RX_DATA_RST = %11111110   ; Reset mask
UART_FL_RX_NUL_RCVD = %00000010   ; we've received a null terminator
UART_FL_RX_BUF_FULL = %00001000
UART_CLEAR_RX_FLAGS = %11110000   ; to be ANDed with info reg to clear RX flags
UART_FL_TX_BUF_DATA = %00010000   ; TX buffer has data to send
UART_FL_TX_BUF_FULL = %10000000
UART_CLEAR_TX_FLAGS = %00001111   ; to be ANDed with info reg to clear TX flags

; Following are values for the control register, setting eight data bits, 
; no parity, 1 stop bit and use of the internal baud rate generator
UART_8N1_2400 = %10011010
UART_8N1_9600 = %10011110
UART_8N1_19K2 = %10011111
; Value for the command register: No parity, echo normal, RTS low with no IRQ,
; IRQ enabled on receive, data terminal ready
ACIA_CMD_CFG = %00001001
; Mask values to be ANDed with status reg to check state of ACIA 
; ACIA_IRQ_SET = %10000000
ACIA_RDRF_BIT = %00001000     ; Receive Data Register Full
ACIA_OVRN_BIT = %00000100     ; Overrun error
ACIA_FE_BIT   = %00000010     ; Frame error
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
  sta ACIA_STAT_REG     ; reset ACIA
  sta UART_STATUS_REG   ; also zero-out our status register
  sta UART_RX_IDX       ; zero buffer index
  sta UART_TX_IDX       ; zero buffer index
  lda #UART_8N1_9600    ; set control register config
  sta ACIA_CTRL_REG
  lda #ACIA_CMD_CFG     ; set command register config
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
.main
  jsr serial_send_start_msg
  jsr serial_send_prompt

; Print initial message on LCD
  ldx #0              ; set message offset to 0
.print
  lda lcd_message,x   ; LDA sets zero flag if it's loaded with 0
  beq mainloop        ; BEQ branches if zero flag set
  jsr lcd_prt_chr
  inx                 ; increment message offset
  jmp print           ; go around again
 
.mainloop                   ; loop forever
  lda UART_STATUS_REG       ; load our serial info register
  and #UART_FL_RX_BUF_DATA  ; is there new data?
  bne process_rx            ; if yes, process it
  jmp mainloop              ; otherwise loop
  
; the following is in the main loop for now while I'm experimenting. It'll be
; moved to a more generalised subroutine eventually.
.process_rx
  lda UART_STATUS_REG       ; first reset the data bit, whatever happens
  ora #UART_FL_RX_DATA_RST  ;
  sta UART_STATUS_REG
  lda ACIA_STAT_REG         ; Load status reg - also resets interrupt bit
  and #ACIA_RDRF_BIT        ; Is the Receive Data Register Full bit set?
  beq mainloop              ; No data. WTF. Let's get outta here...
  ; technically, we should also test aganst frame error and overrun error bits,
  ; but we'll do that in a future version
  ldx UART_RX_IDX           ; load the value of the buffer index
  lda ACIA_DATA_REG         ; load the byte in the data register into A
  sta UART_RX_BUF,x         ; and store it in the buffer, at the offset
  cmp #0                    ; is the byte value 0?
  beq rx_set_null           ; if byte is the 0 terminator, go set the null flag
  cmp #13                   ; or is it a carriage return?
  bne acia_rx_set_info      ; if not 0 or CR, go to next step
  lda #0                    ; if it's a carriage return, replace with null
  sta UART_RX_BUF,x
.rx_set_null
  lda UART_STATUS_REG       ; load our status register
  ora #UART_FL_RX_NUL_RCVD  ; set the null byte received bit
  sta UART_STATUS_REG       ; re-save the status
.acia_rx_set_info
  inx                       ; increment index
  stx UART_RX_IDX           ; store the index
  cpx #UART_RX_BUF_LEN      ; are we at the maximum?
  bne acia_rx_check_flags   ; if not, we're all done, otherwise...
  lda UART_STATUS_REG       ; load our info register (again)
  ora #UART_FL_RX_BUF_FULL  ; flag that buffer is full
  sta UART_STATUS_REG       ; and re-save the status register
.acia_rx_check_flags
; at this point, if we've received a null byte or the buffer is full, we'll
; use the buffer data and reset the buffer index.
; The status register is still in A
  ora #UART_FL_RX_NUL_RCVD  ; have we received a null byte?
  bne print_rx              ; if so, deal with message
  lda UART_STATUS_REG
  ora #UART_FL_RX_BUF_FULL  ; is the buffer full?
  beq mainloop              ; if not, loop, otherwise...
.print_rx
  lda #%00000001            ; clear display, reset display memory
  jsr lcd_cmd
  jsr serial_send_prompt    ; send our standard prompt
  lda UART_STATUS_REG       ; get our info register
  and #UART_CLEAR_RX_FLAGS  ; reset all the RX flags
  sta UART_STATUS_REG       ; and re-save the register
  ldx #0                    ; our offset index
.get_rx_char
  lda UART_RX_BUF,x     ; get the next byte in the buffer
  beq end_process_rx    ; if it's a zero terminator, we're done
  jsr lcd_prt_chr       ; otherwise, print char to LCD
  inx                   ; increment index
  cpx UART_RX_IDX       ; have we reached the last char?
  beq end_process_rx    ; if so, we're done
  cpx #UART_RX_BUF_LEN  ; are we at the end of the buffer?
  bne get_rx_char       ; if not, get another char
.end_process_rx
  lda #0
  sta UART_RX_IDX       ; reset buffer index
  jmp mainloop          ; otherwise, we're done

; ------------------------------------------------------------------------------
; ----     SUBROUTINES                                                      ----
; ------------------------------------------------------------------------------
; .delay    ; ONLY FOR TESTING/DEBUGGING
;   sta $40 ; save the state of the A register in a handy zero-page location
;   lda #0  ; set A to 0
;   sta $41 ; using this location for the high byte of the loop
; .delayloop
;   adc #1  ; add 1 to A
;   bne delayloop  ; loop if zero bit not set (will be set when A overflows)
;   clc     ; reset carry flag - this is the outer loop
;   inc $41
;   bne delayloop ; branches until incrementing $41 overflows and zero bit gets set
;   clc     ; clean up
;   lda $40 ; restore state of A
;   rts

; ---------SERIAL SUBROUTINES---------------------------------------------------

.serial_send_start_msg
  ldx #0
.send_start_char
  lda serial_start_msg,x
  beq serial_send_start_end     ; if char is 0, we've finished
  jsr acia_wait_send_clr
  sta ACIA_DATA_REG
  inx
  jmp send_start_char
.serial_send_start_end
  rts

.serial_send_prompt
  ldx #0                      ; set message offset to 0
.send_prompt_char
  lda serial_prompt,x         ; load next char
  beq serial_send_prompt_end  ; if char is 0, we've finished
  jsr acia_wait_send_clr
  sta ACIA_DATA_REG
  inx
  jmp send_prompt_char
.serial_send_prompt_end
  rts

; .serial_send_startup        ; trying something different
;   lda #<serial_start_msg
; .next_char_to_buf
;   lda serial_start_msg,x
;   sta UART_TX_BUF,x
;   cmp #0
;   beq send_startup_end
;   jmp next_char_to_buf
; .send_startup_end
;   jsr serial_send_buffer
;   rts

.serial_send_buffer         ; sends contents of send buffer and clears it
  ldx #0                    ; offset index
 .serial_send_next_char
  lda UART_TX_BUF,x         ; load next char
  beq serial_send_buf_end   ; if char is 0, we've finished
  jsr acia_wait_send_clr    ; wait until ACIA is ready for another byte
  sta ACIA_DATA_REG         ; write to Data Reg. This sends the byte
  inx                       ; increment offset index
  cpx UART_TX_IDX           ; check if we're at the buffer index
  beq serial_send_buf_end   ; if so, end it here
  cpx #UART_TX_BUF_LEN      ; check against max buffer size, to prevent overrun
  beq serial_send_buf_end   ; if so, end it here
  jmp serial_send_next_char ; otherwise do the next char
.serial_send_buf_end
  lda #0
  sta UART_TX_IDX           ; re-zero the index
  rts

.acia_wait_send_clr
  pha                     ; push A to stack to save it
.acia_wait_send_loop        
  lda ACIA_STAT_REG       ; get contents of status register
  and #ACIA_TX_RDY_BIT    ; and with ready bit
  beq acia_wait_send_loop ; if it's zero, we're not ready yet
  pla                     ; recover A from stack
  rts

.acia_wait_byte_recvd     ; not using this yet. Ever?
  lda ACIA_STAT_REG       ; Possibly if I implement flow control
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
; bit 7 - the one we care about - into the negative flag (N). It doesn't matter
; what's in A.
bit ACIA_STAT_REG ; if it was the ACIA that set IRQ low, the N flag is now set
bne acia_isr
; do other checks here, branching as appropriate
jmp exit_isr

.acia_isr
  lda UART_STATUS_REG       ; load our status register
  ora #UART_FL_RX_BUF_DATA  ; set the 'there be data' bit
  sta UART_STATUS_REG
  jmp exit_isr
  ; there will be other stuff here one day, which is why we're jumping above
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
	equs "Zolatron 64", 0

.serial_start_msg
  equs 10, 10, "Zolatron 64", 10, "Ready", 0

.serial_prompt
  equs 10, "Z>", 0

ORG $fffa
  equw NMI_handler  ; vector for NMI
  equw startcode    ; reset vector to start of ROM code
  equw ISR_handler  ; vector for ISR

.endrom

SAVE "z64-ROM-03.bin", startrom, endrom
