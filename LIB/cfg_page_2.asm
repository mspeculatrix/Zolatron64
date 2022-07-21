; PAGE TWO CONFIG -- cfg_page_2.asm --------------------------------------------

\-------------------------------------------------------------------------------
\ OS CALLS  - OS Indirection Table                                      
\ Jump table for OS calls. Requires corresponding entries in:
\    - z64-main.asm   - OS Call Jump Table
\                     - OS default config routine & stream select functions
\    - cfg_main.asm   - OS Function Address Table
\-------------------------------------------------------------------------------
; READ
OSRDHBYTE_VEC = $0200
OSRDHADDR_VEC = OSRDHBYTE_VEC + 2
OSRDCH_VEC    = OSRDHADDR_VEC + 2
OSRDINT16_VEC = OSRDCH_VEC + 2
OSRDFNAME_VEC = OSRDINT16_VEC + 2
; WRITE
OSWRBUF_VEC   = OSRDFNAME_VEC + 2
OSWRCH_VEC    = OSWRBUF_VEC + 2
OSWRERR_VEC	  = OSWRCH_VEC + 2
OSWRMSG_VEC   = OSWRERR_VEC + 2
OSWRSBUF_VEC  = OSWRMSG_VEC + 2
; CONVERSIONS
OSB2HEX_VEC   = OSWRSBUF_VEC + 2
OSB2ISTR_VEC  = OSB2HEX_VEC +2
OSHEX2B_VEC   = OSB2ISTR_VEC +2
OSU16HEX_VEC  = OSHEX2B_VEC + 2
OSHEX2DEC_VEC = OSU16HEX_VEC + 2
; LCD
OSLCDCH_VEC   = OSHEX2DEC_VEC + 2
OSLCDCLS_VEC  = OSLCDCH_VEC + 2
OSLCDERR_VEC  = OSLCDCLS_VEC + 2
OSLCDMSG_VEC  = OSLCDERR_VEC + 2
OSLCDB2HEX_VEC  = OSLCDMSG_VEC + 2
OSLCDSBUF_VEC = OSLCDB2HEX_VEC + 2
OSLCDSC_VEC   = OSLCDSBUF_VEC + 2
; PRINTER
OSPRTBUF_VEC   = OSLCDSC_VEC + 2
OSPRTCH_VEC    = OSPRTBUF_VEC + 2
OSPRTINIT_VEC  = OSPRTCH_VEC + 2
OSPRTMSG_VEC   = OSPRTINIT_VEC + 2
OSPRTSBUF_VEC  = OSPRTMSG_VEC + 2
OSPRTSTMSG_VEC = OSPRTSBUF_VEC + 2
; ZOLADOS
OSZDDEL_VEC   = OSPRTSTMSG_VEC + 2
OSZDLOAD_VEC  = OSZDDEL_VEC + 2
OSZDSAVE_VEC  = OSZDLOAD_VEC + 2
; MISC
OSUSRINT_VEC  = OSZDSAVE_VEC + 2    ; Vector for user interrupt handling routines
OSDELAY_VEC   = OSUSRINT_VEC + 2
