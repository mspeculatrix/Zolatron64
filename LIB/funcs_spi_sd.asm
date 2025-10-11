\ FUNCS-SPI-SD.ASM

;uint32_t SD_clusterFirstSector(uint32_t cluster, SDpartition *partition);
;void SD_getFileInfo(uint8_t record[], SDfile *file, SDpartition *partition);
;void SD_getPartitionData(SDpartition *partition);
;uint8_t SD_read(uint8_t device, uint8_t cmd, uint32_t argument, uint8_t crc, uint8_t* buffer, uint16_t buf_sz);
;uint8_t SD_readBlock(uint8_t device, uint32_t blkAddr, uint8_t* buffer, uint16_t buf_sz);
;uint32_t SD_readFatEntry(uint32_t cluster, SDpartition *partition);

\ ------------------------------------------------------------------------------
\ ---  SD_CLEAR_CMD_ARGS
\ ------------------------------------------------------------------------------
.sd_clear_cmd_args
  ldx #3
.sd_clear_cmd_args_loop
  stz SD_CMD_ARGS,X
  dex
  bpl sd_clear_cmd_args_loop
  rts

\ ------------------------------------------------------------------------------
\ ---  SD_CMD0_GO_IDLE
\ ------------------------------------------------------------------------------
\ ON EXIT : - If successful, response will be in SD_RESP_BUF
\           - FUNC_ERR will contain error code (0 for no error)
.sd_cmd0_go_idle
  lda #SD_CMD0_GO_IDLE                  ; Load command number
  sta SD_CMD_NUM
  jsr sd_clear_cmd_args                 ; Set all args to 0
  lda #SD_CMD0_CRC                      ; Load CRC value
  sta SD_CMD_CRC
  lda #SD_RESP_R1                       ; How many bytes are we expecting
  sta SD_CMD_RESP_SZ                    ; in the response?
  jsr sd_send_cmd
  rts

\ ------------------------------------------------------------------------------
\ ---  SD_CMD8_IF_COND
\ ------------------------------------------------------------------------------
\ ON EXIT : - If successful, response will be in SD_RESP_BUF
\           - FUNC_ERR will contain error code (0 for no error)
.sd_cmd8_if_cond
  lda #SD_CMD8_SND_IF_COND                  ; Load command number
  sta SD_CMD_NUM
  jsr sd_clear_cmd_args
  lda #<SD_CMD8_ARG
  sta SD_CMD_ARGS + 3
  lda #>SD_CMD8_ARG
  sta SD_CMD_ARGS + 2
  lda #SD_CMD8_CRC                      ; Load CRC value
  sta SD_CMD_CRC
  lda #SD_RESP_R3_R7                    ; How many bytes are we expecting
  sta SD_CMD_RESP_SZ                    ; in the response?
  jsr sd_send_cmd
  rts

.sd_cmd41_op_cond
  ; SEND CMD55/41 combination - expected response 0x00
  ; Try multiple times - may take up to 1sec
  lda #SD_INIT_MAX_ATTEMPTS
  sta TMP_COUNT
.sd_cmd41_op_cond_loop
  jsr sd_clear_cmd_args                 ; Set all args to 0
  lda #SD_CMD55_APP_CMD                  ; Load command number
  sta SD_CMD_NUM
  lda #SD_CMD55_CRC                      ; Load CRC value
  sta SD_CMD_CRC
  lda #SD_RESP_R1                       ; How many bytes are we expecting
  sta SD_CMD_RESP_SZ                    ; in the response?
  jsr sd_send_cmd

  lda #SD_CMD41_APPSND_OPCOND                  ; Load command number
  sta SD_CMD_NUM
  lda #>SD_CMD41_ARG_HIGHW
  sta SD_CMD_ARGS
  lda #<SD_CMD41_ARG_HIGHW
  sta SD_CMD_ARGS + 1
  lda #SD_CMD41_CRC                      ; Load CRC value
  sta SD_CMD_CRC
  lda #SD_RESP_R1                       ; How many bytes are we expecting
  sta SD_CMD_RESP_SZ                    ; in the response?
  jsr sd_send_cmd

  lda SD_RESP_BUF
  beq sd_cmd41_op_cond_ok               ; If response is 0, we're good
  dec TMP_COUNT
  beq sd_cmd41_op_cond_fail

  lda #<SD_INIT_DELAY
  sta LCDV_TIMER_INTVL
  lda #>SD_INIT_DELAY
  sta LCDV_TIMER_INTVL + 1
  jsr OSDELAY

  jmp sd_cmd41_op_cond_loop
