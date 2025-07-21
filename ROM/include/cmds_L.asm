\ ZolOS CLI Commands starting with 'L' - cmds_L.asm

\-------------------------------------------------------------------------------
\ --- CMD: LM  :  LIST MEMORY
\-------------------------------------------------------------------------------
\ Usage: LM <addr> <addr>
\ Expects two, two-byte hex addresses and prints the memory contents in that
\ range.
\ The first address must be lower than the second. The two addresses can be
\ optionally separated by a space.
\ Variables used: BYTE_CONV_L, TMP_OFFSET, TMP_COUNT, LOOP_COUNT, FUNC_RESULT
.cmdprcLM
  stz FUNC_ERR
; --- GET & CONVERT HEX VALUE PAIRS --------------------------------------------
; Get the two, 4-char addresses.
; The byte values are stored at the four locations starting at TMP_ADDR_A
; (which encompasses TMP_ADDR_A and TMP_ADDR_B).
  jsr read_hex_addr_pair
  lda FUNC_ERR
  bne cmdprcLM_addr_fail
; --- CHECK VALUES: Check that values obtained are sane ------------------------
; The four bytes defining the memory range are in the four bytes starting
; at TMP_ADDR_A. The MSB of the start address must be less than or equal to
; the MSB of the end address. If it's less than, the LSB value doesn't matter.
; If it's equal, then the LSB of the start address must be less than that of
; the end address.
.cmdprcLM_check
  jsr compare_addr
  lda FUNC_RESULT
  bne cmdprcLM_addr_fail
  jmp cmdprcLM_chk_null
.cmdprcLM_addr_fail
  lda #ERR_ADDR
  sta FUNC_ERR
  jmp cmdprc_fail
.cmdprcLM_chk_fail
  lda #SYNTAX_ERR_CODE      ; We'll return a syntax error
  sta FUNC_ERR
  jmp cmdprc_fail
.cmdprcLM_chk_null          ; Check there's nothing left in the RX buffer
  ldx STDIN_IDX
  lda STDIN_BUF,X           ; Should be null. Anything else is a mistake
  bne cmdprcLM_chk_fail
  jsr display_memory
  jmp cmdprc_success

\ ------------------------------------------------------------------------------
\ --- CMD: LOAD  :  LOAD FILE
\ ------------------------------------------------------------------------------
\ Usage: LOAD <filename>
\ This is for loading executable files in main memory.
\ The filename should not have the '.EXE' extension (this will be added
\ automatically by ZolaDOS).
.cmdprcLOAD
  LED_ON LED_FILE_ACT
  lda #<USR_START                   ; This is where we're going to put the code
  sta FILE_ADDR
  lda #>USR_START
  sta FILE_ADDR + 1
  jsr zd_getfile
  lda FUNC_ERR
  bne cmdprcLOAD_fail
  jsr zd_fileload_ok
  LED_OFF LED_FILE_ACT
  jmp cmdprc_success
.cmdprcLOAD_fail
  LED_OFF LED_FILE_ACT
  LED_ON LED_ERR
  jmp cmdprc_fail

\ ------------------------------------------------------------------------------
\ --- CMD: LP  :  LIST MEMORY PAGE
\ ------------------------------------------------------------------------------
\ Usage: LP <page>
\ Expects a two-character hex byte in the input buffer. It uses this as the
\ high byte of an address (the low byte being 00) and prints out the memory
\ contents for that page (256 bytes). EG: if you enter 'C0', it gives the
\ memory contents for the range C000-C0FF.
.cmdprcLP
  jsr read_hex_byte         ; Read 2 hex chars from input: result in FUNC_RESULT
  lda FUNC_ERR              ; Check for error
  bne cmdprcLP_fail
.cmdprcLP_chk_null          ; Check there's nothing left in the RX buffer
  ldx STDIN_IDX
  lda STDIN_BUF,X           ; Should be null. Anything else is a mistake
  bne cmdprcLP_fail
  lda FUNC_RESULT           ; Get the result from jsr read_hex_byte
  sta TMP_ADDR_A_H          ; Put the same byte in the high bytes of both
  sta TMP_ADDR_B_H          ; the start address and end address
  stz TMP_ADDR_A_L          ; The low byte of the start address is 0
  lda #$FF                  ; The low byte of the end address is $FF
  sta TMP_ADDR_B_L
  jsr display_memory        ; Use our display memory routine to display
  jmp cmdprc_success
.cmdprcLP_fail
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
  jmp cmdprc_fail

\ ------------------------------------------------------------------------------
\ --- CMD: LS  :  LIST STORAGE
\ ------------------------------------------------------------------------------
\ Usage: LS
\ Inspired by the Unix ls command. Gets a list of available files from the
\ ZolaDOS server.
.cmdprcLS
  LED_ON LED_FILE_ACT
  LOAD_MSG ls_req_msg
  jsr OSLCDMSG
  lda #ZD_OPCODE_LS           ; Start a ZolaDOS process with the code for LS
  jsr zd_init_process
  lda FUNC_ERR
  beq cmdprcLS_rcv_data       ; If result is 0, that's OK
  jmp cmdprcLS_fail             ; Otherwise, we've failed
.cmdprcLS_rcv_data            ; ----- TRANSFER DATA ----------------------------
  ZD_SET_DATADIR_INPUT
  lda #<ZD_WKSPC              ; This is where we're going to put the data
  sta FILE_ADDR               ; "
  lda #>ZD_WKSPC              ; "
  sta FILE_ADDR+1             ; "
  jsr zd_rcv_data             ; If no error, get the data from the Pi
  lda FUNC_ERR
  beq cmdprcLS_show           ; If no error, go to the bit that displays data
.cmdprcLS_err                 ; Otherwise deal with the error
  jmp cmdprcLS_fail
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
  cpy #ZD_MAX_FN_LEN + 6      ; Max filename, +4 chars for ext, +2 for neatness
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
  jmp cmdprc_success
.cmdprcLS_fail
  LED_OFF LED_FILE_ACT
  jmp cmdprc_fail

\ --- DATA ---------------------------------------------------------------------
.ls_req_msg
  equs "Requesting file list",0
