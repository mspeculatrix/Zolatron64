; Zolatron 64
;
; Experimental ROM code for Zolatron 6502-based microcomputer.
;
; This version:
;   - prints 'Zolatron 64' to the 16x2 LCD display on start up
;   - sends a start-up message and prompt across the serial connection
;   - receives on the serial port. It prints incoming strings to the LCD.
;     These strings should be terminated with a null (ASCII 0) or 
;     carriage return (ASCII 13).
;	- checks for size of receive buffer, to prevent overflows. (NOT TESTED)
;
; BUT: There's no flow control. And because we're running on a 1MHz clock, it's
; easily overwhelmed by incoming data. To make this work, the sending terminal
; must have a delay between characters (easy to set in Minicom or CuteCom).
; I'm currently using 10ms. I'm happy to live with this restriction for now.
; This post was helpful: 
; https://www.reddit.com/r/beneater/comments/qbilsu/6551_acia_question/
;
; TO DO:
;   - Would be good to reduce the amount of processing going on inside the
;     ISR if possible.
;   - Maybe implement flow control to manage incoming data.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i z64-<version>.asm
;
; Write to EEPROM with:
; minipro -p AT28C256 -w z64-ROM-<version>.bin

; 6522 VIA register addresses
VIA_PORTA = $A001     ; VIA Port A data/instruction register
VIA_DDRA  = $A003     ; Port A Data Direction Register
VIA_PORTB = $A000     ; VIA Port B data/instruction register
VIA_DDRB  = $A002     ; Port B Data Direction Register

; Vector addresses
MSG_VEC = $70  ; Address of message to be printed. LSB is MSG_VEC, MSB is +1

; ACIA addresses
ACIA_DATA_REG = $B000 ; transmit/receive data register
ACIA_STAT_REG = $B001 ; status register
ACIA_CMD_REG = $B002  ; command register
ACIA_CTRL_REG = $B003 ; control register
UART_RX_BUF = $0400   ; Serial receive buffer start address
UART_TX_BUF = $0300   ; Serial send buffer start address
UART_RX_IDX = $04FF   ; Location of RX buffer index
UART_TX_IDX = $03FF   ; Location of TX buffer index
UART_RX_BUF_LEN = 240 ; size of buffers. We actually have 255 bytes available
UART_RX_BUF_MAX = 255 ; but this leaves some headroom. The MAX values are for
UART_TX_BUF_LEN = 240 ; use in output routines.
UART_TX_BUF_MAX = 255 ; 

UART_STATUS_REG = $0210 ; memory byte we'll use to store various flags
; masks for setting/reading flags
;UART_FL_RX_BUF_DATA = %00000001   ; Receive buffer has data
;UART_FL_RX_DATA_RST = %11111110   ; Reset mask
UART_FL_RX_NUL_RCVD = %00000010   ; we've received a null terminator
; UART_FL_RX_BUF_FULL = %00001000
UART_CLEAR_RX_FLAGS = %11110000   ; to be ANDed with info reg to clear RX flags
UART_FL_TX_BUF_DATA = %00010000   ; TX buffer has data to send
UART_FL_TX_BUF_FULL = %10000000
UART_CLEAR_TX_FLAGS = %00001111   ; to be ANDed with info reg to clear TX flags

; Following are values for the control register, setting eight data bits, 
; no parity, 1 stop bit and use of the internal baud rate generator
UART_8N1_0300 = %10010110
UART_8N1_1200 = %10011000
UART_8N1_2400 = %10011010
UART_8N1_9600 = %10011110
UART_8N1_19K2 = %10011111
; Value for the command register: No parity, echo normal, RTS low with no 
; transmit IRQ, IRQ enabled on receive, data terminal ready
ACIA_CMD_CFG = %00001001
; Mask values to be ANDed with status reg to check state of ACIA 
; ACIA_IRQ_SET = %10000000
ACIA_RDRF_BIT = %00001000     ; Receive Data Register Full
; ACIA_OVRN_BIT = %00000100     ; Overrun error
; ACIA_FE_BIT   = %00000010     ; Frame error
ACIA_TX_RDY_BIT = %00010000
ACIA_RX_RDY_BIT = %00001000

; LCD PANEL
EX = %10000000    ; Toggling this bit high enables execution of byte in register
RW = %01000000    ; Read/Write bit: 0 = read; 1 = write
RS = %00100000    ; Register select bit: 0 = instruction reg; 1 = data reg
BUSY_FLAG = %10000000 

; CPU 1             ; use 65C02 instruction set - maybe later

; --------- INITIALISATION -----------------------------------------------------
ORG $8000         ; Using only the top 16KB of a 32KB EEPROM.
.startrom         ; This is where the ROM bytes start for the file, but...
ORG $C000         ; This is where the actual code starts.
.startcode
  sei             ; don't interrupt me yet
  cld             ; clear decimal flag - don't want to work in BCD
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
  lda #UART_8N1_9600    ; set control register config - set speed & 8N1
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

; ------------------------------------------------------------------------------
; ----     MAIN PROGRAM                                                     ----
; ------------------------------------------------------------------------------
.main

; Print initial message & prompt via serial
  lda #serial_start_msg MOD 256   ; LSB of message
  sta MSG_VEC
  lda #serial_start_msg DIV 256   ; MSB of message
  sta MSG_VEC+1
  jsr serial_send_msg
