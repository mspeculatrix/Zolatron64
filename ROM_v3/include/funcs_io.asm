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
\ Display the contents of memory
\ ON ENTRY: Start and end addresses must be in TMP_ADDR_A and TMP_ADDR_B.
; We'll leave TMP_ADDR_B alone, but increment TMP_ADDR_B until the two match.
.display_memory
  LOAD_MSG memory_header
  jsr OSWRMSG
  stz TMP_COUNT                 ; Keep track how many bytes printed in each row
.display_mem_next_line
  jsr uint16_to_hex_str         ; Creates ASCII hex string starting at STR_BUF
  lda #$20                      ; Add a space
  sta STR_BUF + 4
  stz STR_BUF + 5               ; Add a null terminator
  jsr OSWRSBUF
.display_mem_next_addr
  ldx #0
  lda (TMP_ADDR_A)              ; Load the value of the byte at addr
  jsr byte_to_hex_str           ; Puts ASCII string in STR_BUF
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH
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
  bne display_mem_loopback      ; Has it rolled over? If not, go get next byte
  inc TMP_ADDR_A_H              ; If it has rolled over, increment MSB
.display_mem_loopback
  lda TMP_COUNT
  beq display_mem_next_line
  jmp display_mem_next_addr
.display_mem_output_end
  lda #CHR_LINEEND
  jsr OSWRCH
  jmp display_mem_end
.display_mem_end
  rts

\ ------------------------------------------------------------------------------
\ ---  READ_CHAR
\ ---  Implements: OSRDCH
\ ------------------------------------------------------------------------------
\ Get the next non-space character from STDIN_BUF. This doesn't remove anything
\ from the buffer, but it does update the pointer STDIN_IDX to the next char.
\ ON ENTRY: - Assumes there is something in STDIN_BUF
\           - Reads the char pointed to by STDIN_IDX
\ ON EXIT : - Character code is in FUNC_RESULT
\           - Error code in FUNC_ERR
.read_char
  stz FUNC_RESULT
  stz FUNC_ERR
  ldx STDIN_IDX
.read_char_next
  lda STDIN_BUF,X
  sta FUNC_RESULT
  beq read_char_EOB             ; A 0 means end of buffered text
  cmp #' '                      ; Is it a space?
  bne read_char_store           ; If so, try again...
  inx
  jmp read_char_next
.read_char_store
  inx                           ; For next time
  stx STDIN_IDX
  sta FUNC_RESULT
  jmp read_char_end
.read_char_EOB
  stz STDIN_IDX
  lda #ERR_EOB
  sta FUNC_ERR
.read_char_end
  rts

\ ------------------------------------------------------------------------------
\ ---  READ_INT16
\ ---  Implements: OSRDINT16
\ ------------------------------------------------------------------------------
\ Read a decimal integer from STDIN_BUF. Input number is terminated by nul (0)
\ or a space.
\ ON ENTRY: - Expects input in STDIN_BUF.
\           - Assumes STDIN_IDX points to next byte to be read from STDIN_BUF.
\ ON EXIT : - 16-bit number in FUNC_RES_L/H
\           - Error in FUNC_ERR
.read_int16
  pha : phx : phy
  stz FUNC_ERR
  stz FUNC_RES_L
  stz FUNC_RES_H
  stz MATH_TMP16
  stz MATH_TMP16 + 1
  stz TMP_VAL                 ; Flag for whether we've started reading a number
  ldx STDIN_IDX               ; Offset for STDIN_BUF
.read_int_char
  txa                         ; Transfer a copy of the X offset to Y
  tay                         ; "
  iny                         ; Make Y an index to the char _after_ this one
  lda STDIN_BUF,X
  beq read_int_done           ; If it's a 0 terminator, we're done
  cmp #CHR_LINEEND
  beq read_int_done           ; If it's a line end, we're also done
  cmp #' '
  beq read_int_chkspc         ; If space, have we already started reading num?
  cmp #'0'
  bcc read_int_error          ; Less than '0' - an error
  cmp #':'                    ; Char above '9'
  bcs read_int_error          ; More than '9' - an error
  sec
  sbc #$30                    ; Turn ASCII value into integer digit
  clc                         ; Now got the value of the digit in A
  adc MATH_TMP16              ; Add this value to our result
  sta MATH_TMP16
  bcs read_int_carry          ; Did we carry?
  jmp read_int_mult
