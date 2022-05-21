; funcs_io.asm

\ ------------------------------------------------------------------------------
\ COMMAND INPUT PARSING
\ Inspired somewhat by keyword parsing in EhBASIC:
\ https://github.com/Klaus2m5/6502_EhBASIC_V2.22/blob/master/patched/basic.asm
\ (see line 8273 onward)
.parse_input 
  lda #CMD_TKN_FAIL         ; We'll use this as the default result
  sta FUNC_RESULT           ; 
  ldx #0                    ; Init offset counter
  lda STDIN_BUF             ; Load first char in buffer
  beq parse_cmd_nul         ; if it's a zero, the buffer is empty
  sta TEST_VAL              ; store buffer char somewhere handy
.parse_next_test
  lda cmd_ch1_tbl,X         ; get next char from table of cmd 1st chars
  cmp #EOTBL_MKR            ; is it the end of table marker?
  beq parse_1st_char_fail   ; if so, parsing has failed to find a match
  cmp TEST_VAL              ; otherwise compare against our input char
  beq parse_1st_char_match  ; if it matches, on to the next step
  inx                       ; otherwise, time to test next char in table
  jmp parse_next_test
.parse_cmd_nul
  lda #CMD_TKN_NUL
  sta FUNC_RESULT 
  jmp parse_end
.parse_1st_char_fail
  jmp parse_fail
.parse_1st_char_match
  ; At this point, X holds the offset we need to look up an address in cmd_ptrs
  ; although we need to multiply it by 2
  txa                 ; move into A
  asl A               ; shift left 1 bit to multiply by 2
  tax                 ; and put back in X
  lda cmd_ptrs,X      ; get LSB of relevant address from the cmd_ptrs table
  sta TBL_VEC_L       ; and put in TBL_VEC
  lda cmd_ptrs+1,X
  sta TBL_VEC_H
  ; We now have the start address for the relevant section of the command table
  ; in TBL_VEC and we've already matched on the first char
  ldy #0              ; offset for the command table
  ldx #1              ; offset for the input buffer, starting with 2nd char
.parse_next_chr
  lda STDIN_BUF,X   ; get next char from buffer
  sta TEST_VAL        ; and put it somewhere handy - repurposing TEST_VAL
  lda (TBL_VEC_L),Y   ; load the next test char from our command table
  bmi parse_token_found ; bit 7 will be set if this is a token - $80 or more
;  cmp #$80            ; does it have a value $80 or more?
;  bcs parse_token_found ; if >= $80, it's a token - success!
  cmp #EOCMD_SECTION  ; have we got to the end of the section without a match?
  beq parse_fail      ; if so, we've failed, time to leave
  ; At this point, we've matched neither a token nor an end of section marker.
  ; so it's time to test the buffer char itself - table char is still in A
  ; and buffer char in TEST_VAL
  cmp TEST_VAL
  bne parse_next_cmd  ; if it's not equal, this isn't the right command
  inx                 ; otherwise, if it is equal, let's test the next buffer 
  iny                 ; char against the next command char
  jmp parse_next_chr
.parse_token_found    
  ; We've mached against a command. The next char in the buffer should be a 
  ; space or a null. X already indicates this char because it was incremented
  ; above at the same time as we incremented Y to get the token byte.
  pha                 ; prserve A (which holds our token code)
  lda STDIN_BUF,X     ; get the byte from the buffer
  tay                 ; store it in Y
  pla                 ; restore A 
  cpy #$20            ; is buffer byte a space?
  beq parse_token_ok
  cpy #0              ; or is it a null?
  beq parse_token_ok
  jmp parse_fail       ; if neither of above, this is an error
.parse_token_ok
  sta FUNC_RESULT
  jmp parse_end
.parse_next_cmd
  ; previous command didn't match, so let's spin ahead to the next one.
  ; X needs to be reset; Y needs to be incremented
  ldx #1
.parse_fast_forward
  iny                     ; increment offset
  lda (TBL_VEC_L),Y       ; load next char from cmd table
  cmp #$80                ; is it a token?
  bcs parse_next_cmd_jmp  ; if so, we're nearly done
  jmp parse_fast_forward  ; otherwise, loop
.parse_next_cmd_jmp
  iny                     ; one more for luck - or to move to start of next cmd
  jmp parse_next_chr      ; now let's try again
.parse_fail
  lda #PARSE_ERR_CODE
  sta FUNC_RESULT
