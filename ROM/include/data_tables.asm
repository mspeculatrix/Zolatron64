\ --- DATA & TABLES - data_tables.asm ------------------------------------------

ALIGN &100                  ; Start on new page

\ ===== COMMAND TABLES ========================================================

\ COMMAND POINTER JUMP TABLE
\ These entries need to be in the same order as the CMD_TKN_* definitions that
\ are in cfg_ROM.asm.
\ The entries are the labels of the relevant subroutines in z64-main.asm (or
\ the command files that includes).
.cmdprcptrs
  equw cmdprcSTAR           ; *     - (for future expansion)
  equw cmdprcBANG           ; !     - poke a byte to memory location
  equw cmdprcQUERY          ; ?     - read byte at memory location
  equw cmdprcBRK            ; BRK   - perform soft reset
  equw cmdprcCHAIN          ; CHAIN - load & execute program
  equw cmdprcCLEAR          ; CLEAR - clears program from RAM
  equw cmdprcDATE           ; DATE  - print current date
  equw cmdprcDEL            ; DEL   - delete a file from persistent store
  equw cmdprcDUMP           ; DUMP  - dump region of memory to persistent store
  equw cmdprcHELP           ; HELP  - print list of CLI commands
  equw cmdprcJMP            ; JMP   - jump to memory loc. & execute from there
  equw cmdprcLM             ; LM    - list memory
  equw cmdprcLOAD           ; LOAD  - load file
  equw cmdprcLP             ; LP    - list memory page
  equw cmdprcLS             ; LS    - list storage
  equw cmdprcMV             ; MV    - move (rename) file
  equw cmdprcOPEN           ; OPEN  - load data to memory
  equw cmdprcPDUMP          ; PDUMP - hex dump of executable code at USR_START
  equw cmdprcPEEK           ; PEEK  - read byte at memory location
  equw cmdprcPOKE           ; POKE  - poke a byte to memory location
  equw cmdprcPRT            ; PRT   - (for future use)
  equw cmdprcRUN            ; RUN   - execute user program at USR_START
  equw cmdprcSAVE           ; SAVE  - save file
  equw cmdprcSTAT           ; STAT  - status info
  equw cmdprcTIME           ; TIME  - print time
  equw cmdprcVERS           ; VERS  - version
  equw cmdprcXCLR           ; XCLR  - clear current EXT RAM bank
  equw cmdprcXLOAD          ; XLOAD - load executable into EXT RAM bank
  equw cmdprcXLS            ; XLS   - list contents of EXT ROM/RAM banks
  equw cmdprcXOPEN          ; XOPEN - load data into EXT RAM bank
  equw cmdprcXRUN           ; XRUN  - run executable in current ROM/RAM bank
  equw cmdprcXSAVE          ; XSAVE - save contents of ROM/RAM bank
  equw cmdprcXSEL           ; XSEL  - select ROM/RAM bank

\ FIRST CHARACTER TABLE
\ Initial characters of our commands. The parsing system first looks to see if
\ the initial character is in this list and uses its position in the list to
\ understand where to go next by looking it up in the Command Pointers table
\ below.
.cmd_ch1_tbl
  equs "*!?BCDHJLMOPRSTVX"
  equb EOTBL_MKR            ; End of table marker

\ COMMAND POINTERS
\ These are vectors to the Command Table labels below. Once the parsing routine
\ has found the initial character, it uses its position in the First
\ Character Table (above) to determine an offset into this table. This table,
\ which lists the labels of the alphabetic sections in the Command Table
\ (below) gives the OS the address to go to next - ie, the appropriate label
\ of the Command Table section.
.cmd_ptrs                   ; Pointers to command table sections
  equw cmd_tbl_STAR         ; Commands starting '*'
  equw cmd_tbl_BANG         ; Commands starting '!'
  equw cmd_tbl_QUERY        ; Commands starting '?'
  equw cmd_tbl_ASCB         ; Commands starting 'B'
  equw cmd_tbl_ASCC         ; Commands starting 'C'
  equw cmd_tbl_ASCD         ; Commands starting 'D'
  equw cmd_tbl_ASCH         ; Commands starting 'H'
  equw cmd_tbl_ASCJ         ; Commands starting 'J'
  equw cmd_tbl_ASCL         ; Commands starting 'L'
  equw cmd_tbl_ASCM         ; Commands starting 'M'
  equw cmd_tbl_ASCO         ; Commands starting 'O'
  equw cmd_tbl_ASCP         ; Commands starting 'P'
  equw cmd_tbl_ASCR         ; Commands starting 'R'
  equw cmd_tbl_ASCS         ; Commands starting 'S'
  equw cmd_tbl_ASCT         ; Commands starting 'T'
  equw cmd_tbl_ASCV         ; Commands starting 'V'
  equw cmd_tbl_ASCX         ; Commands starting 'X'

