\ cfg_ROM.asm

\ COMMAND TOKENS - cfg_ROM.asm
\ These should be in alphabetical order. Where two or more commands share the
\ same few chars at the start, the longer commands should come first.
\ The order also has to be the same as that in data_tables.asm.
\ There's nothing special about the numbers, per se - they just need to
\ be different.
CMD_TKN_NUL    = $00                   ; What happens when you just hit RTN
CMD_TKN_FAIL   = $01                   ; Syntax error & whatnot
CMD_TKN_STAR   = $80                   ; *
CMD_TKN_BANG   = CMD_TKN_STAR + 1      ; ! - A form of POKE
CMD_TKN_QUERY  = CMD_TKN_BANG + 1      ; ? - smarter form of PEEK
CMD_TKN_BRK    = CMD_TKN_QUERY + 1     ; BRK - soft reset
CMD_TKN_CHAIN  = CMD_TKN_BRK + 1       ; CHAIN
CMD_TKN_CLEAR  = CMD_TKN_CHAIN + 1     ; CLEAR - clear program
CMD_TKN_DEL    = CMD_TKN_CLEAR + 1     ; DEL - delete file
CMD_TKN_DUMP   = CMD_TKN_DEL + 1       ; DUMP - save memory to storage
CMD_TKN_HELP   = CMD_TKN_DUMP + 1      ; HELP
CMD_TKN_JMP    = CMD_TKN_HELP + 1      ; JMP - jump to memory location
CMD_TKN_LM     = CMD_TKN_JMP + 1       ; LM - list memory
CMD_TKN_LOAD   = CMD_TKN_LM + 1        ; LOAD - load program
CMD_TKN_LP     = CMD_TKN_LOAD + 1      ; LP - list memory page
CMD_TKN_LS     = CMD_TKN_LP + 1        ; LS - list storage
CMD_TKN_MV     = CMD_TKN_LS + 1        ; MV - move(rename) file
CMD_TKN_OPEN   = CMD_TKN_MV + 1        ; OPEN file
CMD_TKN_PDUMP  = CMD_TKN_OPEN + 1      ; PDUMP
CMD_TKN_PEEK   = CMD_TKN_PDUMP + 1     ; PEEK
CMD_TKN_POKE   = CMD_TKN_PEEK + 1      ; POKE
CMD_TKN_PRT    = CMD_TKN_POKE + 1      ; PRT
CMD_TKN_RUN    = CMD_TKN_PRT + 1       ; RUN - run user program
CMD_TKN_SAVE   = CMD_TKN_RUN + 1       ; SAVE
CMD_TKN_STAT   = CMD_TKN_SAVE + 1      ; STAT
CMD_TKN_VERS   = CMD_TKN_STAT + 1      ; VERS - show version
CMD_TKN_XCLR   = CMD_TKN_VERS + 1      ; XCLR - clear memory bank
CMD_TKN_XLOAD  = CMD_TKN_XCLR + 1      ; XLOAD - load file to ext memory
CMD_TKN_XLS    = CMD_TKN_XLOAD + 1	   ; XLS - list programs in ext memory
CMD_TKN_XOPEN  = CMD_TKN_XLS + 1       ; XOPEN - load data file into ext memory
CMD_TKN_XRUN   = CMD_TKN_XOPEN + 1     ; XRUN - run program in current bank
CMD_TKN_XSAVE  = CMD_TKN_XRUN + 1      ; XSAVE - save contents of memory bank
CMD_TKN_XSEL   = CMD_TKN_XSAVE + 1     ; XSEL - select ext memory bank

CMD_MAX_LEN = 8           ; Max number of chars in command names
CMDS_PER_LINE = 6         ; Number of cmds we'll print per line when using HELP

CLEAR_BYTES = 16          ; Number of bytes to clear at start of memory to
                          ; clear a program with CLEAR or XCLR commands