.parse_end
  ; Buffer pointer is still in X
  stx STDIN_IDX         ; for other routines to use for parsing rest of input
  rts
  
\ ------------------------------------------------------------------------------
\ --- DISPLAY_MEMORY
\ ------------------------------------------------------------------------------
\ ON ENTRY: Start and end addresses must be stored at TMP_ADDR_A and TMP_ADDR_B.
; We'll leave TMP_ADDR_B alone, but increment TMP_ADDR_B until the two match.
.display_memory
  LOAD_MSG memory_header
  jsr OSWRMSG
  stz TMP_COUNT                 ; Keep track how many bytes printed in each row
.display_mem_next_line
  lda TMP_ADDR_A_L              ; Load the value of the byte at addr
  sta FUNC_RES_L                ; Puts ASCII string in STR_BUF
  lda TMP_ADDR_A_H
  sta FUNC_RES_H                ; Puts ASCII string in STR_BUF
  jsr res_word_to_hex_str       ; Creates ASCII hex string starting at STR_BUF
  lda #$20                      ; Add a space
  sta STR_BUF + 4
  stz STR_BUF + 5               ; Add a null terminator
  jsr acia_prt_strbuf           ; !!! CHANGE TO OS CALL !!!
.display_mem_next_addr
  ldx #0
  lda (TMP_ADDR_A)              ; Load the value of the byte at addr
  jsr byte_to_hex_str           ; Puts ASCII string in STR_BUF
  lda STR_BUF                   ; Transferring STR_BUF to UART buffer
  sta STDOUT_BUF,X              ;     "           "     "   "
  inx                           ;     "           "     "   "
  lda STR_BUF+1                 ;     "           "     "   "
  sta STDOUT_BUF,X              ;     "           "     "   "
  inx                           ;     "           "     "   "
  lda #$20                      ; Followed by a space
  sta STDOUT_BUF,X
  inx
  stz STDOUT_BUF,X              ; Followed by null terminator
  jsr OSWRBUF
  inc TMP_COUNT
  lda TMP_COUNT
  cmp #$10                      ; Have we got to 16?
  beq display_mem_endline
  jmp display_mem_chk_MSB
.display_mem_endline            ; Start a new line of output
  lda #CHR_LINEEND
  jsr OSWRCH
  stz TMP_COUNT                 ; Reset to 0 for next line
.display_mem_chk_MSB
  lda TMP_ADDR_A_H              ; Compare the MSBs of the addresses
  cmp TMP_ADDR_B_H
  beq display_mem_chk_LSB       ; If equal, go on to check LSBs
  jmp display_mem_inc_LSB       ; Otherwise, go get the next byte from memory
.display_mem_chk_LSB
  lda TMP_ADDR_A_L              ; Compare the LSBs
  cmp TMP_ADDR_B_L
  beq display_mem_output_end    ; If they're also equal, we're done
.display_mem_inc_LSB
  inc TMP_ADDR_A_L              ; Increment LSB of start address
  lda TMP_ADDR_A_L
  cmp #$00                      ; Has it rolled over?
  bne display_mem_loopback      ; If not, go get next byte
  inc TMP_ADDR_A_H              ; If it has rolled over, increment MSB
.display_mem_loopback
  lda TMP_COUNT
  cmp #$00
  beq display_mem_next_line
  jmp display_mem_next_addr
.display_mem_output_end
  lda #CHR_LINEEND
  jsr OSWRCH
  jmp display_mem_end
.display_mem_end
  rts

\ ------------------------------------------------------------------------------
\ ---  READ_FILENAME
\ ---  Implements: OSRDFNAME
\ ------------------------------------------------------------------------------
\ This function reads characters from STDIN_BUF and stores them in STR_BUF.
\ It assumes that X contains an offset pointer to the part of STDIN_BUF from 
\ which we want to read next.
\ ON ENTRY: Nul-terminated filename string expected in STDIN_BUF
\ ON EXIT : - Nul-terminated filename in STR_BUF
\           - Error in FUNC_ERR
.read_filename
  pha : phy
  stz FUNC_ERR              ; Initialise to 0
  ldy #0                    ; Offset for where we're storing each byte
.read_filename_next_char
  lda STDIN_BUF,X           ; Get next byte from buffer
  beq read_filename_check   ; If a null (0), at end of input
  cmp #CHR_SPACE            ; If it's a space, ignore it & get next byte
  beq read_filename_loop
  cmp #CHR_LINEEND
  beq read_filename_loop
  cmp #'A'                  ; Acceptable values are 65-90 (A-Z)
  bcc read_filename_fail
  cmp #'Z'+1
  bcs read_filename_fail
  sta STR_BUF,Y             ; Store in STR_BUF buffer
  iny                       ; Increment STR_BUF index
