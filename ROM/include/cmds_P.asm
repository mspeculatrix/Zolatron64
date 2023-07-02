\ ZolOS CLI Commands starting with 'P' - cmds_P.asm

\ ------------------------------------------------------------------------------
\ --- CMD: PDUMP  :  HEX DUMP PROGRAM IN MEMORY TO SCREEN
\ ------------------------------------------------------------------------------
\ Usage: PDUMP

.cmdprcPDUMP
  jsr check_exec                  ; Check if executable program loaded
  lda FUNC_ERR
  bne cmdprcPDUMP_err             ; An error suggests not
	lda #<USR_START                 ; Get start address
	sta TMP_ADDR_A
  lda #>USR_START
	sta TMP_ADDR_A + 1
  ; Get end address
	lda USR_START + CODEHDR_END     ; LSB of first free byte after prog
	dec	A			                      ; Decrement to get last byte of program
	sta TMP_ADDR_B
	lda USR_START + CODEHDR_END + 1 ; MSB
	sta TMP_ADDR_B + 1
	LOAD_MSG cmdprcPDUMP_msg
 	jsr OSWRMSG
  jsr display_memory
	lda #10
	jsr OSWRCH
	jmp cmdprc_success

.cmdprcPDUMP_err
  jmp cmdprc_fail

.cmdprcPDUMP_msg
  equs "Executable program found:",10,0


\ ------------------------------------------------------------------------------
\ --- CMD: PEEK  :  EXAMINE BYTE IN MEMORY
\ ------------------------------------------------------------------------------
\ Usage: PEEK <addr>
\ Show the value of a byte at a specific address.
\ Expects a two-byte hex address as input.
.cmdprcPEEK
  jsr read_hex_addr         ; Get address - puts bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcPEEK_fail
  ldx STDIN_IDX
  lda STDIN_BUF,X           ; Check there's nothing left in the RX buffer
  bne cmdprcPEEK_fail       ; Should be null. Anything else is a mistake
  lda (FUNC_RES_L)
  jsr byte_to_hex_str       ; Resulting string is in STR_BUF
  jsr duart_snd_strbuf
  jmp cmdprc_success
.cmdprcPEEK_fail
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
  jmp cmdprc_fail

\ ------------------------------------------------------------------------------
\ --- CMD: POKE  :  SET BYTE IN MEMORY
\ ------------------------------------------------------------------------------
\ Usage: POKE <addr> <val>
\ Write a one-byte value to a specific address.
\ Expects a two-byte hex address and a one-byte hex value as input.
\ The command '!' also directs here.
.cmdprcPOKE
  jsr read_hex_addr         ; Puts address bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcPOKE_fail
  jsr read_hex_byte         ; Get byte value - puts result in FUNC_RESULT
  lda FUNC_ERR
  bne cmdprcPOKE_fail
  ldx STDIN_IDX
  lda STDIN_BUF,X           ; Check there's nothing left in the RX buffer
  bne cmdprcPOKE_fail       ; Should be null. Anything else is a mistake
  lda FUNC_RESULT           ; Store the byte in the given address
  sta (FUNC_RES_L)
  jmp cmdprc_success
.cmdprcPOKE_fail
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
  jmp cmdprc_fail

\ ------------------------------------------------------------------------------
\ --- CMD: PRT  :  PRINT A TEXT FILE
\ ------------------------------------------------------------------------------
\ Usage: PRT <filename>
\ ***** UNDER CONSTRUCTION *****
.cmdprcPRT
  jsr OSPRTCHK                ; Check the printer state
  lda FUNC_ERR
  bne cmdprcPRT_fail          ; 0 = OK, all else is an error state
  jsr read_filename           ; Puts filename in STR_BUF
  lda FUNC_ERR
  bne cmdprcPRT_fail

  lda #ZD_OPCODE_OPENR        ; Open file for readiing
  jsr zd_open_file


  jmp cmdprcPRT_success


.cmdprcPRT_fail
  jmp cmdprc_fail

.cmdprcPRT_success
  LOAD_MSG prt_success_msg
  jsr OSWRMSG
  jmp cmdprc_success

\ TEMPORARY DEBUG STUFF

.prt_success_msg
  equs "OK",10,0
