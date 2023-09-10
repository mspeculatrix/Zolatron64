
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
  jsr OSSPIEXCH                   ; Value of byte at address now in A
  stz SPI_DEV_SEL                 ; End comms
  rts

\ ------------------------------------------------------------------------------
\ ---  SRAM_WRITE_BYTE
\ ------------------------------------------------------------------------------
\ Assumes that SRAM has been put into SRAM_BYTE_MODE using sram_set_WR_mode
\ ON ENTRY: - TMP_ADDR_A/+1 contains byte address
\           - Byte value in A
.sram_write_byte
  pha
  lda #SRAM_CMD_WRITE
  jsr sram_start_WR_op
  pla
  jsr OSSPIEXCH
  stz SPI_DEV_SEL                 ; End comms
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
  jsr OSSPIEXCH   ; Doesn't matter what's in A to start with
  sta SPI_BUF_32,X
  inx
  cpx #SRAM_PG_SZ
  bne sram_read_page_loop
  stz SPI_DEV_SEL                 ; End comms
  rts

\ ------------------------------------------------------------------------------
\ ---  SRAM_SET_WR_MODE
\ ------------------------------------------------------------------------------
\ ON ENTRY: - A contains mode code
.sram_set_WR_mode
  pha                       ; Set aside for a moment
  SPI_COMM_START
  lda #SRAM_CMD_WRMR        ; Send the relevant command
  jsr OSSPIEXCH
  pla                       ; Now send the mode code
  jsr OSSPIEXCH
  stz SPI_DEV_SEL                 ; End comms
  rts

\ ------------------------------------------------------------------------------
\ ---  SRAM_START_WR_OP
\ ------------------------------------------------------------------------------
\ ON ENTRY: - Device number must have been set in SPI_CURR_DEV
\.          - A contains operation code
\           - TMP_ADDR_A/+1 contains address
.sram_start_WR_op
  pha                               ; Keep A for later
  lda SPI_CURR_DEV                  ; Start comms
  sta SPI_DEV_SEL
  lda SPI_DATA_REG                  ; To clear TC flag, if set
  pla                               ; Get back operation code
  jsr OSSPIEXCH
  lda TMP_ADDR_A_H
  jsr OSSPIEXCH
  lda TMP_ADDR_A_L
  jsr OSSPIEXCH
  ; No stz SPI_DEV_SEL because that will be sent by function
  ; calling this one.
  rts

\ ------------------------------------------------------------------------------
\ ---  SRAM_WRITE_PAGE
\ ------------------------------------------------------------------------------
\ Assumes that SRAM has been put into SRAM_PAGE_MODE using sram_set_WR_mode
\ ON ENTRY: - TMP_ADDR_A/+1 contains start address
\           - SPI_BUF_32 buffer contains data to write
.sram_write_page
  lda #SRAM_CMD_WRITE
  jsr sram_start_WR_op
  ldx #0
.sram_write_page_loop
  lda SPI_BUF_32,X
  jsr OSSPIEXCH
  inx
  cpx #SRAM_PG_SZ
  bne sram_write_page_loop
  stz SPI_DEV_SEL                 ; End comms
  rts
