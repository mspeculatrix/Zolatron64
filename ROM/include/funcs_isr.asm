; FUNCTIONS: INTERRUPT SERVICE ROUTINE (ISR) -- funcs_isr.asm ------------------

ALIGN &100                ; start on new page
.IRQ_handler
  pha : phx : phy         ; preserve CPU state on the stack
  ; Check which device caused the interrupt.

; --- CHECK VIA C TIMER --------------------------------------------------------
;.isr_via_c_timer
;  bit VIAC_IFR                ; Bit 6 copied to overflow flag
;  bvc isr_via_c_timer_next    ; Overflow clear, so not this... on to next check
;  bit VIAC_T1CL		            ; Clears interrupt
;  inc VIAC_TIMER_COUNT
;  bne isr_via_c_timer_end
;  inc VIAC_TIMER_COUNT + 1	  ; previous byte rolled over
;.isr_via_c_timer_end
;  jmp isr_exit
;.isr_via_c_timer_next

; --- CHECK VIA B -- ZD TIMEOUT TIMER ------------------------------------------
.isr_zd_timer
  bit ZD_IFR                ; Bit 6 copied to overflow flag
  bvc isr_zd_timer_next     ; Overflow clear, so not this... on to next check
  bit ZD_T1CL               ; Clears interrupt
  inc ZD_TIMER_COUNT
  bne isr_zd_timer_end
  inc ZD_TIMER_COUNT + 1	  ; previous byte rolled over
.isr_zd_timer_end
  jmp isr_exit
.isr_zd_timer_next

; --- CHECK VIA A TIMER --------------------------------------------------------
.isr_via_a_timer
  bit VIAA_IFR                ; Bit 6 copied to overflow flag
  bvc isr_via_a_timer_next    ; overflow clear, so not this... on to next check
  bit VIAA_T1CL		            ; clears interrupt
  inc VIAA_TIMER_COUNT
  bne isr_via_a_timer_end
  inc VIAA_TIMER_COUNT + 1	  ; previous byte rolled over
.isr_via_a_timer_end
  jmp isr_exit
.isr_via_a_timer_next

; --- CHECK ACIA ---------------------------------------------------------------
.isr_chk_acia
  bit ACIA_STAT_REG ; if it was the ACIA that set IRQ low, the N flag is now set
  bmi isr_acia      ; branch if N flag set to 1

; --- CHECK SC28L92 ------------------------------------------------------------
;.isr_chk_SC28L92
;  lda SC28L92_ISR              ; bit 1 of the SRA will be set if there's data
;  and #DUART_RxA_RDY_FL
;  bne isr_SC28L92              ; if result not zero, that means RxRDYA bit set

.isr_end_chks
  jmp isr_exit

.isr_acia
  ldx STDIN_IDX             ; Load the value of the buffer index
  lda ACIA_DATA_REG         ; Load the byte in the data register into A
  sta STDIN_BUF,X           ; and store it in the buffer, at the offset
  beq uart_rx_set_null      ; If byte is the 0 terminator, go set the null flag
  cmp #CHR_LINEEND          ; Or is it a line end?
  bne isr_acia_end          ; If not 0 or line end, go to next step
  stz STDIN_BUF,X			      ; If CR, replace with NULL
.uart_rx_set_null
  lda STDIN_STATUS_REG      ; Load our status register
  ora #STDIN_NUL_RCVD_FLG   ; Set the null byte received flag
  sta STDIN_STATUS_REG      ; Re-save the status
.isr_acia_end
  inx                       ; Increment the index for next time
  stx STDIN_IDX             ; and save it.
  lda ACIA_STAT_REG         ; Load ACIA status reg - resets interrupt bit
  jmp isr_exit

;.isr_SC28L92
  ; The ISR needs to empty out the receive buffer (at least to the fill level
  ; selected) in order to clear the interrupt condition.
  ; We'll copy what's in the DUART FIFO into the buffer and set a flag.
  ; If the buffer is full, we'll dump the rest of the content in the FIFO.
;  ldx STDIN_IDX           ; Load the value of the buffer index
;.isr_SC28L92_next_chr
;  cpx #STR_BUF_LEN         ; Is the index at the maximum?
;  beq isr_SC28L92_buf_full    ; Yes, so ignore all further data.
;  lda SC28L92_RxFIFOA         ; Load the byte in the data register into A
;  sta STDIN_BUF,X         ; and store it in the buffer, at the offset
;  bne isr_SC28L92_cont        ; If byte not the 0 terminator, continue
;.isr_SC28L92_set_null
;  lda STDIN_STATUS_REG        ; Otherwise, load our status register
;  ora #DUART_RxA_NUL_RCVD_FL  ; Set the null byte received flag
;  sta STDIN_STATUS_REG        ; Re-save the status
;  jmp isr_SC28L92_cont
;.isr_SC28L92_buf_full         ; Simply read (and ignore) all the bytes.
;  lda SC28L92_SRA             ; Load status reg to see if more bytes await
;  and #SC28L92_RxRDY          ; Check RxRDY bit
;  bne isr_SC28L92_buf_full    ; If data, go around again
;  lda STDIN_STATUS_REG
; ora #DUART_RxA_BUF_FULL_FL
;  sta STDIN_STATUS_REG
; jmp isr_SC28L92_end
;.isr_SC28L92_cont
;  inx                         ; Increment the index for next time
;  lda SC28L92_SRA             ; Load status reg to see if more bytes waiting
;  and #SC28L92_RxRDY          ; Check RxRDY bit
;  bne isr_SC28L92_next_chr    ; If it's still set, there's more data...
;.isr_SC28L92_end
;  stx STDIN_IDX           ; Save index
;  lda STDIN_STATUS_REG
; ora #DUART_RxA_DATA_RCVD_FL
;  sta STDIN_STATUS_REG

.isr_exit
  ply : plx : pla             ; resume original register state
  rti
  