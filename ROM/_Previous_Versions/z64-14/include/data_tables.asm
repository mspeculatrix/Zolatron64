\\ DATA & TABLES -- data_tables.asm --------------------------------------------

ALIGN &100        ; start on new page

\\ ===== COMMAND TABLES ========================================================

\\ COMMAND POINTER JUMP TABLE
.cmdprcptrs                 ; these entries need to be in the same order as
  equw cmdprcSTAR           ; the CMD_TKN_* definitions
  equw cmdprcBRK            ; BRK
  equw cmdprcJMP            ; JMP
  equw cmdprcLM             ; LM - list memory
  equw cmdprcLP             ; LP - list page
  equw cmdprcPEEK           ; PEEK
  equw cmdprcPOKE           ; POKE
  equw cmdprcPRT
  equw cmdprcVERS           ; VERS - version

\\ FIRST CHARACTER TABLE
.cmd_ch1_tbl                ; table of command first characters
  equs "*BJLPV" 
  equb EOTBL_MKR            ; end of table marker

\\ COMMAND POINTERS
.cmd_ptrs                   ; pointers to command table sections
  equw cmd_tbl_STAR         ; commands starting '*'
  equw cmd_tbl_ASCB         ; commands starting 'B'
  equw cmd_tbl_ASCJ         ; commands starting 'J'
  equw cmd_tbl_ASCL         ; commands starting 'L'
  equw cmd_tbl_ASCP         ; commands starting 'P'
  equw cmd_tbl_ASCV         ; commands starting 'V'

\\ Command table
.cmd_tbl_STAR               ; commands starting '*'
  equb CMD_TKN_STAR         ; not sure what I'm using this for yet
  equb EOCMD_SECTION        ; comes at end of each section

.cmd_tbl_ASCB               ; commands starting 'B'
  equs "RK", CMD_TKN_BRK    ; BRK
  equb EOCMD_SECTION

.cmd_tbl_ASCJ               ; commands starting 'J'
  equs "MP", CMD_TKN_JMP    ; JMP
  equb EOCMD_SECTION

.cmd_tbl_ASCL               ; commands starting 'L'
  equs "M", CMD_TKN_LM      ; LM
  equs "P", CMD_TKN_LP      ; LP
  equb EOCMD_SECTION

.cmd_tbl_ASCP               ; commands starting 'P'
  equs "EEK", CMD_TKN_PEEK  ; PEEK
  equs "OKE", CMD_TKN_POKE  ; POKE
  equs "RT", CMD_TKN_PRT    ; PRT
  equb EOCMD_SECTION

.cmd_tbl_ASCV               ; commands starting 'V'
  equs "ERS", CMD_TKN_VERS  ; VERS
  equb EOCMD_SECTION

\\ ===== ERROR TABLES ==========================================================

.err_ptrs                   ; message pointer table
  equw err_msg_cmd
  equw err_msg_hex_bin_conv
  equw err_msg_parse
  equw err_msg_read_hexbyte
  equw err_msg_syntax

.err_msg_cmd
  equs "Bad command! Bad, bad command!", 0
.err_msg_hex_bin_conv
  equs "Error converting hex chars to byte",0
.err_msg_parse
  equs "Hmm, didn't quite get that...",0
.err_msg_read_hexbyte
  equs "Meh! Trouble reading hex input",0
.err_msg_syntax
  equs "What?", 0

\\ ===== MISC TABLES & STRINGS =================================================

\\ HEX CHARACTER TABLE
.hex_chr_tbl
  equs "0123456789ABCDEF"

.led_on_mask
  equb 1,2,4,8,16
.led_off_mask
  equb %11111110,%11111101,%11111011,%11110111,%11101111

\\ MESSAGES
.memory_header
  equs "----  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F", 10, 0

.test_msg
  equs "Hello World!", 0
  
.prompt_msg
  equs CHR_LINEEND, "Z>", 0

.start_msg
	equs "Zolatron 64", 0