.read_int_chkspc              ; We've read a space
  lda TMP_VAL                 ; If TMP_VAL is 0, that means we haven't started
  beq read_int_next           ; reading the number yet, so go around again...
  jmp read_int_done           ; Otherwise, we're done
.read_int_carry
  inc MATH_TMP16 + 1
.read_int_mult                ; Check if we need to multiply value by 10
  inc TMP_VAL                 ; First, flag that we've got a number
  lda STDIN_BUF,Y             ; Look ahead to next char
  beq read_int_done           ; If a zero, the current one is the last digit
  cmp #' '
  beq read_int_done           ; If a space, the current one is the last digit
  cmp #'0'
  bcc read_int_error          ; Less than '0' - an error
  cmp #$3A                    ; ASCII for ':', char above '9'
  bcs read_int_error          ; More than '9' - an error
  jsr uint16_times10          ; Otherwise, multiply the current sum by 10
.read_int_next                ; Get the next digit
  inx
  jmp read_int_char
.read_int_error
  lda #ERR_NAN
  sta FUNC_ERR
  jmp read_int_end
.read_int_done
  lda MATH_TMP16
  sta FUNC_RES_L
  lda MATH_TMP16 + 1
  sta FUNC_RES_H
.read_int_end
  inx
  stx STDIN_IDX
  ply : plx : pla
  rts

\ ------------------------------------------------------------------------------
\ ---  READ_FILENAME
\ ---  Implements: OSRDFNAME
\ COULD BE RENAMED TO READ_STRING AS A MORE GENERAL-PURPOSE ROUTINE - OSRDSTR
\ Keep READ_FILENAME AS A WRAPPER
\ WOULD NEED TO UPGRADE TO ACCEPT NUMBERS (and maybe lowercase)
\ ------------------------------------------------------------------------------
\ This function reads characters from STDIN_BUF and stores them in STR_BUF.
\ It assumes that STDIN_IDX contains an offset pointer to the part of STDIN_BUF
\ from which we want to read next.
\ ON ENTRY: Nul- or space- terminated filename string expected in STDIN_BUF
\ ON EXIT : - Nul-terminated filename in STR_BUF
\           - Error in FUNC_ERR
\           - STDIN_IDX updated
.read_filename
  pha : phx : phy
  stz FUNC_ERR              ; Initialise to 0
  ldy #0                    ; Offset for where we're storing each byte
  ldx STDIN_IDX
.read_filename_next_char
  lda STDIN_BUF,X           ; Get next byte from buffer
  beq read_filename_check   ; If a null (0), at end of input
  cmp #CHR_LINEEND          ; If a line end, we're done.
  beq read_filename_check
  cmp #CHR_SPACE            ; If it's a space, check if we should ignore it
  beq read_filename_chkspc
  ; If we're not at or near the beginning of the filename, numbers and certain
  ; special chars are allowed
  cpy #ZD_MIN_FN_LEN          ; If our char count Y is less than the minimum
  bcc read_filename_chk_alpha ; filename length, only alpha chars are allowed
  cmp #'.'                    ; Check for special, allowed chars
  beq read_filename_store     ; Period is okay
  cmp #'0'
  bcc read_filename_fail      ; Not special char but also less than '0' - fail
  cmp #'9'+1
  bcs read_filename_chk_alpha ; More than 0 and also =>'9'+1, check alpha
  jmp read_filename_store     ; Otherwise it's a number, so okay
.read_filename_chk_alpha
  and #$DF                    ; Convert lower to uppercase. Uppercase unaffected
  cmp #'A'                    ; Acceptable values are 65-90 (A-Z)
  bcc read_filename_fail
  cmp #'Z'+1
  bcs read_filename_fail