;  jsr serial_send_start_msg
  jsr serial_send_prompt

; Print initial message on LCD
  lda #lcd_start_message MOD 256  ; LSB of message
  sta MSG_VEC
  lda #lcd_start_message DIV 256  ; MSB of message
  sta MSG_VEC+1
  jsr lcd_prt_msg

  cli                     ; enable interrupts

; --------- MAIN LOOP ----------------------------------------------------------
.mainloop                   ; loop forever
  lda UART_STATUS_REG       ; load our serial status register
  and #UART_FL_RX_NUL_RCVD  ; is the 'null received' bit set?
  bne process_rx            ; if yes, process the buffer
  ldx UART_RX_IDX           ; load the value of the buffer index
  cpx #UART_RX_BUF_LEN		  ; are we at the limit?
  bcs process_rx			      ; branch if X >= UART_RX_BUF_LEN
; other tests may go here
  jmp mainloop              ; loop
.process_rx
  ; we're here because the null received bit is set or buffer is full
  jsr serial_print_rx_buf   ; print the buffer to the display
  jmp mainloop              ; go around again

; ------------------------------------------------------------------------------
; ----     SUBROUTINES                                                      ----
; ------------------------------------------------------------------------------

; ---------SERIAL SUBROUTINES---------------------------------------------------

.serial_send_msg
  ldy #0                      ; set message offset to 0
.serial_send_msg_chr
  lda (MSG_VEC),Y             ; load next char
  beq serial_send_msg_end     ; if char is 0, we've finished
  jsr acia_wait_send_clr      ; wait for serial port to be ready
  sta ACIA_DATA_REG           ; write to data register. This sends the byte
  iny                         ; increment index
  jmp serial_send_msg_chr     ; go back for next character
.serial_send_msg_end
  rts

.serial_send_prompt
  lda #serial_prompt MOD 256
  sta MSG_VEC
  lda #serial_prompt DIV 256
  sta MSG_VEC+1
  jsr serial_send_msg
  rts

.serial_print_rx_buf
  lda #%00000001            ; clear display, reset display memory
  jsr lcd_cmd
  jsr serial_send_prompt    ; send our standard prompt
  lda UART_STATUS_REG       ; get our info register
  and #UART_CLEAR_RX_FLAGS  ; zero all the RX flags
  sta UART_STATUS_REG       ; and re-save the register
  ldx #0                    ; our buffer offset index
.get_rx_char
  lda UART_RX_BUF,x         ; get the next byte in the buffer
  beq end_print_rx          ; if it's a zero terminator, we're done
  jsr lcd_prt_chr           ; otherwise, print char to LCD
  inx                       ; increment index
  cpx UART_RX_IDX           ; have we reached the last char?
  beq end_print_rx          ; if so, we're done
  cpx #UART_RX_BUF_MAX      ; or are we at the end of the buffer?
  bne get_rx_char           ; if not, get another char
.end_print_rx
  ldx #0
  stx UART_RX_IDX           ; reset buffer index
  stx UART_RX_BUF           ; and reset first byte in buffer to 0
  rts

.serial_send_buffer         ; sends contents of send buffer and clears it
  ldx #0                    ; offset index
 .serial_send_next_char
  lda UART_TX_BUF,X         ; load next char
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
  and #ACIA_TX_RDY_BIT    ; AND with ready bit
  beq acia_wait_send_loop ; if it's zero, we're not ready yet
  pla                     ; otherwise, recover A from stack
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

; ---------INTERRUPT SERVICE ROUTINE (ISR)--------------------------------------
ALIGN &100        ; start on new page
.ISR_handler
  pha             ; preserve CPU state on the stack
  txa             ;                
  pha             ;
  ; Check which device caused the interrupt.
  bit ACIA_STAT_REG ; if it was the ACIA that set IRQ low, the N flag is now set
  bmi acia_isr      ; branch if N flag set to 1
  ; do other checks here, branching as appropriate
  jmp exit_isr

.acia_isr
  ldx UART_RX_IDX           ; load the value of the buffer index
  lda ACIA_DATA_REG         ; load the byte in the data register into A
  sta UART_RX_BUF,X         ; and store it in the buffer, at the offset
  beq acia_rx_set_null      ; if byte is the 0 terminator, go set the null flag
  cmp #13                   ; or is it a carriage return?
  bne acia_isr_end          ; if not 0 or CR, go to next step
  lda #0                    ; if it's a carriage return, replace the CR code
  sta UART_RX_BUF,X			    ; we previously stored with a null
.acia_rx_set_null
  lda UART_STATUS_REG       ; load our status register
  ora #UART_FL_RX_NUL_RCVD  ; set the null byte received flag
  sta UART_STATUS_REG       ; re-save the status
.acia_isr_end
  inx                       ; increment the index for next time
  stx UART_RX_IDX           ; and save it
  lda ACIA_STAT_REG         ; Load ACIA status reg - resets interrupt bit
;  jmp exit_isr
  ; when there is other stuff here, implement the jump above

.exit_isr
  pla             ; resume original register state
  tax             ;
  pla             ;
  rti

ALIGN &100        ; start on new page
.NMI_handler      ; for future development
.exit_nmi
  rti

; ---------DATA-----------------------------------------------------------------
ALIGN &100        ; start on new page
.lcd_start_message
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

SAVE "z64-ROM-04.bin", startrom, endrom