.read_filename_loop
  inx                       ; Increment input buffer index
  jmp read_filename_next_char
.read_filename_fail
  lda #FN_CHAR_ERR_CODE
  sta FUNC_ERR
  jmp read_filename_end
.read_filename_check  ;
  sta STR_BUF,Y             ; Make sure we have a null terminator
  sty BARLED_DAT
  cpy #ZD_MIN_FN_LEN        ; Minimum filename length
  bcc read_filename_err
  cpy #ZD_MAX_FN_LEN+1      ; Maximum filename length
  bcc read_filename_end
.read_filename_err
  lda #FN_LEN_ERR_CODE
  sta FUNC_ERR
.read_filename_end
  ply : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  READ_HEX_ADDR
\ ---  Implements: OSRDHADDR
\ ------------------------------------------------------------------------------
\ This function reads four characters from the serial input and converts them to
\ a 16-bit address.
\ ON ENTRY: Expects four hex characters in STDIN_BUF, plus null terminator.
\ ON EXIT : 16-bit value in FUNC_RES_L/FUNC_RES_H.
.read_hex_addr
  pha : phy
  ldy #1                    ; Offset for where we're storing each byte from buf
.read_hex_addr_next_byte
  jsr read_hex_byte         ; Byte value result is in FUNC_RESULT
  lda FUNC_RESULT           ; Load the result from the conversion
  sta FUNC_RES_L,Y
  cpy #0
  beq read_hex_addr_end
  dey
  jmp read_hex_addr_next_byte
.read_hex_addr_end
  ply : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  READ_HEX_BYTE
\ ---  Implements: OSRDHBYTE
\ ------------------------------------------------------------------------------
\ Reads a pair of ASCII hex chars from the serial buffer and converts to
\ a byte value.
\ ON ENTRY: - Expects a pair of ASCII hex chars in the serial buffer.
\           - Also assumes that X contains an offset pointer to the part of 
\             STDIN_BUF from which we want to read next.
\ ON EXIT : - Value in FUNC_RESULT
\           - Error in FUNC_ERR
.read_hex_byte
  pha : phy
  stz FUNC_ERR              ; Initialise to 0
  ldy #1                    ; Offset for where we're storing each byte from buf
.read_hexbyte_next_char
  lda STDIN_BUF,X           ; Get next byte from buffer
  inx                       ; Increment for next time
  cmp #0                    ; Is the buffer char a null? Shouldn't be
  beq read_hexbyte_fail     ; - that's an error
  cmp #CHR_SPACE            ; If it's a space, ignore it & get next byte
  beq read_hexbyte_next_char
  sta BYTE_CONV_L,Y         ; Store in BYTE_CONV buffer, high byte first
  cpy #0                    
  beq read_hexbyte_conv     ; If 0, we've now got the second of the 2 bytes
  dey                       ; Otherwise go get low byte
  jmp read_hexbyte_next_char
.read_hexbyte_conv
  ; We've got our pair of bytes in BYTE_CONV_L and BYTE_CONV_L+1
  jsr hex_str_to_byte       ; Convert them - result is in FUNC_RESULT
  lda #0                    ; Check to see if there was an error
  cmp FUNC_ERR
  bne read_hexbyte_fail
  jmp read_hexbyte_end
.read_hexbyte_fail
  lda #READ_HEXBYTE_ERR_CODE
  sta FUNC_ERR  
.read_hexbyte_end
  ply : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  OS_PRINT_ERROR
\ ---  Implements: OSWRERR
\ ------------------------------------------------------------------------------
\ ON ENTRY: An error code is assumed to be in FUNC_ERR
.os_print_error
  lda FUNC_ERR
  dec A                   ; To get offset for table
  asl A                   ; Shift left to multiply by 2
  tax                     ; Move to X to use as offset
  lda err_ptrs,X          ; Get LSB of relevant address from the cmd_ptrs table
  sta MSG_VEC             ; and put in MSG_VEC
  lda err_ptrs+1,X        ; Get MSB
  sta MSG_VEC+1           ; and put in MSG_VEC high byte
  jsr OSWRMSG
  LED_ON LED_ERR
  rts
