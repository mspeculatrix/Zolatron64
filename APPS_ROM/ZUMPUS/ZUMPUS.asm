; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i ZUMPUS.asm

CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"
INCLUDE "../../LIB/cfg_user_port.asm"
;INCLUDE "../../LIB/cfg_uart_SC28L92.asm"

INCLUDE "../../APPS/ZUMPUS/zumpus_cfg.asm"

ORG EXTMEM_START
INCLUDE "../../APPS/ZUMPUS/zumpus_main.asm"
INCLUDE "../../APPS/ZUMPUS/zumpus_funcs.asm"
INCLUDE "../../APPS/ZUMPUS/zumpus_data.asm"
INCLUDE "../../LIB/math_uint8_div.asm"
INCLUDE "../../LIB/funcs_prng.asm"
INCLUDE "../../LIB/cfg_ZolaDOS.asm"

.endtag
  equs "EOF",0

ORG EXTMEM_END             ; To pad out space
  equb 0
.endcode

SAVE "../bin/ZUMPUS.ROM", header, endcode
