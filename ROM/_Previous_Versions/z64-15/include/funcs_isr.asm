; FUNCTIONS: INTERRUPT SERVICE ROUTINE (ISR) -- funcs_isr.asm ------------------

ALIGN &100                ; start on new page
.ISR_handler
  pha : phx : phy         ; preserve CPU state on the stack
  ; Check which device caused the interrupt.

; --- CHECK VIA C TIMER --------------------------------------------------------
.isr_inc_c_timer
  bit VIAC_T1CL		            ; clears interrupt. Bit 6 copied to overflow flag
  bvc isr_inc_a_timer         ; overflow clear, so not this... on to next check
  inc VIAC_TIMER_COUNT
  bne isr_inc_c_timer_end
  inc VIAC_TIMER_COUNT + 1	  ; previous byte rolled over
.isr_inc_c_timer_end
  jmp isr_exit

; --- CHECK VIA A TIMER --------------------------------------------------------
.isr_inc_a_timer
  bit VIAA_T1CL		            ; clears interrupt. Bit 6 copied to overflow flag
  bvc isr_chk_acia            ; overflow clear, so not this... on to next check
  inc VIAA_TIMER_COUNT
  bne isr_inc_a_timer_end
  inc VIAA_TIMER_COUNT + 1	  ; previous byte rolled over
.isr_inc_a_timer_end
  jmp isr_exit

; --- CHECK ACIA ---------------------------------------------------------------
.isr_chk_acia
  bit ACIA_STAT_REG ; if it was the ACIA that set IRQ low, the N flag is now set
  bmi isr_acia      ; branch if N flag set to 1

; --- CHECK SC28L92 ------------------------------------------------------------
.isr_chk_SC28L92
  lda SC28L92_ISR              ; bit 1 of the SRA will be set if there's data
  and #%00000010
  bne isr_SC28L92

.isr_end_chks
  jmp isr_exit

.isr_acia
  ldx STDIN_IDX             ; load the value of the buffer index
  lda ACIA_DATA_REG         ; load the byte in the data register into A
  sta STDIN_BUF,X           ; and store it in the buffer, at the offset
  beq uart_rx_set_null      ; if byte is the 0 terminator, go set the null flag
  cmp #CHR_LINEEND          ; or is it a line end?
  bne isr_acia_end          ; if not 0 or CR, go to next step
  stz STDIN_BUF,X			      ; if CR, replace with NULL
.uart_rx_set_null
  lda UART_STATUS_REG       ; load our status register
  ora #STDIN_NUL_RCVD_FLG   ; set the null byte received flag
  sta UART_STATUS_REG       ; re-save the status
.isr_acia_end
  inx                       ; increment the index for next time
  stx STDIN_IDX             ; and save it
  lda ACIA_STAT_REG         ; Load ACIA status reg - resets interrupt bit
  jmp isr_exit

.isr_SC28L92
  ; the ISR needs to empty out the receive buffer (at least to the fill level
  ; selected) ibn order to clear the interrupt condition.
  ; In this example, we're just adding to the same receive buffer used by the
  ; ACIA. But in real life we'd probably want to use a separate buffer for
  ; different tasks.
  ldx STDIN_IDX             ; load the value of the buffer index
.isr_SC28L92_next_chr
  lda SC28L92_RxFIFOA       ; load the byte in the data register into A
  sta STDIN_BUF,X           ; and store it in the buffer, at the offset
  beq isr_SC28L92_set_null  ; if byte is the 0 terminator, go set the null flag
  cmp #CHR_LINEEND          ; or is it a line end?
  bne isr_SC28L92_end       ; if not 0 or CR, go to next step
  stz STDIN_BUF,X			      ; if line end, replace with NULL
.isr_SC28L92_set_null
  lda UART_STATUS_REG       ; load our status register
  ora #STDIN_NUL_RCVD_FLG   ; set the null byte received flag
  sta UART_STATUS_REG       ; re-save the status
.isr_SC28L92_end
  inx                       ; increment the index for next time
  lda SC28L92_SRA           ; load status reg to see if there are any more bytes
  and #SC28L92_RxRDY        ; check RxRDY bit
  bne isr_SC28L92_next_chr
  stx STDIN_IDX             ; and save it

.isr_exit
  ply : plx : pla           ; resume original register state
  rti
  