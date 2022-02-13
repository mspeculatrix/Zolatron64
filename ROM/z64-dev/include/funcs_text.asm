; FUNCTIONS: TEXT -- funcs_text.asm --------------------------------------------
; v09 - 25 Nov 2021
;

; Convert 1-byte value to 2-char hex string representation. Stores result in
; three bytes starting at STR_BUF. Third byte is a null terminator.
.byte_to_hex_str              ; assumes that byte to be converted is in A
  phx : phy
  tax                         ; keep a copy of A in X for later
  lsr A                       ; logical shift right 4 bits
  lsr A
  lsr A
  lsr A                       ; A now contains upper nibble of value
  tay                         ; put in Y to act as offset
  lda hex_chr_tbl,Y           ; load A with appropriate char from lookup table
  sta STR_BUF                 ; and stash that in the text buffer
  txa                         ; recover original value of A
  and #%00001111              ; mask to get lower nibble value
  tay                         ; again, put in Y to act as offset
  lda hex_chr_tbl,Y           ; load A with appropriate char from lookup table
  sta STR_BUF+1               ; and stash that in the next byte of the buffer
  stz STR_BUF+2               ; end with a null byte
  ply : plx
  rts
  
.hex_str_to_byte              ; assumes text is in BYTE_CONV_H and BYTE_CONV_L
  pha : phx
  stz FUNC_ERR                ; zero out function error
  stz FUNC_RESULT             ; zero-out return result
  lda BYTE_CONV_H             ; load the high nibble character
  jsr asc_hex_to_bin          ; convert to number - result is in A
  ldx #$00
  cpx FUNC_ERR
;  bne hex_str_to_byte_err
  asl A                       ; shift to high nibble
  asl A 
  asl A 
  asl A
  sta FUNC_RESULT             ; and store
  lda BYTE_CONV_L             ; get the low nibble character
  jsr asc_hex_to_bin          ; convert to number - result is in A
  ldx #$00
  cpx FUNC_ERR
  bne hex_str_to_byte_err
  ora FUNC_RESULT             ; OR with previous result
  sta FUNC_RESULT             ; and store final result
  jmp hex_str_to_byte_end
.hex_str_to_byte_err
  stz FUNC_RESULT
.hex_str_to_byte_end
  plx : pla
  rts

.asc_hex_to_bin               ; assumes ASCII char val is in A
  phx
  stz FUNC_ERR                ; zero-out error
  sec
  sbc #$30                    ; subtract $30 - this is good for 0-9
  cmp #10                     ; is value more than 10?
  bcc asc_hex_to_bin_end      ; if not, we're okay
;  sec
  sbc #$07                    ; otherwise subtract further for A-F
  cmp #16                     ; result should be less than 16
  bcc asc_hex_to_bin_end
.asc_hex_to_bin_err
  ldx #HEX_TO_BIN_ERR_CODE    ; set error code
  stx FUNC_ERR
  ; jsr serial_prt_err        ; FOR DEBUGGING ONLY
.asc_hex_to_bin_end
  plx
  rts                         ; value is returned in A

.res_word_to_hex_str          ; takes the 16-bit value in FUNC_RES_L/H and
  pha                         ; converts to a four-byte hex string stored 
  lda FUNC_RES_L              ; in STR_BUF
  jsr byte_to_hex_str
  lda STR_BUF                 ; STR_BUF contains the two chars for the low byte, 
  sta TMP_WORD_L              ; but at locations 0 & 1.
  lda STR_BUF + 1             ; Put these in temporary locations
  sta TMP_WORD_H
  lda FUNC_RES_H              ; Now process the high byte
  jsr byte_to_hex_str         ; This is now in STR_BUF
  lda TMP_WORD_L              ; Move our previous results into the appropriate
  sta STR_BUF + 2             ; locations in STR_BUF
  lda TMP_WORD_H
  sta STR_BUF + 3
  stz STR_BUF + 4             ; Null terminator
  pla
  rts

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
;  lda #CMD_TKN_NUL
  sta FUNC_RESULT 
.parse_1st_char_fail
  jmp parse_end
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
  beq parse_end       ; if so, we've failed, time to leave
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
  jmp parse_end       ; if neither of above, this is an error
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
.parse_end
  ; buffer pointer is still in X
  stx UART_RX_IDX         ; for other routines to use for parsing rest of input
  rts
  