\ ------------------------------------------------------------------------------
\ ---  SPI_EXCHANGE_BYTE
\ ---  Implements: OSSPIEXCH
\ ------------------------------------------------------------------------------
\ ON ENTRY: Byte to send should be in A
\ ON EXIT : Returned byte is in A
\ A - O     X - n/a     Y - n/a
.spi_exchange_byte	  ; Sends & receives a byte. Byte value should be in A
  sei
;  pha
;  LOAD_MSG send_msg
;  jsr OSWRMSG
;  pla
;  pha
;  jsr OSB2HEX
;  jsr OSWRSBUF
;  pla
  sta SPI_DATA_REG		; Write to Data Reg
.spi_wait_for_tc	  	; Wait for transfer
  bit SPI_STAT_REG		; Run BIT on Status Reg. If TC set, N flag will be set
  bpl spi_wait_for_tc	; If positive, bit 7 not set yet
  lda SPI_DATA_REG		; Read incoming byte. Clears TC flag

;  pha
;  LOAD_MSG recv_msg
;  jsr OSWRMSG
;  pla
;  pha
;  jsr OSB2HEX
;  jsr OSWRSBUF
;  NEWLINE
;  pla

  cli
  rts

.send_msg
  equs "send: ",0
.recv_msg
  equs " - recv: ",0
