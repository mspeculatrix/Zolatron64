\ --- funcs_VIAA.asm

\ ------------------------------------------------------------------------------
\ ---  DELAY
\ ------------------------------------------------------------------------------
\ General-purpose delay function. Assumes a 16-bit value in VIAA_TIMER_INTVL.
\ This number should be the length of the desired delay in milliseconds.
.delay
  pha
  stz VIAA_TIMER_COUNT		    ; Zero-out counter
  stz VIAA_TIMER_COUNT + 1
  lda #%11000000		          ; Bit 7 enables interrupts, bit 6 enables Timer 1
  sta VIAA_IER
  lda #%01000000              ; Set timer to free-run mode
  sta VIAA_ACL			
  lda #$E6				  ; Going to use a base of 1ms. At 1MHz that's 1K cycles but
  sta VIAA_T1CL     ; allowing for other operations, it's actually 998 ($03E6)
  lda #$03
  sta VIAA_T1CH		            ; Starts timer running
.delay_loop
  lda #100
.nop_loop                     ; Adding a NOP loop to give the processor time
  nop                         ; to increase the counter
  dec A 
  bne nop_loop
  jsr delay_timer_chk         ; Check how far our counter has got
  lda FUNC_RESULT
  cmp #LESS_THAN
  beq delay_loop              ; If still less than our target, go around again
  lda #%01000000              ; Disable TIMER 1 interrupts
  sta VIAA_IER
  pla
  rts

.delay_timer_chk              ; Check to see if the counter has incremented
  pha                         ; to the same value as the set delay. This is
  sei                         ; basically a standard 16-bit comparison.
  lda VIAA_TIMER_COUNT+1      ; Compare the high bytes first as if they aren't
  cmp VIAA_TIMER_INTVL+1      ; equal, we don't need to compare the low bytes
  bcc delay_timer_chk_less_than                 ; Count is less than interval
  bne delay_timer_chk_more_than                 ; Count is more than interval
  lda VIAA_TIMER_COUNT        ; High bytes were equal - what about low bytes?
  cmp VIAA_TIMER_INTVL
  bcc delay_timer_chk_less_than
  bne delay_timer_chk_more_than
  lda #EQUAL				          ; COUNT = INTVL - this what we're looking for.
  jmp delay_timer_chk_end
.delay_timer_chk_less_than
  lda #LESS_THAN			        ; COUNT < INTVL - counter isn't big enough yet
  jmp delay_timer_chk_end     ; so let's bug out.
.delay_timer_chk_more_than
  lda #MORE_THAN			        ; COUNT > INTVL - shouldn't happen, but still...
.delay_timer_chk_end
  sta FUNC_RESULT
  cli
  pla
  rts
