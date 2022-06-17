\ DATA & TABLES -- data_tables.asm --------------------------------------------

ALIGN &100                  ; Start on new page

\ ===== COMMAND TABLES ========================================================

\ COMMAND POINTER JUMP TABLE
\ These entries need to be in the same order as the CMD_TKN_* definitions that
\ are in cfg_ROM.asm.
\ The entries are the labels of the relevant subroutines in z64-main.asm (or
\ the command files that includes).
.cmdprcptrs
  equw cmdprcSTAR           ; *
  equw cmdprcBRK            ; BRK
  equw cmdprcFLOAD          ; FLOAD
  equw cmdprcFLIST          ; FLIST
  equw cmdprcFRUN           ; FRUN
  equw cmdprcFS             ; FS
  equw cmdprcHELP           ; HELP
  equw cmdprcJMP            ; JMP
  equw cmdprcLM             ; LM - list memory
  equw cmdprcLOAD           ; LOAD - load file
  equw cmdprcLP             ; LP - list page
  equw cmdprcLS             ; LS - list storage
  equw cmdprcPEEK           ; PEEK
  equw cmdprcPOKE           ; POKE
  equw cmdprcPRT            ; PRT
  equw cmdprcRUN            ; RUN user program
  equw cmdprcSAVE           ; SAVE - save file
  equw cmdprcVERS           ; VERS - version

\ FIRST CHARACTER TABLE
\ Initial characters of our commands. The parsing system first looks to see if
\ the initial character is in this list.
.cmd_ch1_tbl
  equs "*BFHJLPRSV" 
  equb EOTBL_MKR            ; End of table marker

\ COMMAND POINTERS
\ These are vectors to the Command Table labels below. Once the parsing routine
\ has found the initial character, it uses its position in the First
\ Character Table (above) to determine an offset into this table.
.cmd_ptrs                   ; Pointers to command table sections
  equw cmd_tbl_STAR         ; Commands starting '*'
  equw cmd_tbl_ASCB         ; Commands starting 'B'
  equw cmd_tbl_ASCF         ; Commands starting 'F'
  equw cmd_tbl_ASCH         ; Commands starting 'H'
  equw cmd_tbl_ASCJ         ; Commands starting 'J'
  equw cmd_tbl_ASCL         ; Commands starting 'L'
  equw cmd_tbl_ASCP         ; Commands starting 'P'
  equw cmd_tbl_ASCR         ; Commands starting 'R'
  equw cmd_tbl_ASCS         ; Commands starting 'S'
  equw cmd_tbl_ASCV         ; Commands starting 'V'

\ COMMAND TABLE
\ Having found the an address in the Command Pointers table above, the parsing
\ rutine then jumps to the corresponding label in this section to match the
\ rest of the characters in the command. When a match is made, it then reads
\ the corresponding token value following the command name.
.cmd_tbl_STAR               ; Commands starting '*'
  equb CMD_TKN_STAR         ; Not sure what I'm using this for yet
  equb EOCMD_SECTION        ; Comes at end of each section

.cmd_tbl_ASCB               ; Commands starting 'B'
  equs "RK", CMD_TKN_BRK    ; BRK
  equb EOCMD_SECTION

.cmd_tbl_ASCF                ; Commands starting 'F'
  equs "LOAD", CMD_TKN_FLOAD ; FLOAD
  equs "LIST", CMD_TKN_FLIST ; FLIST
  equs "RUN", CMD_TKN_FRUN   ; FRUN
  equs "S", CMD_TKN_FS       ; FS
  equb EOCMD_SECTION

.cmd_tbl_ASCH               ; Commands starting 'H'
  equs "ELP", CMD_TKN_HELP  ; HELP
  equb EOCMD_SECTION

.cmd_tbl_ASCJ               ; Commands starting 'J'
  equs "MP", CMD_TKN_JMP    ; JMP
  equb EOCMD_SECTION

.cmd_tbl_ASCL               ; Commands starting 'L'
  equs "M", CMD_TKN_LM      ; LM
  equs "OAD", CMD_TKN_LOAD  ; LOAD
  equs "P", CMD_TKN_LP      ; LP
  equs "S", CMD_TKN_LS      ; LS
  equb EOCMD_SECTION

