\ funcs_isr.asm

\ INTERRUPT SERVICE ROUTINE (ISR) ----------------------------------------------
\ A - P
\ X - P
\ Y - P

ALIGN &100                ; start on new page
.IRQ_handler
  pha : phx : phy         ; preserve CPU state on the stack

\ Check which device caused the interrupt.

; --- CHECK ZOLADOS VIA TIMEOUT TIMER ------------------------------------------
.isr_zd_timer
  bit ZD_IFR                ; Bit 6 copied to overflow flag
  bvc isr_zd_timer_next     ; Overflow clear, so not this... on to next check
  bit ZD_T1CL               ; Clears interrupt
  inc ZD_TIMER_COUNT
  bne isr_zd_timer_end
  inc ZD_TIMER_COUNT + 1	  ; Previous byte rolled over
.isr_zd_timer_end
  jmp isr_end_chks
.isr_zd_timer_next

; --- CHECK LCD VIA TIMER ------------------------------------------------------
.isr_lcdvia_timer
  bit LCDV_IFR                ; Bit 6 copied to overflow flag
  bvc isr_lcdvia_timer_next    ; Overflow clear, so not this... on to next check
  bit LCDV_T1CL		            ; Clears interrupt
  inc LCDV_TIMER_COUNT
  bne isr_lcdvia_timer_end
  inc LCDV_TIMER_COUNT + 1	  ; Previous byte rolled over
.isr_lcdvia_timer_end
  jmp isr_end_chks
.isr_lcdvia_timer_next

; --- CHECK SC28L92 ------------------------------------------------------------
.isr_chk_SC28L92
  lda SC28L92_ISR              ; Bit 1 of the ISR will be set if incoming data
  and #DUART_RxA_RDY_MASK      ; triggered the interrupt
  bne isr_SC28L92              ; If result not zero, that means RxRDYA bit set

.isr_chk_zolados
  lda ZD_CTRL_PORT
  and #ZD_INT_SEL
  beq isr_end_chks
  lda SYS_REG
  ora #PROC_ZD_INT_FL
  sta SYS_REG

.isr_end_chks
  jmp isr_exit

.isr_SC28L92
  ; The ISR needs to empty out the receive buffer (at least to the fill level
  ; selected) in order to clear the interrupt condition.
  ; We'll copy what's in the DUART FIFO into the buffer and set a flag.
  ; If the buffer is full, we'll dump the rest of the content in the FIFO.
  ldx STDIN_IDX               ; Load the value of the buffer index
.isr_SC28L92_next_chr
  cpx #STR_BUF_LEN            ; Is the index at the maximum?
  beq isr_SC28L92_buf_full    ; Yes, so ignore all further data.
  lda SC28L92_RxFIFOA         ; Load the byte in the data register into A
  sta STDIN_BUF,X             ; and store it in the buffer, at the offset
  beq isr_SC28L92_set_null    ; If the 0 terminator, set null
  cmp #CHR_LINEEND            ; Is this a linefeed?
  bne isr_SC28L92_cont        ; If not, skip ahead
  stz STDIN_BUF,X             ; Otherwise replace with null
.isr_SC28L92_set_null
  lda STDIN_STATUS_REG        ; Load our status register
  ora #DUART_RxA_NUL_RCVD_FL  ; Set the null byte received flag
  sta STDIN_STATUS_REG        ; Re-save the status register
  jmp isr_SC28L92_cont
.isr_SC28L92_buf_full         ; Simply read (and ignore) all the bytes.
  lda SC28L92_SRA             ; Load status reg to see if more bytes await
  and #SC28L92_RxRDY          ; Check RxRDY bit
  bne isr_SC28L92_buf_full    ; If data, go around again
  lda STDIN_STATUS_REG        ; Otherwise set our buffer full flag
  ora #DUART_RxA_BUF_FULL_FL
  sta STDIN_STATUS_REG
  jmp isr_SC28L92_end
.isr_SC28L92_cont
  inx                         ; Increment the index for next time
  lda SC28L92_SRA             ; Load status reg to see if more bytes waiting
  and #SC28L92_RxRDY          ; Check RxRDY bit
  bne isr_SC28L92_next_chr    ; If it's still set, there's more data...
.isr_SC28L92_end
  stx STDIN_IDX               ; Save index
  lda STDIN_STATUS_REG        ; Update register to show that data has
  ora #DUART_RxA_DAT_RCVD_FL  ; been received.
  sta STDIN_STATUS_REG
  jmp isr_exit

.isr_exit
  ply : plx : pla             ; Resume original register state
  rti