\ COMMAND TABLE
\ Having found the an address in the Command Pointers table above, the parsing
\ routine then jumps to the corresponding label in this section to match the
\ rest of the characters in the command. When a match is made, it then reads
\ the corresponding token value following the command name.
.cmd_tbl_STAR                  ; Commands starting '*'
  equb CMD_TKN_STAR            ; Not sure what I'm using this for yet
  equb EOCMD_SECTION           ; Comes at end of each section

.cmd_tbl_BANG                  ; Command '!'
  equb CMD_TKN_BANG            ;
  equb EOCMD_SECTION

.cmd_tbl_QUERY                 ; Command '?'
  equb CMD_TKN_QUERY           ;
  equb EOCMD_SECTION

.cmd_tbl_ASCB                  ; Commands starting 'B'
  equs "RK", CMD_TKN_BRK       ; BRK
  equb EOCMD_SECTION

.cmd_tbl_ASCC                  ; Commands starting 'C'
  equs "HAIN", CMD_TKN_CHAIN   ; CHAIN
  equs "LEAR", CMD_TKN_CLEAR   ; CLEAR
  equb EOCMD_SECTION

.cmd_tbl_ASCD                  ; Commands starting 'D'
  equs "ATE", CMD_TKN_DATE     ; DATE
  equs "EL", CMD_TKN_DEL       ; DEL
  equs "UMP", CMD_TKN_DUMP     ; DUMP
  equb EOCMD_SECTION

.cmd_tbl_ASCH                  ; Commands starting 'H'
  equs "ELP", CMD_TKN_HELP     ; HELP
  equb EOCMD_SECTION

.cmd_tbl_ASCJ                  ; Commands starting 'J'
  equs "MP", CMD_TKN_JMP       ; JMP
  equb EOCMD_SECTION

.cmd_tbl_ASCL                  ; Commands starting 'L'
  equs "M", CMD_TKN_LM         ; LM
  equs "OAD", CMD_TKN_LOAD     ; LOAD
  equs "P", CMD_TKN_LP         ; LP
  equs "S", CMD_TKN_LS         ; LS
  equb EOCMD_SECTION

.cmd_tbl_ASCM                  ; Commands starting 'M'
  equs "V", CMD_TKN_MV         ; MV
  equb EOCMD_SECTION

.cmd_tbl_ASCO                  ; Commands starting 'O'
  equs "PEN", CMD_TKN_OPEN     ; OPEN
  equb EOCMD_SECTION

.cmd_tbl_ASCP                  ; Commands starting 'P'
  equs "DUMP", CMD_TKN_PDUMP   ; PDUMP
  equs "EEK", CMD_TKN_PEEK     ; PEEK
  equs "OKE", CMD_TKN_POKE     ; POKE
  equb EOCMD_SECTION

.cmd_tbl_ASCR                  ; Commands starting 'R'
  equs "UN", CMD_TKN_RUN       ; RUN
  equb EOCMD_SECTION

.cmd_tbl_ASCS                  ; Commands starting 'S'
  equs "AVE", CMD_TKN_SAVE     ; SAVE
  equs "TAT", CMD_TKN_STAT     ; STAT
  equb EOCMD_SECTION

.cmd_tbl_ASCT                  ; Commands starting 'T'
  equs "IME", CMD_TKN_TIME     ; TIME
  equb EOCMD_SECTION

.cmd_tbl_ASCV                  ; Commands starting 'V'
  equs "ERS", CMD_TKN_VERS     ; VERS
  equb EOCMD_SECTION

.cmd_tbl_ASCX                  ; Commands starting 'X'
  equs "CLR", CMD_TKN_XCLR     ; XCLR
  equs "LOAD", CMD_TKN_XLOAD   ; XLOAD
  equs "LS", CMD_TKN_XLS       ; XLS
  equs "OPEN", CMD_TKN_XOPEN   ; XOPEN
  equs "RUN", CMD_TKN_XRUN     ; XRUN
  equs "SAVE", CMD_TKN_XSAVE   ; XSAVE
  equs "SEL", CMD_TKN_XSEL     ; XSEL
  equb EOCMD_SECTION

\ ===== ERROR TABLES ===========================================================

