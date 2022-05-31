; PAGE TWO CONFIG -- cfg_page_2.asm --------------------------------------------

;CMD_BUF_SZ = $20

;CMD_BUF = $0200							          ; not used yet
;CMD_ARGS_LEN = CMD_BUF + CMD_BUF_SZ		; not used yet

\-------------------------------------------------------------------------------
\ OS CALLS  - OS Indirection Table                                      
\ Jump table for OS calls. Requires corresponding entries in:
\    - z64-main.asm   - OS Call Jump Table
\                     - OS default config routine & stream select functions
\    - cfg_main.asm   - OS Function Address Table
\-------------------------------------------------------------------------------
OSRDHBYTE_VEC = $0200
OSRDHADDR_VEC = OSRDHBYTE_VEC + 2
OSRDCH_VEC    = OSRDHADDR_VEC + 2
OSRDFNAME_VEC = OSRDCH_VEC + 2

OSWRBUF_VEC   = OSRDFNAME_VEC + 2
OSWRCH_VEC    = OSWRBUF_VEC + 2
OSWRERR_VEC	  = OSWRCH_VEC + 2
OSWRMSG_VEC   = OSWRERR_VEC + 2
OSWRSBUF_VEC  = OSWRMSG_VEC + 2

OSB2HEX_VEC   = OSWRSBUF_VEC + 2
OSHEX2B_VEC   = OSB2HEX_VEC +2

OSLCDCH_VEC   = OSHEX2B_VEC + 2
OSLCDCLS_VEC  = OSLCDCH_VEC + 2
OSLCDERR_VEC  = OSLCDCLS_VEC + 2
OSLCDMSG_VEC  = OSLCDERR_VEC + 2
OSLCDPRB_VEC  = OSLCDMSG_VEC + 2
OSLCDSC_VEC   = OSLCDPRB_VEC + 2

OSUSRINT_VEC  = OSLCDSC_VEC + 2    ; Vector for user interrupt handling routines
OSDELAY_VEC   = OSUSRINT_VEC + 2
