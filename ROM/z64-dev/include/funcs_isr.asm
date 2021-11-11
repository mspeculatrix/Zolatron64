; FUNCTIONS: INTERRUPT SERVICE ROUTINE (ISR) -- funcs_isr.asm ------------------
; v07 - 10 Nov 2021
;
ALIGN &100                ; start on new page
.ISR_handler
  pha : phx : phy         ; preserve CPU state on the stack
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
  cmp #CHR_LINEEND          ; or is it a line end?
  bne acia_isr_end          ; if not 0 or CR, go to next step
  stz UART_RX_BUF,X			    ; if CR, replace with NULL
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
  ply : plx : pla           ; resume original register state
  rti
  