\ Error Message Pointer Table
\ See cfg_main.asm for the corresponding error numbers. This list needs to be in
\ the same order as that list because that list acts as an index into this one.
\ This list in turn provides the address of the (label of) the appropriate
\ text in the Error Messages section.
.err_ptrs
  equw err_msg_cmd
  equw err_null_entry
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

  equw err_extmem_write
  equw err_extmem_bank
  equw err_extmem_exec

  equw err_addr
  equw err_file_exists
  equw err_file_open
  equw ERR_FILE_DEL
  equw err_filenotfound
  equw err_file_bounds

  equw err_stdin_buf_empty

  equw err_no_executable

  equw err_printer_state_ol
  equw err_printer_state_pe
  equw err_printer_state_err
  equw err_printer_not_present

  equw err_spi_not_present

\ Error Messages
.err_msg_cmd
  equs "Bad command! Bad, bad command!", 0
.err_null_entry
  equs "Null entry",0
.err_msg_hex_bin_conv
  equs "Hex-byte error",0
.err_msg_parse
  ;     12345678901234567890
  equs "Bad command/exec",0
.err_msg_read_hexbyte
  equs "Err reading hex",0
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
  equs "Server f/open error", 0
.err_filesvrls
  equs "Server f/list error", 0
.err_filename_badchar
  equs "Bad filename",0
.err_filename_badlen
  equs "Bad filename length",0
.err_file_bounds
  equs "Data out of bounds",0
.err_end_of_buffer
  equs "End of buffer",0
.err_not_a_number
  equs "Not a number",0
.err_extmem_write
  equs "Extmem not writeable",0
.err_extmem_bank
  equs "Ext mem bank error",0
.err_extmem_exec
  equs "Ext mem not executable",0
.err_addr
  equs "Address error",0
.err_file_exists
  equs "Error: File exists",0
.err_file_open
  equs "Error opening file",0
.err_file_del
  equs "Delete file failed",0
.err_filenotfound
  equs "File not found",0
.err_stdin_buf_empty
  equs "Input buffer empty",0
.err_no_executable
  equs "No program loaded",0
.err_printer_state_ol
  equs "Printer offline",0
.err_printer_state_pe
  equs "Printer: paper out",0
.err_printer_state_err
  equs "Printer error",0
.err_printer_not_present
  equs "No printer interface",0
.err_spi_not_present
  equs "No SPI interface",0

\ ===== MISC TABLES & STRINGS ==================================================

.ext_data_types               ; Valid data type characters for extended memory
  equs "BDEOX",0

.help_table                   ; Text for 'HELP' output
  equs "?",0
  equs "!",0
  equs "BRK",0
  equs "CHAIN",0
  equs "CLEAR",0
  equs "DATE",0
  equs "DEL",0
  equs "DUMP",0
  equs "HELP",0
  equs "JMP",0
  equs "LM",0
  equs "LOAD",0
  equs "LP",0
  equs "LS",0
  equs "(MV)",0
  equs "OPEN",0
  equs "PDUMP",0
  equs "PEEK",0
  equs "POKE",0
  equs "RUN",0
  equs "SAVE",0
  equs "STAT",0
  equs "TIME",0
  equs "VERS",0
  equs "XCHAIN",0
  equs "XCLR",0
  equs "XLOAD",0
  equs "XLS",0
  equs "XOPEN",0
  equs "XRUN",0
  equs "XSAVE",0
  equs "XSEL",0
  equb EOTBL_MKR

\ HEX CHARACTER TABLE
.hex_chr_tbl                  ; For converting numeric value to hex character
  equs "0123456789ABCDEF"

.memory_header                ; For 'LM' and 'LP' output
  equs "----  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F    "
  equs "0123456789ABCDEF", 10, 0

\ MESSAGES
;       01234567890123456789
.exmem_fitted_msg
  equs "+ Extended memory",0
.exmem_absent_msg
  equs "- No extended memory",0

.parallel_if_fitted
  equs "+ Parallel interface",0
.parallel_if_not_fitted
  equs "- No parallel I/F",0

.spi_if_present_msg
  equs "+ SPI interface",0
.spi_if_not_present_msg
  equs "- No SPI I/F",0

.test_msg
  equs "Hello World!",0
.test_msg2
  equs "Test message",0

.prompt_msg
  equs CHR_LINEEND, "Z>", 0

.start_msg
	equs "Zolatron 64", 0
.okay_msg
  equs "OK",10,0
.ready_msg
  equs "Ready",0

;ALIGN &100                  ; Start on new page
;.identity_table             ; Not using yet
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
