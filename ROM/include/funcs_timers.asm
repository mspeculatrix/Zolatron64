
\ ------------------------------------------------------------------------------
\ ---  DELAY
\ ---  Implements: OSDELAY
\ ------------------------------------------------------------------------------
\ General-purpose delay function. Blocking.
\ This isn't specific to the LCD, but we're using the LCD's VIA to provide
\ the timer.
\ ON ENTRY: - Assumes a 16-bit value in LCDV_TIMER_INTVL.
\             This number should be the length of the desired delay
\             in milliseconds.
\ A - P     X - n/a     Y - n/a
\ NB: The SYS_* constants are synonyms for the LCD VIA constants.
\ I created them in case I want to have a version of the Zolatron without
\ the LCD panel at some point.

._OSDELAY
.delay
  pha
  stz SYS_TIMER_COUNT		        ; Zero-out counter
  stz SYS_TIMER_COUNT + 1
  lda SYSV_IER
  ora #%11000000		            ; Bit 7 enables interrupts, b6 enables Timer 1
  sta SYSV_IER
  lda #%01000000                ; Set timer to free-run mode
  sta SYSV_ACR
  lda #$E6				  ; Going to use a base of 1ms. At 1MHz that's 1K cycles but,
  sta SYSV_T1CL     ; allowing for other operations, it's actually 998 ($03E6)
  lda #$03
  sta SYSV_T1CH		              ; Starts timer running
.delay_loop
  lda #100
.nop_loop                       ; Adding a small NOP loop to give the timer time
  nop                           ; to increase the counter
  dec A
  bne nop_loop
  jsr delay_timer_chk           ; Check how far our counter has got
  lda FUNC_RESULT
  cmp #LESS_THAN
  beq delay_loop                ; If still less than our target, go around again
  lda SYSV_IER
  and #%01111111                ; Disable TIMER 1 interrupts
  sta SYSV_IER
  pla
  stz FUNC_RESULT               ; Done with this, so zero out
  rts

.delay_timer_chk                ; Check to see if the counter has incremented
  sei                           ; to the same value as the set delay.
  lda SYS_TIMER_COUNT+1         ; Compare the high bytes first as if they aren't
  cmp SYS_TIMER_INTVL+1         ; equal, we don't need to compare the low bytes
  bcc delay_timer_chk_less_than ; Count is less than interval
  bne delay_timer_chk_more_than ; Count is more than interval
  lda SYS_TIMER_COUNT           ; High bytes were equal - what about low bytes?
  cmp SYS_TIMER_INTVL
  bcc delay_timer_chk_less_than
  bne delay_timer_chk_more_than
  lda #EQUAL				            ; COUNT = INTVL - this what we're looking for.
  jmp delay_timer_chk_end
.delay_timer_chk_less_than
  lda #LESS_THAN			          ; COUNT < INTVL - counter isn't big enough yet
  jmp delay_timer_chk_end       ; so let's bug out.
.delay_timer_chk_more_than
  lda #MORE_THAN			          ; COUNT > INTVL - shouldn't happen, but still...
.delay_timer_chk_end
  sta FUNC_RESULT
  cli
  rts
