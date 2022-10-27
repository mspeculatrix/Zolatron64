\ funcs_prng.asm

\ PSEUDO-RANDOM NUMBER GENERATOR FUNCTIONS

\ ------------------------------------------------------------------------------
\ ---  PRNG_RAND8
\ ------------------------------------------------------------------------------
\ Creates an 8-bit pseudo-random number.
\ BEFORE CALLING THIS FUNCTION FOR THE FIRST TIME you must have started the
\ timer (prng_start_timer) and have seeded the RAND_SEED variable by calling
\ prng_set_seed at a suitably random moment.
\ ON EXIT : - A contains random number
\           - Same number also in RAND_SEED
.prng_rand8
  phy
  ldy #8                    ; We're going to loop 8 times
.prng_rand8_loop
  lda RAND_SEED             ; Load whatever is in this location
  beq prng_rand8_eor        ; If it's a 0, do the XOR thing
  asl A                     ; Otherwise, shift left
  beq prng_rand8_no_eor     ; If the result of this is 0, we can use that
  rol RAND_SEED + 1         ; Otherwise roll upper byte left
  bcc prng_rand8_no_eor     ; If nothing rolled into carry bit, skip the XOR
.prng_rand8_eor					    ; If carry was set by ROL, do an XOR
  eor #$1D                  ; A handy bit pattern to make things seem random
.prng_rand8_no_eor
  dey
  bne prng_rand8_loop
  sta RAND_SEED
  ply
  rts

\ ------------------------------------------------------------------------------
\ ---  PRNG_SET_SEED
\ ------------------------------------------------------------------------------
.prng_set_seed
  pha
  lda USRP_T1CL           ; Get the current counter value & use it for the
  sta RAND_SEED           ; low byte
  lda USRP_T1CH           ; Get the counter high byte
  eor #$1D                ; XOR it to mix things up a little
  sta RAND_SEED + 1       ; and store as the seed high byte
  pla
  rts

\ ------------------------------------------------------------------------------
\ ---  PRNG_START_TIMER
\ ------------------------------------------------------------------------------
\ Using Timer 1 for random numbers. This runs in free-run mode, counting down
\ constantly. We read the low byte at suitably random moments to get a random
\ value 0-255.
.prng_start_timer
  pha
  lda #%01000000		          ; Bit 7 off - don't need interrupts
  sta USRP_IER
  lda #%01000000              ; Set timer to free-run mode
  sta USRP_ACR
  lda #255                    ; Start value
  sta USRP_T1CL
  lda #0
  sta USRP_T1CH		            ; Starts timer running
  pla
  rts
