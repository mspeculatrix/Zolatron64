
\ ------------------------------------------------------------------------------
\ ---  SRAM_READ_BYTE
\ ------------------------------------------------------------------------------
\ Assumes that SRAM has been put into SRAM_BYTE_MODE using sram_set_WR_mode
\ Replicates: readByte()
\ ON ENTRY: - TMP_ADDR_A/+1 contains byte address
\ ON EXIT : - Byte value in A
.sram_read_byte
  lda #SRAM_CMD_READ
  jsr sram_start_WR_op
  jsr spi_exchange_byte             ; Value of byte at address now in A
  SPI_COMM_END
  rts

\ ------------------------------------------------------------------------------
\ ---  SRAM_READ_PAGE
\ ------------------------------------------------------------------------------
\ Assumes that SRAM has been put into SRAM_PAGE_MODE using sram_set_WR_mode
\ Replicates: readPage()
\ ON ENTRY: - TMP_ADDR_A/+1 contains start address
\ ON EXIT : - Memeory contents have been read into SPI_BUF_32 buffer
.sram_read_page
  lda #SRAM_CMD_READ
  jsr sram_start_WR_op
  ldx #0
.sram_read_page_loop
  jsr spi_exchange_byte   ; Doesn't matter what's in A to start with
  sta SPI_BUF_32,X
  inx
  cpx #SRAM_PG_SZ
  bne sram_read_page_loop
  SPI_COMM_END
  rts

\ ------------------------------------------------------------------------------
\ ---  SRAM_SET_WR_MODE
\ ------------------------------------------------------------------------------
\ Replicates: setWRMode()
\ ON ENTRY: - A contains mode code
.sram_set_WR_mode
  pha                       ; Set aside for a moment
  SPI_COMM_START
  lda #SRAM_CMD_WRMR        ; Send the relevant command
  jsr spi_exchange_byte
  pla                       ; Now send the mode code
  jsr spi_exchange_byte
  SPI_COMM_END
  rts

\ ------------------------------------------------------------------------------
\ ---  SRAM_START_WR_OP
\ ------------------------------------------------------------------------------
\ Replicates: _startWROp()
\ ON ENTRY: - A contains operation code
\           - TMP_ADDR_A/+1 contains address
.sram_start_WR_op
  SPI_COMM_START
  jsr spi_exchange_byte
  lda TMP_ADDR_A_H
  jsr spi_exchange_byte
  lda TMP_ADDR_A_L
  jsr spi_exchange_byte
  ; No SPI_COMM_END because that will be sent by function
  ; calling this one.
  rts

\ ------------------------------------------------------------------------------
\ ---  SRAM_WRITE_PAGE
\ ------------------------------------------------------------------------------
\ Replicates: writePage()
\ Assumes that SRAM has been put into SRAM_PAGE_MODE using sram_set_WR_mode
\ ON ENTRY: - TMP_ADDR_A/+1 contains start address
\           - SPI_BUF_32 buffer contains data to write
.sram_write_page
  lda #SRAM_CMD_WRITE
  jsr sram_start_WR_op
  ldx #0
.sram_write_page_loop
  lda SPI_BUF_32,X
  jsr spi_exchange_byte
  inx
  cpx #SRAM_PG_SZ
  bne sram_write_page_loop
  SPI_COMM_END
  rts
