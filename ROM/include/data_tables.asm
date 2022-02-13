; DATA & TABLES -- data_tables.asm ---------------------------------------------
; v06 - 04 Nov 2021
;
ALIGN &100        ; start on new page

; ===== COMMAND TABLES =========================================================
.cmd_ch1_tbl              ; table of command first characters
  equs "*LPV" 
  equb EOTBL_MKR          ; end of table marker

.cmd_ptrs                 ; pointers to command table sections
  equw cmd_tbl_STAR       ; commands starting '*'
  equw cmd_tbl_ASCL       ; commands starting 'L'
  equw cmd_tbl_ASCP       ; commands starting 'P'
  equw cmd_tbl_ASCV       ; commands starting 'V'

; Command table
.cmd_tbl_STAR               ; commands starting '*'
.cmd_STAR
  equb CMD_TKN_STAR         ; not sure what I'm using this for yet
  equb EOCMD_SECTION        ; comes at end of each section
.cmd_tbl_ASCL               ; commands starting 'L'
.cmd_LM
  equs "M", CMD_TKN_LM      ; LM
.cmd_LP 
  equs "P", CMD_TKN_LP      ; LP
  equb EOCMD_SECTION
.cmd_tbl_ASCP               ; commands starting 'P'
.cmd_PRT
  equs "RT", CMD_TKN_PRT    ; PRT
  equb EOCMD_SECTION
.cmd_tbl_ASCV               ; commands starting 'V'
.cmd_VERS
  equs "ERS", CMD_TKN_VERS        ; VERS
  equb EOCMD_SECTION

; ===== ERROR TABLES ===========================================================

.err_ptrs
  equw err_msg_cmd
  equw err_msg_hex_bin_conv
  equw err_msg_read_hexbyte
  equw err_msg_syntax

.err_msg_cmd
  equs "Bad command! Bad, bad command!", 0
.err_msg_hex_bin_conv
  equs "Error converting hex chars to byte",0
.err_msg_read_hexbyte
  equs "Error reading hex byte from input.",0
.err_msg_syntax
  equs "What?", 0

; ===== MISC TABLES & STRINGS ==================================================

; HEX CHARACTER TABLE
.hex_chr_tbl
  equs "0123456789ABCDEF"

; MESSAGES
.memory_header
  equs "ADDR  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F",0

.prompt_msg
  equs CHR_LINEEND, "Z>", 0

.start_msg
	equs "Zolatron 64", 0
