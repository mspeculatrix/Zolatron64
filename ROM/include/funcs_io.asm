; funcs_io.asm

; ------------------------------------------------------------------------------
; COMMAND INPUT PARSING
; Inspired by keyword parsing in EhBASIC:
; https://github.com/Klaus2m5/6502_EhBASIC_V2.22/blob/master/patched/basic.asm
; (see line 8273 onward)
.parse_input 
  lda #CMD_TKN_FAIL         ; we'll use this as the default result
  sta FUNC_RESULT           ; 
  ldx #0                    ; init offset counter
  lda UART_RX_BUF           ; load first char in buffer
  cmp #0                    ; if it's a zero, the buffer is empty
  beq parse_cmd_nul
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
  ; at this point, X holds the offset we need to look up an address in cmd_ptrs
  ; although we need to multiply it by 2
  txa                 ; move into A
  asl A               ; shift left 1 bit to multiply by 2
  tax                 ; and put back in X
  lda cmd_ptrs,X      ; get LSB of relevant address from the cmd_ptrs table
  sta TBL_VEC_L       ; and put in TBL_VEC
  lda cmd_ptrs+1,X
  sta TBL_VEC_H
  ; we now have the start address for the relevant section of the command table
  ; in TBL_VEC and we've already matched on the first char
  ldy #0              ; offset for the command table
  ldx #1              ; offset for the input buffer, starting with 2nd char
.parse_next_chr
  lda UART_RX_BUF,X   ; get next char from buffer
  sta TEST_VAL        ; and put it somewhere handy - repurposing TEST_VAL
  lda (TBL_VEC_L),Y   ; load the next test char from our command table
  bmi parse_token_found ; bit 7 will be set if this is a token - $80 or more
;  cmp #$80            ; does it have a value $80 or more?
;  bcs parse_token_found ; if >= $80, it's a token - success!
  cmp #EOCMD_SECTION  ; have we got to the end of the section without a match?
  beq parse_fail      ; if so, we've failed, time to leave
  ; at this point, we've matched neither a token nor an end of section marker.
  ; so it's time to test the buffer char itself - table char is still in A
  ; and buffer char in TEST_VAL
  cmp TEST_VAL
  bne parse_next_cmd  ; if it's not equal, this isn't the right command
  inx                 ; otherwise, if it is equal, let's test the next buffer 
  iny                 ; char against the next command char
  jmp parse_next_chr
.parse_token_found    
  ; we've mached against a command. The next char in the buffer should be a 
  ; space or a null. X already indicates this char because it was incremented
  ; above at the same time as we incremented Y to get the token byte.
  pha                 ; prserve A (which holds our token code)
  lda UART_RX_BUF,X   ; get the byte from the buffer
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
  ; buffer pointer is still in X
  stx UART_RX_IDX         ; for other routines to use for parsing rest of input
  rts
  
; ------------------------------------------------------------------------------
; --- DISPLAY MEMORY                                                         ---
; ------------------------------------------------------------------------------
; The start and end addresses must be stored at TMP_ADDR_A and TMP_ADDR_B.
; We'll leave TMP_ADDR_B alone, but increment TMP_ADDR_B until the two match.
.display_memory

; --- TEMP ROUTINE : print reversed (little-endian) numbers to serial ----------
ldy #0
.cmdprcLM_tmp
  lda TMP_ADDR_A,Y 
  jsr byte_to_hex_str        ; string version now in STR_BUF
  lda #<STR_BUF              ; LSB of message
  sta MSG_VEC
  lda #>STR_BUF              ; MSB of message
  sta MSG_VEC+1
  jsr serial_send_msg
  lda #$20  
  jsr serial_send_char
  cpy #3
  beq cmdprcLM_tmp_end
  iny
  jmp cmdprcLM_tmp
.cmdprcLM_tmp_end
  lda #CHR_LINEEND
  jsr serial_send_char
; --- END OF TEMP SECTION ------------------------------------------------------

  lda #<memory_header              ; LSB of message
  sta MSG_VEC
  lda #>memory_header              ; MSB of message
  sta MSG_VEC+1
  jsr serial_send_msg
  stz TMP_COUNT                 ; keep track how many bytes printed in each row
.display_mem_next_line
  lda TMP_ADDR_A_L             ; load the value of the byte at addr
  sta FUNC_RES_L           ; puts ASCII string in STR_BUF
  lda TMP_ADDR_A_H
  sta FUNC_RES_H           ; puts ASCII string in STR_BUF
  jsr res_word_to_hex_str ; creates ASCII hex string starting at STR_BUF
  lda #$20
  sta STR_BUF + 4
  stz STR_BUF + 5
  jsr serial_send_str_buf
