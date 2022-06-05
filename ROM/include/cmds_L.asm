\-------------------------------------------------------------------------------
\ --- CMD: LM  :  LIST MEMORY
\-------------------------------------------------------------------------------
\ Expects two, two-byte hex addresses and prints the memory contents in that 
\ range. So the format is:
\     LM hhhh hhhh
\ The first address must be lower than the second. The two addresses can be
\ optionally separated by a space.
\ Variables used: BYTE_CONV_L, TMP_OFFSET, TMP_COUNT, LOOP_COUNT, FUNC_RESULT
.cmdprcLM
  ; X currently contains the buffer index for the rest of the text in the RX 
  ; buffer (after the command), although the first char is likely to be a space.
  stz FUNC_ERR
; --- GET & CONVERT HEX VALUE PAIRS --------------------------------------------
; Get the two, 4-char addresses.
; The byte values are stored at the four locations starting at TMP_ADDR_A
; (which encompasses TMP_ADDR_A and TMP_ADDR_B).
  ldy #0                        ; Offset from TMP_ADDR_A
.cmdprcLM_next_addr             ; Get next address from buffer
  jsr read_hex_addr             ; Puts bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcLM_rd_addr_fail
  lda FUNC_RES_L
  sta TMP_ADDR_A,Y
  iny                           ; Increment Y to store the high byte
  lda FUNC_RES_H
  sta TMP_ADDR_A,Y
  cpy #3                        ; If 3, then we've got all four bytes
  beq cmdprcLM_check
  iny                           ; Otherwise, get next byte
  jmp cmdprcLM_next_addr
.cmdprcLM_rd_addr_fail
  jmp cmdprc_fail
; --- CHECK VALUES: Check that values obtained are sane ------------------------
; The four bytes defining the memory range are in the four bytes starting
; at TMP_ADDR_A. The MSB of the start address must be less than or equal to
; the MSB of the end address. If it's less than, the LSB value doesn't matter.
; If it's equal, then the LSB of the start address must be less than that of
; the end address.
.cmdprcLM_check
  lda FUNC_ERR
  bne cmdprcLM_chk_fail
  lda TMP_ADDR_B_H          ; MSB of end address
  cmp TMP_ADDR_A_H          ; MSB of start address
  beq cmdprcLM_chk_lsb      ; They're equal, so now check LSB
  bcc cmdprcLM_chk_fail     ; Start is more than end
  jmp cmdprcLM_chk_nul
.cmdprcLM_chk_lsb
  lda TMP_ADDR_B_L          ; LSB of end address
  cmp TMP_ADDR_A_L          ; LSB of start address
  beq cmdprcLM_chk_fail     ; If equal, then both addresses are same - an error
  bcs cmdprcLM_chk_nul
.cmdprcLM_chk_fail
  lda #SYNTAX_ERR_CODE      ; We'll return a syntax error
  sta FUNC_ERR
  jmp cmdprc_fail
.cmdprcLM_chk_nul           ; Check there's nothing left in the RX buffer
  lda STDIN_BUF,X           ; Should be null. Anything else is a mistake
  bne cmdprcLM_chk_fail
  jsr display_memory
  jmp cmdprc_end

\ ------------------------------------------------------------------------------
\ --- CMD: LOAD  :  LOAD FILE
\ ------------------------------------------------------------------------------
.cmdprcLOAD
  LED_ON LED_FILE_ACT
  lda #<USR_PAGE              ; This is where we're going to put the code
  sta FILE_ADDR
  lda #>USR_PAGE
  sta FILE_ADDR + 1
  jsr read_filename           ; Puts filename in STR_BUF
  lda FUNC_ERR
  bne cmdprcLOAD_err
  jsr zd_loadfile
  lda FUNC_ERR
  bne cmdprcLOAD_err
  jmp cmdprcLOAD_success
.cmdprcLOAD_err
  LED_ON LED_ERR
  jsr os_print_error          ; There should be an error code in FUNC_ERR
  jsr OSLCDERR
  jmp cmdprcLOAD_end
.cmdprcLOAD_success
  LOAD_MSG load_complete_msg
  jsr OSLCDMSG
  jsr OSWRMSG
.cmdprcLOAD_end
  LED_OFF LED_FILE_ACT
  jmp cmdprc_end

\ ------------------------------------------------------------------------------
\ --- CMD: LP  :  LIST MEMORY PAGE
\ ------------------------------------------------------------------------------
\ Expects a two-character hex byte in the input buffer. It uses this as the
\ high byte of an address and prints out the memory contents for that page (256
\ bytes). EG: if you enter 'C0', it gives the memory contents for the range
\ C000-C0FF.
.cmdprcLP
  jsr read_hex_byte         ; Read 2 hex chars from input: result in FUNC_RESULT
  lda FUNC_ERR              ; Check for error
  bne cmdprcLP_fail