.read_filename_store
  sta STR_BUF,Y               ; Store in STR_BUF buffer
  iny                         ; Increment STR_BUF index for next time
.read_filename_loop
  inx                         ; Increment input buffer index
  jmp read_filename_next_char ; Go get next char
.read_filename_chkspc
  cpy #0
  beq read_filename_loop      ; 0, so not started receiving chars, ignore space
  jmp read_filename_check     ; Otherwise, we're done
.read_filename_fail
  lda #FN_CHAR_ERR_CODE
  sta FUNC_ERR
  jmp read_filename_end
.read_filename_check  ;
  lda #0
  sta STR_BUF,Y               ; Make sure we have a null terminator
  cpy #ZD_MIN_FN_LEN          ; Minimum filename length
  bcc read_filename_err
  cpy #ZD_MAX_FN_LEN+1        ; Maximum filename length
  bcc read_filename_end
.read_filename_err
  lda #FN_LEN_ERR_CODE
  sta FUNC_ERR
.read_filename_end
  stx STDIN_IDX
  ply : plx : pla
  rts

\ Maybe use another address location for storing a parameter which will be
\ the maximum string length.
.read_string          ; **** WORK IN PROGRESS ****
  pha : phx : phy
  stz FUNC_ERR              ; Initialise to 0
  ldy #0                    ; Offset for where we're storing each byte
  ldx STDIN_IDX
  stz TMP_VAL               ; Flag regarding whether we've already read chars
.read_string_next_char
  lda STDIN_BUF,X           ; Get next byte from buffer
  beq read_string_check     ; If a null (0), at end of input
  cmp #CHR_SPACE            ; If it's a space, ignore it & get next byte
  beq read_string_chkspc
  cmp #CHR_LINEEND          ; If LF, end of input.
  beq read_string_check
  \ Acceptable char ranges:
  \     -./0-9:
  \     @A-Z
  \     a-z
  cmp #'-'
  bcc read_string_fail      ; A is less than lowest acceptable char
  cmp #':'+1
  bcc read_string_charOK    ; A less than top of first range, so okay
  cmp #'@'
  bcc read_string_fail      ; More than first range but less than second. Fail
  cmp #'Z'+1
  bcc read_string_charOK    ; Falls within second range
  cmp #'a'
  bcc read_string_fail      ; More than second range but less than third. Fail
  cmp #'z'+1
  bcs read_string_fail      ; Within third range, so okay
.read_string_charOK
  sta STR_BUF,Y             ; Store in STR_BUF buffer
  iny                       ; Increment STR_BUF index
  inc TMP_VAL
.read_string_loop
  inx                       ; Increment input buffer index
  jmp read_string_next_char
.read_string_chkspc
  lda TMP_VAL
  beq read_string_loop      ; 0, so not started receiving chars yet
  jmp read_string_check     ; Otherwise, we're done
.read_string_fail
  lda #FN_CHAR_ERR_CODE
  sta FUNC_ERR
  jmp read_string_end
.read_string_check  ;
  sta STR_BUF,Y             ; Make sure we have a null terminator
  cpy #ZD_MIN_FN_LEN        ; Minimum filename length
  bcc read_string_err
  cpy #ZD_MAX_FN_LEN+1      ; Maximum filename length
  bcc read_string_end
.read_string_err
  lda #FN_LEN_ERR_CODE
  sta FUNC_ERR
.read_string_end
  stx STDIN_IDX
  ply : plx : pla
  rts


\ ------------------------------------------------------------------------------
\ ---  READ_HEX_ADDR
\ ---  Implements: OSRDHADDR
\ ------------------------------------------------------------------------------
\ This function reads four characters from the serial input and converts them to
\ a 16-bit address.
\ ON ENTRY: Expects four hex characters in STDIN_BUF, plus null terminator or
\           space.
\ ON EXIT : - 16-bit value in FUNC_RES_L/FUNC_RES_H.
\           - FUNC_ERR contains error code.
.read_hex_addr
  pha : phy
  ldy #1                    ; Offset for where we're storing each byte from buf