.display_mem_next_addr
  ldx #0
  lda (TMP_ADDR_A)              ; load the value of the byte at addr
  jsr byte_to_hex_str           ; puts ASCII string in STR_BUF
  lda STR_BUF                   ; transferring STR_BUF to UART buffer
  sta UART_TX_BUF,X             ;     "           "     "   "
  inx                           ;     "           "     "   "
  lda STR_BUF+1                 ;     "           "     "   "
  sta UART_TX_BUF,X             ;     "           "     "   "
  inx                           ;     "           "     "   "
  lda #$20                      ; followed by a space
  sta UART_TX_BUF,X
  inx
  stz UART_TX_BUF,X             ; followed by null terminator
  jsr serial_send_buffer
  inc TMP_COUNT
  lda TMP_COUNT
  cmp #$10                      ; have we got to 16?
  beq display_mem_endline
  jmp display_mem_chk_MSB
.display_mem_endline      ; start a new line of output
  lda #CHR_LINEEND
  jsr serial_send_char
  stz TMP_COUNT                 ; reset to 0 for next line
.display_mem_chk_MSB
  lda TMP_ADDR_A_H              ; compare the MSBs of the addresses
  cmp TMP_ADDR_B_H
  beq display_mem_chk_LSB          ; if equal, go on to check LSBs
  jmp display_mem_inc_LSB          ; otherwise, go get the next byte from memory
.display_mem_chk_LSB
  lda TMP_ADDR_A_L              ; compare the LSBs
  cmp TMP_ADDR_B_L
  beq display_mem_output_end       ; if they're also equal, we're done
.display_mem_inc_LSB
  inc TMP_ADDR_A_L              ; increment LSB of start address
  lda TMP_ADDR_A_L
  cmp #$00                      ; has it rolled over?
  bne display_mem_loopback     ; if not, go get next byte
  inc TMP_ADDR_A_H              ; if it has rolled over, increment MSB
.display_mem_loopback
  lda TMP_COUNT
  cmp #$00
  beq display_mem_next_line
  jmp display_mem_next_addr
.display_mem_output_end
  lda #CHR_LINEEND
  jsr serial_send_char
  jmp display_mem_end
.display_mem_end
  rts

; ------------------------------------------------------------------------------
; ---  READ HEX ADDRESS                                                      ---
; ------------------------------------------------------------------------------
; This function reads four characters from the serial input and converts them to
; a 16-bit address, stored LSB first, in FUNC_RES_L/FUNC_RES_H.
; USES: FUNC_RES, FUNC_RES_L, FUNC_RES_H
.read_hex_addr
  pha : phy
  ldy #1                    ; offset for where we're storing each byte from buf
.read_hex_addr_next_byte
  jsr read_hex_byte         ; byte value result is in FUNC_RES
  lda FUNC_RESULT           ; load the result from the previous conversion
  sta FUNC_RES_L,Y
  cpy #0
  beq read_hex_addr_end
  dey
  jmp read_hex_addr_next_byte
.read_hex_addr_end
  ply : pla
  rts

; ------------------------------------------------------------------------------
; ---  READ HEX BYTE                                                         ---
; ------------------------------------------------------------------------------
; Reads a pair of ASCII hex chars from the serial buffer and converts to
; a byte value. Returns result in FUNC_RESULT.
; This function assumes that UART_RX_IDX contains an offset pointer to the part 
; of UART_RX_BUF from which we want to read next.
.read_hex_byte
  pha : phy
  ldy #1                    ; offset for where we're storing each byte from buf
.read_hexbyte_next_char
  lda UART_RX_BUF,X         ; get next byte from serial buffer
  inx                       ; increment for next time
  cmp #0                    ; is the buffer char a null? Shouldn't be
  beq read_hexbyte_fail     ; - that's an error
  cmp #CHR_SPACE            ; if it's a space, ignore it & get next byte
  beq read_hexbyte_next_char
  sta BYTE_CONV_L,Y         ; store in BYTE_CONV buffer, high byte first
  cpy #0                    
  beq read_hexbyte_conv     ; if 0, we've now got the second of the 2 bytes
  dey                       ; otherwise go get low byte
  jmp read_hexbyte_next_char
.read_hexbyte_conv
  ; we've got our pair of bytes in BYTE_CONV_L and BYTE_CONV_L+1
  jsr hex_str_to_byte       ; convert them - result is in FUNC_RESULT
  lda #$00                  ; check to see if there was an error
  cmp FUNC_ERR
  bne read_hexbyte_fail
  jmp read_hexbyte_end
.read_hexbyte_fail
  lda #READ_HEXBYTE_ERR_CODE
  sta FUNC_ERR  
.read_hexbyte_end
  ply : pla
  rts

.print_error
; The error code is assumed to be in FUNC_ERR.
  lda FUNC_ERR
  dec A             ; to get offset for table
  asl A             ; shift left to multiply by 2
  tax               ; move to X to use as offset
  lda err_ptrs,X    ; get LSB of relevant address from the cmd_ptrs table
  sta MSG_VEC       ; and put in MSG_VEC
  lda err_ptrs+1,X  ; get MSB
  sta MSG_VEC+1
  jsr serial_send_msg
  rts