.cmdprcLP_chk_nul           ; Check there's nothing left in the RX buffer
  lda STDIN_BUF,X           ; Should be null. Anything else is a mistake
  bne cmdprcLP_input_fail
  lda FUNC_RESULT           ; Get the result from jsr read_hex_byte
  sta TMP_ADDR_A_H          ; Put the same byte in the high bytes of both
  sta TMP_ADDR_B_H          ; the start address and end address
  lda #0                    ; The low byte of the start address is 0
  sta TMP_ADDR_A_L
  lda #$FF                  ; The low byte of the end address is $FF
  sta TMP_ADDR_B_L
  jsr display_memory        ; Use our display memory routine to display
  jmp cmdprcLP_end
.cmdprcLP_input_fail
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
.cmdprcLP_fail
  jmp cmdprc_fail
.cmdprcLP_end
  jmp cmdprc_end

\ ------------------------------------------------------------------------------
\ --- CMD: LS  :  LIST STORAGE
\ ------------------------------------------------------------------------------
\ Inspired by the Unix ls command. Gets a list of available files from the
\ ZolaDOS server. The files are shown without their '.BIN' suffixes because,
\ when loading, we only use the main part of the filename with the LOAD command.
.cmdprcLS
  LED_ON LED_FILE_ACT
  lda #ZD_OPCODE_LS           ; Start a ZolaDOS process with the code for LS
  jsr zd_init_process
  lda FUNC_ERR
  beq cmdprcLS_rcv_data       ; If result is 0, that's OK
  jmp cmdprc_fail
.cmdprcLS_rcv_data            ; ----- TRANSFER DATA ----------------------------
  ZD_SET_DATADIR_INPUT
  lda #<ZD_WKSPC              ; This is where we're going to put the data
  sta TMP_ADDR_A_L            ; "
  lda #>ZD_WKSPC              ; "
  sta TMP_ADDR_A_H            ; "
;  jsr zd_waitForSAoff         ; Wait for /SA signal to go high. This times out
;  lda FUNC_ERR                ; sometimes, so might want a longer wait here
;  bne cmdprcLS_err
  jsr zd_rcv_data             ; If no error, get the data from the Pi
  lda FUNC_ERR
  beq cmdprcLS_show           ; If no error, go to the bit that displays data
.cmdprcLS_err                 ; Otherwise deal with the error
  LED_ON LED_ERR
  jmp cmdprc_fail
.cmdprcLS_show
  ldx #0                      ; Counter for number of FNs per line
  ldy #0                      ; Counter for number chars per filename
  lda #<ZD_WKSPC              ; Reset vector to where data is stored
  sta TMP_ADDR_A_L            ; "
  lda #>ZD_WKSPC              ; "
  sta TMP_ADDR_A_H            ; "
.cmdprcLS_show_loop
  lda (TMP_ADDR_A)            ; Get char from workspace
  beq cmdprcLS_show_pad       ; If it's a 0 terminator, pad out the name
  cmp #ZD_FILELIST_TERM       ; If it's 255, we're done.
  beq cmdprcLS_end            ; "
  jsr OSWRCH                  ; Otherwise, print char
  iny                         ; Increament filename char counter
.cmdprcLS_show_loopback                   ; Set up for next filename
  inc TMP_ADDR_A_L                        ; Increment address
  bne cmdprcLS_show_loopback_contd        ; If hasn't rolled over, continue
  inc TMP_ADDR_A_H                        ; Otherwise increment high byte
.cmdprcLS_show_loopback_contd
  jmp cmdprcLS_show_loop      ; Go around again
.cmdprcLS_show_pad
  inx                         ; At the end of a name, so increment file count
  cpx #ZD_FILES_PER_LINE      ; Are we also at the end of a line?
  bne cmdprcLS_show_pad_next  ; If not at max, go to next step
  lda #CHR_LINEEND            ; Print a linefeed
  jsr OSWRCH                  ; "
  ldx #0                      ; Reset counters
  ldy #0                      ; "
  jmp cmdprcLS_show_loopback  ; Go on to next filename
.cmdprcLS_show_pad_next
  cpy #ZD_MAX_FN_LEN + 2      ; Length of filename plus two spaces for neatness
  beq cmdprcLS_show_pad_end   ; If we're at max width, skip to next step
  lda #' '                    ; Otherwise, print a space
  jsr OSWRCH                  ; "
  iny                         ; And increment filename char counter
  jmp cmdprcLS_show_pad_next
.cmdprcLS_show_pad_end
  ldy #0                      ; Reset filename char counter
  jmp cmdprcLS_show_loopback  ; On to next filename
.cmdprcLS_end
  ZD_SET_DATADIR_OUTPUT
  LED_OFF LED_FILE_ACT
  jmp cmdprc_end
