; FUNCTIONS: MATHS & Numbers -- funcs_math.asm ---------------------------------
; v01 - 25 Nov 2021

.subtract16u
  ; subtracts a 16-bit number stored in INT16uB from another 16-bit value
  ; in INT16uA.
  pha
  sec
  lda INT16uA
  sbc INT16uB
  sta FUNC_RES_L
  lda INT16uA + 1
  sbc INT16uB + 1
  sta FUNC_RES_H
  pla
  rts

.compare16u                 ; Compare two 16-bit unsigned values
  pha
  lda INT16uA+1
  cmp INT16uB+1
  bcc compare16u_less_than
  bne compare16u_more_than
  lda INT16uA
  cmp INT16uB
  bcc compare16u_less_than
  bne compare16u_more_than
  lda #EQUAL				          ; A = B
  jmp compare16u_end
.compare16u_less_than
  lda #LESS_THAN			        ; A < B
  jmp compare16u_end
.compare16u_more_than
  lda #MORE_THAN			        ; A > B
.compare16u_end
  sta FUNC_RESULT
  pla
  rts

.compare32u                 ; Compare two 32-bit unsigned values
  pha
  lda INT32uA+3
  cmp INT32uB+3
  bcc compare32u_less_than  ; NUMA < NUMB
  bne compare32u_more_than	; if NUMA+3 <> NUMB+3 then NUMA > NUMB 
  lda INT32uA+2
  cmp INT32uB+2
  bcc compare32u_less_than
  bne compare32u_more_than
  lda INT32uA+1
  cmp INT32uB+1
  bcc compare32u_less_than
  bne compare32u_more_than
  lda INT32uA
  cmp INT32uB
  bcc compare32u_less_than
  bne compare32u_more_than
  lda #EQUAL				          ; A = B
  jmp compare32u_end
.compare32u_less_than
  lda #LESS_THAN			        ; A < B
  jmp compare32u_end
.compare32u_more_than
  lda #MORE_THAN			        ; A > B
.compare32u_end
  sta FUNC_RESULT
  pla
  rts
