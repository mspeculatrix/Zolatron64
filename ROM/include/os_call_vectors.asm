\ ----- SETUP OS CALL VECTORS --------------------------------------------------
\ This is where we assign a function to each vector (or vice versa if you
\ prefer). Basically, we write the address of each function into the vector
\ locations.
\ The order in which things appear isn't critical here, but it makes sense
\ to have then in the same order as the other elements of the os calls, which
\ you'll find in:
\    - z64-main.asm   - OS Call Jump Table
\    - cfg_page_2.asm - set up locations of call vectors
\    - cfg_main.asm   - OS Function Address Table

\ --- READ ---------------------------------------------------------------------
  lda #<getkey                        ; OSRDASC
  sta OSGETKEY_VEC
  lda #>getkey
  sta OSGETKEY_VEC + 1
  lda #<read_ascii                    ; OSRDASC
  sta OSRDASC_VEC
  lda #>read_ascii
  sta OSRDASC_VEC + 1
  lda #<read_byte                     ; OSRDBYTE
  sta OSRDBYTE_VEC
  lda #>read_byte
  sta OSRDBYTE_VEC + 1
  lda #<read_char                     ; OSRDCH
  sta OSRDCH_VEC
  lda #>read_char
  sta OSRDCH_VEC + 1
  lda #<read_hex_byte                 ; OSRDHBYTE
  sta OSRDHBYTE_VEC
  lda #>read_hex_byte
  sta OSRDHBYTE_VEC + 1
  lda #<read_hex_addr                 ; OSRDHADDR
  sta OSRDHADDR_VEC
  lda #>read_hex_addr
  sta OSRDHADDR_VEC + 1
  lda #<read_int16                    ; OSRDINT16
  sta OSRDINT16_VEC
  lda #>read_int16
  sta OSRDINT16_VEC + 1
  lda #<read_filename                 ; OSRDFNAME
  sta OSRDFNAME_VEC
  lda #>read_filename
  sta OSRDFNAME_VEC + 1
  lda #<read_string                   ; OSRDSTR
  sta OSRDSTR_VEC
  lda #>read_string
  sta OSRDSTR_VEC + 1
\ --- WRITE --------------------------------------------------------------------
  lda #<duart_sendbuf                 ; OSWRBUF
  sta OSWRBUF_VEC
  lda #>duart_sendbuf
  sta OSWRBUF_VEC + 1
  lda #<duart_sendchar                ; OSWRCH
  sta OSWRCH_VEC
  lda #>duart_sendchar
  sta OSWRCH_VEC + 1
  lda #<os_print_error                ; OSWRERR
  sta OSWRERR_VEC
  lda #>os_print_error
  sta OSWRERR_VEC + 1
  lda #<duart_println                 ; OSWRMSG
  sta OSWRMSG_VEC
  lda #>duart_println
  sta OSWRMSG_VEC + 1
  lda #<duart_snd_strbuf              ; OSWRSBUF
  sta OSWRSBUF_VEC
  lda #>duart_snd_strbuf
  sta OSWRSBUF_VEC + 1
  lda #<stdout_append                 ; OSSOAPP
  sta OSSOAPP_VEC
  lda #>stdout_append
  sta OSSOAPP_VEC + 1
  lda #<stdout_add_char               ; OSSOCH
  sta OSSOCH_VEC
  lda #>stdout_add_char
  sta OSSOCH_VEC + 1
\ --- CONVERSIONS --------------------------------------------------------------
  lda #<byte_to_bin                   ; OSB2BIN
  sta OSB2BIN_VEC
  lda #>byte_to_bin
  sta OSB2BIN_VEC + 1
  lda #<byte_to_hex_str               ; OSB2HEX
  sta OSB2HEX_VEC
  lda #>byte_to_hex_str
  sta OSB2HEX_VEC + 1
  lda #<byte_to_int_str               ; OSB2ISTR
  sta OSB2ISTR_VEC
  lda #>byte_to_int_str
  sta OSB2ISTR_VEC + 1
  lda #<hex_str_to_byte               ; OSHEX2B
  sta OSHEX2B_VEC
  lda #>hex_str_to_byte
  sta OSHEX2B_VEC + 1
  lda #<uint16_to_hex_str             ; OSU16HEX
  sta OSU16HEX_VEC
  lda #>uint16_to_hex_str
  sta OSU16HEX_VEC + 1
  lda #<asc_hex_to_dec                ; OSHEX2DEC
  sta OSHEX2DEC_VEC
  lda #>asc_hex_to_dec
  sta OSHEX2DEC_VEC + 1
