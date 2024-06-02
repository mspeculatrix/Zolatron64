\ INTERRUPT SERVICE ROUTINE (ISR) -- funcs_isr.asm -----------------------------
\ A - P     X - P     Y - P

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
  jmp isr_exit
.isr_zd_timer_next

; --- CHECK LCD VIA TIMER ------------------------------------------------------
.isr_lcdvia_timer
  bit LCDV_IFR                 ; Bit 6 copied to overflow flag
  bvc isr_lcdvia_timer_next    ; Overflow clear, so not this... on to next check
  bit LCDV_T1CL		             ; Clears interrupt
  inc LCDV_TIMER_COUNT
  bne isr_lcdvia_timer_end
  inc LCDV_TIMER_COUNT + 1	   ; Previous byte rolled over
.isr_lcdvia_timer_end
  jmp isr_exit
.isr_lcdvia_timer_next

; --- CHECK SC28L92 ------------------------------------------------------------
.isr_chk_SC28L92
  lda SC28L92_ISR               ; Bit 1 of the ISR will be set if incoming data
  and #DUART_RxA_RDY_MASK       ; triggered the interrupt
  beq isr_chk_SC28L92_next      ; If result is zero, RxRDYA bit is not set
  jmp isr_SC28L92               ; Otherwise go to the SC28L92 handlng routine
.isr_chk_SC28L92_next

; --- CHECK ZOLADOS IRQ --------------------------------------------------------
; *** NOT SURE THIS IS BEING USED ???? ***
;.isr_chk_zolados
;  lda ZD_CTRL_PORT              ; Load the control port state
;  and #ZD_INT_SEL               ; Check the IRQ bit
;  beq isr_chk_zolados_next      ; If clear, not this, so jump to next check
;  lda IRQ_REG                   ; Load SYS_REG
;  ora #ZD_IRQ                   ; and set the appropriate flag
;  sta IRQ_REG                   ; Store SYS_REG again
;  jmp isr_exit                  ; Done doing checks
;.isr_chk_zolados_next

; --- CHECK USER PORT IRQs -----------------------------------------------------
.isr_chk_usrp
  lda USRP_IFR                  ; Load the user port interrupt flags
  beq isr_chk_usrp_next         ; If zero, no interrupts to report, move on
  ora IRQ_REG                   ; Otherwise combine with what's in IRQ_REG
  sta IRQ_REG                   ; Store the result
  lda #%01111111                ; Reset the user port interrupt flags
  sta USRP_IFR
  jmp isr_exit                  ; Done doing checks
.isr_chk_usrp_next

; --- CHECK RTC ALARM ----------------------------------------------------------
.isr_chk_rtc
  jmp isr_chk_rtc_next  ; *** TEMPORARY *** skip this section for now
  ;
  ; **** THIS CODE IS UNTESTED ****
  ;
  lda SYS_REG                   ; Check register to see if SPI board fitted
  and #SYS_SPI
  beq isr_chk_rtc_next          ; No SPI board fitted
  lda #SPI_DEV_RTC              ; Select the RTC
  sta SPI_DEV_SEL
  lda #RTC_STAT_REG             ; Select the status register
  lda SPI_DATA_REG              ; Comm start
  lda SPI_CURR_DEV
  sta SPI_DEV_SEL

  jsr spi_exchange_byte			    ; Selects the reg, don't care what's in A
  jsr spi_exchange_byte			    ; Sends dummy value, register value is in A
  stz SPI_DEV_SEL
  tay                           ; Keep RTC_STAT_REG value for later
  and #%00000001                ; Check Alarm 1 flag
  beq isr_chk_rtc_next          ; If it's 0, not this, go on to next check
  lda IRQ_REG                   ; Load SYS_REG
  ora #RTC_ALARM                ; and set the appropriate flag
  sta IRQ_REG                   ; Store SYS_REG again
  tya                           ; Bring back RTC_STAT_REG value
  and #%11111100                ; Unset the interrupt flags
  tax                           ; Put in X as value to write to register
  lda #RTC_STAT_REG             ; Load RTC_STAT_REG number
  ora $80                       ; Set high bit to select write operation
  lda SPI_DATA_REG              ; Comm start
  lda SPI_CURR_DEV
  sta SPI_DEV_SEL

  jsr spi_exchange_byte			    ; Select the reg
  txa                           ; Put the value to write in A
  jsr spi_exchange_byte			    ; Send value
  lda #SPI_DEV_NONE
  sta SPI_DEV_SEL
.isr_chk_rtc_next

; --- USER ISR -----------------------------------------------------------------
; --- This needs to be the last of the checks.
  jmp (OSUSRINT_VEC)
.isr_usrint_rtn                 ; Label for return address - this is important

; --- END OF CHECKS ------------------------------------------------------------
.isr_end_checks
  jmp isr_exit

; --- HANDLING ROUTINES --------------------------------------------------------
.isr_SC28L92
  ; The ISR needs to empty out the receive buffer (at least to the fill level
  ; selected) in order to clear the interrupt condition.
  ; We'll copy what's in the DUART FIFO into the buffer and set a flag.
  ; If the buffer is full, we'll dump the rest of the content in the FIFO.
  ; At the start of this routine, STDIN_IDX should contain a value pointing
  ; to the next free byte in the input buffer.
  ldx STDIN_IDX               ; Load the value of the buffer index
.isr_SC28L92_next_chr
  cpx #STR_BUF_LEN            ; Is the index at the maximum?
  beq isr_SC28L92_buf_full    ; Yes, so ignore all further data.
  lda SC28L92_RxFIFOA         ; Load the byte in the data register into A
  sta STDIN_BUF,X             ; and store it in the buffer, at the offset
  bne isr_SC28L92_cont        ; If not the 0 terminator, skip ahead
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
  lda STDIN_BUF,X             ; Reload our byte
  cmp #8                      ; Is it a Backspace?
  bne isr_SC28L92_notbs       ; - no ...
  dex                         ; - yes ...
  bmi isr_SC28L92_resetidx    ; We've gone beyond start of buffer
  jmp isr_SC28L92_wrapup
.isr_SC28L92_notbs            ; Wasn't a Backspace
  inx                         ; Increment the index for next time
  jmp isr_SC28L92_wrapup
.isr_SC28L92_resetidx
  ldx #0
.isr_SC28L92_wrapup
  lda SC28L92_SRA             ; Load status reg to see if more bytes waiting
  and #SC28L92_RxRDY          ; Check RxRDY bit
  bne isr_SC28L92_next_chr    ; If it's still set, there's more data...
.isr_SC28L92_end
  stx STDIN_IDX               ; Save index
  lda STDIN_STATUS_REG        ; Update register to show that data has
  ora #DUART_RxA_DAT_RCVD_FL  ; been received.
  sta STDIN_STATUS_REG
  ;jmp isr_exit

.isr_exit
  ply : plx : pla             ; Resume original register state
  rti
