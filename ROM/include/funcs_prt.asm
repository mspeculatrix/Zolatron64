\ funcs_prt.asm

\ ------------------------------------------------------------------------------
\ ---  PRT_INIT
\ ------------------------------------------------------------------------------
\ Set up the VIA.
.prt_init 
  lda #PRT_CTRL_PT_DIR              ; Set pin directions
  sta PRT_CTRL_DDR
  lda #$FF                          ; Set data port to output
  sta PRT_DATA_DDR
  stz PRT_DATA_PORT
  lda PRT_CTRL_PORT                 ; Set outputs high to start
  ora #%11010000                    
  sta PRT_CTRL_PORT


  rts