.sd_cmd41_op_cond_fail
  lda #SD_ERR_OPCOND
  sta FUNC_ERR
.sd_cmd41_op_cond_ok
  rts

\ ------------------------------------------------------------------------------
\ ---  SD_CMD58_READ_OCR
\ ------------------------------------------------------------------------------
\ ON EXIT : - If successful, response will be in SD_RESP_BUF
\           - FUNC_ERR will contain error code (0 for no error)
.sd_cmd58_read_ocr
  lda #SD_CMD58_READ_OCR                ; Load command number
  sta SD_CMD_NUM
  jsr sd_clear_cmd_args                 ; Set all args to 0
  lda #SD_CMD58_CRC                     ; Load CRC value
  sta SD_CMD_CRC
  lda #SD_RESP_R3_R7                    ; How many bytes are we expecting
  sta SD_CMD_RESP_SZ                    ; in the response?
  jsr sd_send_cmd
  rts

\ ------------------------------------------------------------------------------
\ ---  SD_SELECT
\ ------------------------------------------------------------------------------
\ Set SD card drive as current SPI device.
.sd_select
  lda #SPI_DEV_SD               ; Select the SD
  sta SPI_CURR_DEV
  lda #%00000000                ; Set SPI Mode 0 on 65SPI
  sta SPI_CTRL_REG
  rts

\ ------------------------------------------------------------------------------
\ ---  SD_SEND_CMD
\ ------------------------------------------------------------------------------
\ ON ENTRY: - Parameters should be set in SD_CMD_PARAMS
\ ON EXIT : - SD_RESP_BUF contains R1 response. This will have MSB set if there
\             was an error.
\           - FUNC_ERR contains error code (0 if no error).
.sd_send_cmd
  ; Clear the response buffer
  stz FUNC_ERR
  ldx #0
.sd_send_cmd_clr_buf_loop
  stz SD_RESP_BUF,X
  inx
  cpx #SD_RESP_BUF_SZ
  bne sd_send_cmd_clr_buf_loop

  SD_START_OP
  ; Send command
  lda SD_CMD_NUM
  ora #%01000000          ; // Set start bits. Bit 7 is naturally 0 anyway
  jsr OSSPIEXCH           ; Send command

  ; Send arguments - the 32-bit values in SD_CMD_ARGS are big-endian, so
  ; MSB is sent first.
  ldy #0                  ; Loop counter
.sd_send_cmd_arg_loop     ; Send Argument
  lda SD_CMD_ARGS,Y
  jsr OSSPIEXCH
  iny
  cpy #4
  bne sd_send_cmd_arg_loop

  ; Send CRC
  lda SD_CMD_CRC                ; Load appropriate CRC value
  ora #%00000001                ; Set stop bit
  jsr OSSPIEXCH

  ; Get response from SD card.
  ; Seems to need multiple attempts. Simply delaying doesn't work.
  ldy #SD_MAX_RESP_ATTEMPTS
.sd_send_cmd_resp_loop
  lda #SD_RESP_DELAY            ; Otherwise, delay before trying again
  sta LCDV_TIMER_INTVL
  stz LCDV_TIMER_INTVL + 1
  jsr OSDELAY
  lda #$AA                      ; Arbitrary value to send
  jsr OSSPIEXCH                 ; A valid response does NOT have bit 7 set
  sta SD_RESP_BUF               ; Store response, whatever
  and #%10000000
  beq sd_send_cmd_resp_ok       ; Got a valid response
  dey                           ; Decrement counter
  beq sd_send_cmd_resp_err      ; If zero, we've used up all our tries
  jmp sd_send_cmd_resp_loop
.sd_send_cmd_resp_err           ; We're here because we ran out of attempts
  lda #SD_ERR_RESP_TO           ; Load the timeout error code
  sta FUNC_ERR
  jmp sd_send_cmd_done
.sd_send_cmd_resp_ok            ; Means the first resp byte was valid
  ldx #1
.sd_send_cmd_get_loop           ; Get remaining bytes of the response (if any)
  dec SD_CMD_RESP_SZ            ; Decrement up front because some commands have
  beq sd_send_cmd_done          ; only a single byte response
  jsr OSSPIEXCH                 ; Grab another byte
  sta SD_RESP_BUF,X
  jmp sd_send_cmd_get_loop
