\ DATA & TABLES -- data_tables.asm --------------------------------------------

ALIGN &100                  ; Start on new page

\ ===== COMMAND TABLES ========================================================

\ COMMAND POINTER JUMP TABLE
\ These entries need to be in the same order as the CMD_TKN_* definitions
.cmdprcptrs
  equw cmdprcSTAR           ; *
  equw cmdprcBRK            ; BRK
  equw cmdprcFLOAD          ; FLOAD
  equw cmdprcFSEL           ; FSEL
  equw cmdprcHELP           ; HELP
  equw cmdprcJMP            ; JMP
  equw cmdprcLM             ; LM - list memory
  equw cmdprcLOAD           ; LOAD - load file
  equw cmdprcLP             ; LP - list page
  equw cmdprcLS             ; LS - list storage
  equw cmdprcPEEK           ; PEEK
  equw cmdprcPOKE           ; POKE
  equw cmdprcPRT
  equw cmdprcRUN            ; RUN user program
  equw cmdprcSAVE           ; SAVE - save file
  equw cmdprcVERS           ; VERS - version

\ FIRST CHARACTER TABLE
\ Initial characters of our commands.
.cmd_ch1_tbl
  equs "*BFHJLPRSV" 
  equb EOTBL_MKR            ; End of table marker

\ COMMAND POINTERS
\ These are vectors to the Command Table labels below.
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
.cmd_tbl_STAR               ; Commands starting '*'
  equb CMD_TKN_STAR         ; Not sure what I'm using this for yet
  equb EOCMD_SECTION        ; Comes at end of each section

.cmd_tbl_ASCB               ; Commands starting 'B'
  equs "RK", CMD_TKN_BRK    ; BRK
  equb EOCMD_SECTION

.cmd_tbl_ASCF                ; Commands starting 'F'
  equs "LOAD", CMD_TKN_FLOAD ; FLOAD
  equs "SEL", CMD_TKN_FSEL   ; FSEL
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

\ ===== MISC TABLES & STRINGS ==================================================

.help_table
  equs "BRK",0
  equs "FLOAD",0
  equs "FSEL",0
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
