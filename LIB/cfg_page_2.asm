; PAGE TWO CONFIG -- cfg_page_2.asm --------------------------------------------

\-------------------------------------------------------------------------------
\ OS CALLS  - Vector Location Table
\ Vector locations for OS calls. These hold the addresses of the actual
\ functions that implement the OS operations.
\ Requires corresponding entries in:
\    - z64-main.asm        - OS Call Jump Table
\    - os_call_vectors.asm - map functions to vectors
\    - cfg_main.asm        - OS Function Address Table
\-------------------------------------------------------------------------------
; READ
OSGETKEY_VEC    = $0200
OSGETINP_VEC    = OSGETKEY_VEC + 2
OSRDASC_VEC     = OSGETINP_VEC + 2
OSRDBYTE_VEC    = OSRDASC_VEC + 2
OSRDCH_VEC      = OSRDBYTE_VEC + 2
OSRDHBYTE_VEC   = OSRDCH_VEC + 2
OSRDHADDR_VEC   = OSRDHBYTE_VEC + 2
OSRDINT16_VEC   = OSRDHADDR_VEC + 2
OSRDFNAME_VEC   = OSRDINT16_VEC + 2
OSRDSTR_VEC     = OSRDFNAME_VEC + 2
; WRITE
OSWRBUF_VEC     = OSRDSTR_VEC + 2
OSWRCH_VEC      = OSWRBUF_VEC + 2
OSWRERR_VEC	    = OSWRCH_VEC + 2
OSWRMSG_VEC     = OSWRERR_VEC + 2
OSWROP_VEC	    = OSWRMSG_VEC + 2
OSWRSBUF_VEC    = OSWROP_VEC + 2
OSSOAPP_VEC     = OSWRSBUF_VEC + 2
OSSOCH_VEC      = OSSOAPP_VEC + 2
; CONVERSIONS
OSB2BIN_VEC     = OSSOCH_VEC + 2
OSB2HEX_VEC     = OSB2BIN_VEC + 2
OSB2ISTR_VEC    = OSB2HEX_VEC + 2
OSHEX2B_VEC     = OSB2ISTR_VEC +2
OSU16HEX_VEC    = OSHEX2B_VEC + 2
OSU16ISTR_VEC   = OSU16HEX_VEC + 2
OSHEX2DEC_VEC   = OSU16ISTR_VEC + 2
; LCD
OSLCDCH_VEC     = OSHEX2DEC_VEC + 2
OSLCDCLS_VEC    = OSLCDCH_VEC + 2
OSLCDERR_VEC    = OSLCDCLS_VEC + 2
OSLCDMSG_VEC    = OSLCDERR_VEC + 2
OSLCDB2HEX_VEC  = OSLCDMSG_VEC + 2
OSLCDSBUF_VEC   = OSLCDB2HEX_VEC + 2
OSLCDSC_VEC     = OSLCDSBUF_VEC + 2
OSLCDWRBUF_VEC  = OSLCDSC_VEC + 2
; PRINTER
OSPRTBUF_VEC    = OSLCDWRBUF_VEC + 2
OSPRTCH_VEC     = OSPRTBUF_VEC + 2
OSPRTCHK_VEC    = OSPRTCH_VEC + 2
OSPRTINIT_VEC   = OSPRTCHK_VEC + 2
OSPRTMSG_VEC    = OSPRTINIT_VEC + 2
OSPRTSBUF_VEC   = OSPRTMSG_VEC + 2
;OSPRTSTMSG_VEC = OSPRTSBUF_VEC + 2
; ZOLADOS
OSZDDEL_VEC     = OSPRTSBUF_VEC + 2
OSZDLOAD_VEC    = OSZDDEL_VEC + 2
OSZDSAVE_VEC    = OSZDLOAD_VEC + 2
; MISC
OSDELAY_VEC     = OSZDSAVE_VEC + 2
OSUSRINT_VEC    = OSDELAY_VEC + 2   ; Vector for user interrupt service routines
OSUSRINTRTN_VEC = OSUSRINT_VEC + 2  ; and for returning from these routines
OSSPIEXCH_VEC   = OSUSRINTRTN_VEC + 2	; SPI exchange byte
OSRDDATE_VEC    = OSSPIEXCH_VEC + 2
OSRDTIME_VEC    = OSRDDATE_VEC + 2
