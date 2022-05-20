; COMMAND TOKENS
; These should be in alphabetical order. Where two or more commands share the
; same few chars at the start, the longer commands should come first.
; The order also has to be the same as that in data_tables.asm.
CMD_TKN_NUL  = $00                    ; What happens when you just hit RTN
CMD_TKN_FAIL = $01                    ; Syntax error & whatnot
CMD_TKN_STAR = $80                    ; *
CMD_TKN_BRK  = CMD_TKN_STAR + 1       ; BRK - soft reset
CMD_TKN_HELP  = CMD_TKN_BRK + 1       ; HELP
CMD_TKN_JMP  = CMD_TKN_HELP + 1       ; JMP - jump to memory location
CMD_TKN_LM   = CMD_TKN_JMP + 1        ; LM - list memory
CMD_TKN_LOAD = CMD_TKN_LM + 1         ; LOAD - load file
CMD_TKN_LP   = CMD_TKN_LOAD + 1       ; LP - list memory page
CMD_TKN_LS   = CMD_TKN_LP + 1		      ; LS - list storage
CMD_TKN_PEEK = CMD_TKN_LS + 1         ; PEEK
CMD_TKN_POKE = CMD_TKN_PEEK + 1       ; POKE
CMD_TKN_PRT  = CMD_TKN_POKE + 1       ; PRT - print string to LCD
CMD_TKN_RUN  = CMD_TKN_PRT + 1        ; RUN - run user program
CMD_TKN_SAVE = CMD_TKN_RUN + 1        ; SAVE
CMD_TKN_VERS = CMD_TKN_SAVE + 1       ; VERS - show version
