
CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"    ; OS Indirection Table
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"
INCLUDE "../../LIB/cfg_page_7.asm"    ; SPI, RTC, SD

INCLUDE "../../LIB/cfg_rtc_ds3234.asm"
INCLUDE "../../LIB/funcs_rtc_ds3234.asm"
INCLUDE "../../LIB/cfg_spi65.asm"
INCLUDE "../../LIB/funcs_spi65.asm"

ORG USR_START
.header                     ; HEADER INFO
  jmp startprog             ;
  equb "E"                  ; Designate executable file
  equb <header              ; @ $0802 Entry address
  equb >header
  equb <reset               ; @ $0804 Reset address
  equb >reset
  equb <endcode             ; @ $0806 Addr of first byte after end of program
  equb >endcode
  equs 0,0,0                ; -- Reserved for future use --
.prog_name
  equs "SPITEST",0          ; @ $080D Short name, max 15 chars - nul terminated
.version_string
  equs "1.0",0              ; Version string - nul terminated

.startprog
.reset

RTC_CTRL = %00000000  ; Settings for RTC chip. No interrupts.
RTC_DEV_NUM = $01		  ; Connected to peripheral select 0



.endtag
  equs "EOF",0
.endcode

SAVE "../bin/SPITEST.EXE", header, endcode