\ --- LCD ----------------------------------------------------------------------
  lda #<lcd_prt_chr                   ; OSLCDCH
  sta OSLCDCH_VEC
  lda #>lcd_prt_chr
  sta OSLCDCH_VEC + 1
  lda #<lcd_cls                       ; OSLCDCLS
  sta OSLCDCLS_VEC
  lda #>lcd_cls
  sta OSLCDCLS_VEC + 1
  lda #<lcd_prt_err                   ; OSLCDERR
  sta OSLCDERR_VEC
  lda #>lcd_prt_err
  sta OSLCDERR_VEC + 1
  lda #<lcd_println                   ; OSLCDMSG
  sta OSLCDMSG_VEC
  lda #>lcd_println
  sta OSLCDMSG_VEC + 1
  lda #<lcd_print_byte                ; OSLCDB2HEX
  sta OSLCDB2HEX
  lda #>lcd_print_byte
  sta OSLCDB2HEX + 1
  lda #<lcd_prt_sbuf                  ; OSLCDSBUF
  sta OSLCDSBUF_VEC
  lda #>lcd_prt_sbuf
  sta OSLCDSBUF_VEC + 1
  lda #<lcd_set_cursor                ; OSLCDSC
  sta OSLCDSC_VEC
  lda #>lcd_set_cursor
  sta OSLCDSC_VEC + 1
  lda #<lcd_prt_buf                   ; OSLCDWRBUF
  sta OSLCDWRBUF_VEC
  lda #>lcd_prt_buf
  sta OSLCDWRBUF_VEC + 1
  \ --- PRINTER ------------------------------------------------------------------
  lda #<prt_stdout_buf                ; OSPRTBUF
  sta OSPRTBUF_VEC
  lda #>prt_stdout_buf
  sta OSPRTBUF_VEC + 1
  lda #<prt_char                      ; OSPRTCH
  sta OSPRTCH_VEC
  lda #>prt_char
  sta OSPRTCH_VEC + 1
  lda #<prt_check_state               ; OSPRTCHK
  sta OSPRTCHK_VEC
  lda #>prt_check_state
  sta OSPRTCHK_VEC + 1
  lda #<prt_init                      ; OSPRTINIT
  sta OSPRTINIT_VEC
  lda #>prt_init
  sta OSPRTINIT_VEC + 1
  lda #<prt_msg                       ; OSPRTMSG
  sta OSPRTMSG_VEC
  lda #>prt_msg
  sta OSPRTMSG_VEC + 1
  lda #<prt_str_buf                   ; OSPRTSBUF
  sta OSPRTSBUF_VEC
  lda #>prt_str_buf
  sta OSPRTSBUF_VEC + 1
\  lda #<prt_load_state_msg            ; OSPRTSTMSG
\  sta OSPRTSTMSG_VEC
\  lda #>prt_load_state_msg
\  sta OSPRTSTMSG_VEC + 1
\ --- ZOLADOS ------------------------------------------------------------------
  lda #<zd_delfile                    ; OSZDDEL
  sta OSZDDEL_VEC
  lda #>zd_delfile
  sta OSZDDEL_VEC + 1
  lda #<zd_loadfile                   ; OSZDLOAD
  sta OSZDLOAD_VEC
  lda #>zd_loadfile
  sta OSZDLOAD_VEC + 1
  lda #<zd_save_data                  ; OSZDSAVE
  sta OSZDSAVE_VEC
  lda #>zd_save_data
  sta OSZDSAVE_VEC + 1

; OSUSRINT
\ --- MISC ---------------------------------------------------------------------
  lda #<delay                         ; OSDELAY
  sta OSDELAY_VEC
  lda #>delay
  sta OSDELAY_VEC + 1
; OSUSRINT - to come