.read_hex_addr_next_byte
  jsr read_hex_byte         ; Byte value result is in FUNC_RESULT
  lda FUNC_ERR
  bne read_hex_addr_end
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
\ ---  READ_HEX_ADDR_PAIR
\ ------------------------------------------------------------------------------
\ This function reads two four-character hex addresses from STDIN_BUF.
\ ON ENTRY: Expects two four-char hex characters in STDIN_BUF, plus null
\           terminator or space.
\ ON EXIT : - Two 16-bit addresses in TMP_ADDR_A and TMP_ADDR_B.
\           - FUNC_ERR contains error code.
.read_hex_addr_pair
  ldy #0
.read_hex_addr_pair_next        ; Get next address from buffer
  jsr read_hex_addr             ; Puts bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne read_hex_addr_pair_end
  lda FUNC_RES_L
  sta TMP_ADDR_A,Y
  iny                           ; Increment Y to store the high byte
  lda FUNC_RES_H
  sta TMP_ADDR_A,Y
  cpy #3                        ; If 3, then we've got all four bytes
  beq read_hex_addr_pair_end
  iny                           ; Otherwise, get next byte
  jmp read_hex_addr_pair_next
.read_hex_addr_pair_end
  rts

\ ------------------------------------------------------------------------------
\ ---  READ_HEX_BYTE
\ ---  Implements: OSRDHBYTE
\ ------------------------------------------------------------------------------
\ Reads a pair of ASCII hex chars from the serial buffer and converts to
\ a byte value.
\ ON ENTRY: - Expects a pair of ASCII hex chars in the serial buffer.
\           - Also assumes that STDIN_IDX contains an offset pointer to the part
\             of STDIN_BUF from which we want to read next.
\ ON EXIT : - Value in FUNC_RESULT
\           - Error in FUNC_ERR
.read_hex_byte
  pha : phy
  stz FUNC_ERR              ; Initialise to 0
  ldy #1                    ; Offset for where we're storing each byte from buf
  ldx STDIN_IDX
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
  lda FUNC_ERR              ; Check to see if there was an error
  bne read_hexbyte_fail
  jmp read_hexbyte_end
.read_hexbyte_fail
  lda #READ_HEXBYTE_ERR_CODE
  sta FUNC_ERR
.read_hexbyte_end
  stx STDIN_IDX
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
  jsr OSWRMSG             ; Print to standard stream
  rts

\ ------------------------------------------------------------------------------
\ ---  STDOUT_APPEND
\ ---  Implements: OSSOAPP
\ ------------------------------------------------------------------------------
\ ON ENTRY: - Assumes index for next char is in STDOUT_IDX
\           - MSG_VEC/+1 contains pointer to text string
\ ON EXIT : - FUNC_ERR contains error code - 0 for success
.stdout_append
  phx : phy
  stz FUNC_ERR
.stdout_append_copy
  ldy #0
  ldx STDOUT_IDX
.stdout_append_copy_loop
  lda (MSG_VEC),Y
  beq stdout_append_copy_done
  sta STDOUT_BUF,X
  inx
  iny
  jmp stdout_append_copy_loop
.stdout_append_copy_done
  lda #0
  sta STDOUT_BUF,X
  stx STDOUT_IDX
  ply : plx
  rts

\ ------------------------------------------------------------------------------
\ ---  STDOUT_TO_MSG_VEC
\ ------------------------------------------------------------------------------
\ Put the start address of STDOUT_BUF into the MSG_VEC vector.
.stdout_to_msg_vec
  lda #<STDOUT_BUF
  sta MSG_VEC
  lda #>STDOUT_BUF
  sta MSG_VEC+1
  rts
\ ------------------------------------------------------------------------------
\ ---  STR_BUF_TO_MSG_VEC
\ ------------------------------------------------------------------------------
\ Put the start address of STR_BUF into the MSG_VEC vector.
.str_buf_to_msg_vec
  lda #<STR_BUF
  sta MSG_VEC
  lda #>STR_BUF
  sta MSG_VEC+1
  rts