.sd_send_cmd_done
  SD_STOP_OP
  rts

\ ------------------------------------------------------------------------------
\ ---  SD_INIT
\ ------------------------------------------------------------------------------
\ Put the SD card into SPI mode. This routine is also included in the ROM code,
\ during the initialisation. After the Z64 is started, then, you shouldn't
\ have to call this again. I may transfer this to the -dev library.
.sd_init
  ; PICO/MOSI line needs to be HIGH, but this seems to be its natural state
  lda #SPI_DEV_NONE               ; We need to do this operation with the CS
  sta SPI_DEV_SEL                 ; line high - yes, high
  ; Cycle clock at least 74 times - we'll 'send' 10 bytes - ie, 80 clock cycles
  ldx #10
  lda #$FF
.sd_init_loop
  jsr OSSPIEXCH
  dex
  bne sd_init_loop
  rts

;/* Utility functions */
;uint16_t read2byteVal(uint8_t *buf, uint16_t startOffset);
;uint32_t read4byteVal(uint8_t *buf, uint16_t startOffset);

\ ------------------------------------------------------------------------------
\ ---  SD_PRINT_ERROR
\ ------------------------------------------------------------------------------
.sd_print_error
  LOAD_MSG sd_err_prefix
  jsr OSWRMSG             ; Print to console
  jsr OSLCDMSG            ; Print to LCD
  lda FUNC_ERR
  and #%01111111          ; Remove high bit because codes start at 129.
  dec A                   ; To get offset for table
  asl A                   ; Shift left to multiply by 2
  tax                     ; Move to X to use as offset
  lda sd_error_ptrs,X     ; Get LSB of relevant address from the cmd_ptrs table
  sta MSG_VEC             ; and put in MSG_VEC
  lda sd_error_ptrs+1,X   ; Get MSB
  sta MSG_VEC+1           ; and put in MSG_VEC high byte
  jsr OSWRMSG             ; Print to console
  jsr OSLCDMSG            ; Print to LCD
  rts

\ ------------------------------------------------------------------------------
\ ---  SD_STARTUP
\ ------------------------------------------------------------------------------
\ Initial routines to get the SD card online and ready.
.sd_startup
  ldx #SD_IDLE_MAX_ATTEMPTS
.sd_startup_cmd0_loop
  ; Load command config for a CMD0 - expected response $01
  jsr sd_cmd0_go_idle
  lda FUNC_ERR
  bne sd_startup_cmd0_err
  lda SD_RESP_BUF
  cmp #1
  bne sd_startup_cmd0_resp_err
  jmp sd_startup_cmd8_ifcond
.sd_startup_cmd0_resp_err
  DELAY SD_IDLE_DELAY
  lda #SD_ERR_IDLE
  sta FUNC_ERR
.sd_startup_cmd0_err
  dex
  bne sd_startup_cmd0_loop
  jmp sd_startup_done

.sd_startup_cmd8_ifcond ; Command Interface Condition - expected response $01
  jsr sd_cmd8_if_cond
  lda FUNC_ERR
  bne sd_startup_cmd8_err
  lda SD_RESP_BUF
  cmp #1
  bne sd_startup_cmd8_resp_err
  jmp sd_startup_cmd_opcond
.sd_startup_cmd8_resp_err
  lda #SD_ERR_IFCOND
  sta FUNC_ERR
.sd_startup_cmd8_err
  jmp sd_startup_done

.sd_startup_cmd_opcond
  jsr sd_cmd41_op_cond
  ;lda FUNC_ERR
  ;bne sd_startup_done

.sd_startup_done

  rts


\ ------------------------------------------------------------------------------
\ ---  DATA
\ ------------------------------------------------------------------------------
.sd_msg_ready
  equs "SD drive ready",0

.sd_error_ptrs
  equw sd_err_timeout
  equw sd_err_idle
  equw sd_err_ifconf
  equw sd_err_opcond

.sd_err_prefix
  equs "SD error: ",0

.sd_err_timeout
  equs "response timeout"
.sd_err_idle
  equs "failed to enter idle mode",0
.sd_err_ifconf
  equs "interface condition",0
.sd_err_opcond
  equs "operating condition",0
