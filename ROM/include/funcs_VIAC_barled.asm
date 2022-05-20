; Subroutines for 16-bit bar LED display

.barled_show			          ; display a 16-bit value on the BAR LEDs
  pha
  lda BARLED_L
  sta VIAC_PORTA
  lda BARLED_H
  sta VIAC_PORTB
  pla
  rts 

;.barled_count               ; increment and display a 16-bit counter on BAR LEDs
;  inc BARLED_L
; bne barled_count_end
 ; inc BARLED_H
;.barled_count_end
;  jsr barled_show
;  rts

;.viac_init_timer
;  stz VIAC_TIMER_COUNT		    ; zero-out counter
;  stz VIAC_TIMER_COUNT + 1
;  lda #%11000000		; setting bit 7 enables interrupts and bit 6 enables Timer 1
;  sta VIAC_IER
;  lda #%01000000    ; set timer to free-run mode
;  sta VIAC_ACL			
;  lda #$0E				  ; going to use a base of 10ms. At 1MHz that's 10K cycles but
;  sta VIAC_T1CL     ; allowing for other operations, it's actually 9998 ($270E)
;  lda #$27
;  sta VIAC_T1CH		  ; starts timer
;  rts

;.viac_chk_timer                 ; check to see if the counter has incremented
;  sei                           ; to the same value as the set interval. This is
;  pha                           ; basically a standard 16-bit comparison.
;  lda VIAC_TIMER_COUNT+1        ; compare the high bytes first as if they aren't
;  cmp VIAC_TIMER_INTVL+1        ; equal, we don't need to compare the low bytes
;  bcc viac_chk_timer_less_than  ; count is less than interval
;  bne viac_chk_timer_more_than  ; count is more than interval
;  lda VIAC_TIMER_COUNT          ; high bytes were equal - what about low bytes?
;  cmp VIAC_TIMER_INTVL
;  bcc viac_chk_timer_less_than
;  bne viac_chk_timer_more_than
;  lda #EQUAL				            ; COUNT = INTVL - this what we're looking for.
;  jmp viac_chk_timer_reset
;.viac_chk_timer_less_than
;  lda #LESS_THAN			          ; COUNT < INTVL - counter isn't big enough yet
;  jmp viac_chk_timer_end        ; so let's bug out.
;.viac_chk_timer_more_than
;  lda #MORE_THAN			          ; COUNT > INTVL - shouldn't happen, but still...
;.viac_chk_timer_reset
;  stz VIAC_TIMER_COUNT          ; reset counter
;  stz VIAC_TIMER_COUNT + 1
;.viac_chk_timer_end
;  sta FUNC_RESULT
;  pla
;  cli
;  rts