.cmd_tbl_ASCP               ; Commands starting 'P'
  equs "EEK", CMD_TKN_PEEK  ; PEEK
  equs "OKE", CMD_TKN_POKE  ; POKE
  equs "RT", CMD_TKN_PRT    ; PRT
  equb EOCMD_SECTION

.cmd_tbl_ASCR               ; Commands starting 'R'
  equs "UN", CMD_TKN_RUN    ; RUN
  equb EOCMD_SECTION

.cmd_tbl_ASCS               ; Commands starting 'S'
  equs "AVE", CMD_TKN_SAVE  ; SAVE
  equb EOCMD_SECTION

.cmd_tbl_ASCV               ; Commands starting 'V'
  equs "ERS", CMD_TKN_VERS  ; VERS
  equb EOCMD_SECTION

\ ===== ERROR TABLES ========+==================================================
\ See cfg_main.asm for the corresponding error numbers. This list needs to be in
\ the same order as that list.
\ Error Message Pointer Table
.err_ptrs                   
  equw err_msg_cmd
  equw err_msg_hex_bin_conv
  equw err_msg_parse
  equw err_msg_read_hexbyte
  equw err_msg_syntax
  equw err_file_read
  equw err_timeout_SR
  equw err_timeout_SA
  equw err_timeout_SRO
  equw err_timeout_SAO

  equw err_filesvropen
  equw err_filesvrls

  equw err_filename_badchar
  equw err_filename_badlen

  equw err_end_of_buffer
  equw err_not_a_number

\ Error Message Table
.err_msg_cmd
  equs "Bad command! Bad, bad command!", 0
.err_msg_hex_bin_conv
  equs "Hex-byte error",0
.err_msg_parse
  equs "Parse error",0
.err_msg_read_hexbyte
  equs "Err reading hex input",0
.err_msg_syntax
  equs "What?", 0
.err_file_read
  equs "File read error", 0
.err_timeout_SR
  equs "SR Timeout", 0
.err_timeout_SA
  equs "SA Timeout", 0
.err_timeout_SRO
  equs "SR Off Timeout", 0
.err_timeout_SAO
  equs "SA Off Timeout", 0
.err_filesvropen
  equs "File open failed on server", 0
.err_filesvrls
  ;     1234567890ABCDEF
  equs "File list failed on server", 0
.err_filename_badchar
  equs "Bad filename",0
.err_filename_badlen
  equs "Bad f/n length",0
.err_end_of_buffer
  equs "End of buffer",0
.err_not_a_number
  equs "Not a number",0 

\ ===== MISC TABLES & STRINGS ==================================================

.help_table
  equs "BRK",0
  equs "FLOAD",0
  equs "FLIST",0
  equs "FRUN",0
  equs "FS",0
  equs "HELP",0
  equs "JMP",0
  equs "LM",0
  equs "LS",0
  equs "LOAD",0
  equs "LP",0
  equs "PEEK",0
  equs "POKE",0
  equs "RUN",0
  equs "VERS",0
  equb EOTBL_MKR

\ HEX CHARACTER TABLE
.hex_chr_tbl
  equs "0123456789ABCDEF"

.memory_header
  equs "----  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F", 10, 0

\ MESSAGES
.test_msg
  equs "Hello World!", 0
  
.prompt_msg
  equs CHR_LINEEND, "Z>", 0

.start_msg
	equs "Zolatron 64", 0

;ALIGN &100                  ; Start on new page
;.identity_table
;    equs $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
;    equs $10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f
;    equs $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f
;    equs $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f
;    equs $40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f
;    equs $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$5b,$5c,$5d,$5e,$5f
;    equs $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e,$6f
;    equs $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7a,$7b,$7c,$7d,$7e,$7f
;    equs $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8a,$8b,$8c,$8d,$8e,$8f
;    equs $90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9a,$9b,$9c,$9d,$9e,$9f
;    equs $a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9,$aa,$ab,$ac,$ad,$ae,$af
;    equs $b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9,$ba,$bb,$bc,$bd,$be,$bf
;    equs $c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7,$c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf
;    equs $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$da,$db,$dc,$dd,$de,$df
;    equs $e0,$e1,$e2,$e3,$e4,$e5,$e6,$e7,$e8,$e9,$ea,$eb,$ec,$ed,$ee,$ef
;    equs $f0,$f1,$f2,$f3,$f4,$f5,$f6,$f7,$f8,$f9,$fa,$fb,$fc,$fd,$fe,$ff
