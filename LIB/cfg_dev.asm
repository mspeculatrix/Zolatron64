\ This is a set of macros designed to be used for development and
\ debugging but not intended for finished software.

\ ------------------------------------------------------------------------------
\ ---  DEV_PRINT_BIN
\ ---  Display a byte value in binary format
\ ------------------------------------------------------------------------------
\ ON ENTRY: A contains byte to be displayed
MACRO DEV_PRINT_BIN
  pha : phx : phy
  jsr OSB2BIN
  jsr OSWRSBUF
  ply : plx : pla
ENDMACRO

\ ------------------------------------------------------------------------------
\ ---  DEV_PRINT_HEX
\ ---  Display a byte value in hex format
\ ------------------------------------------------------------------------------
\ ON ENTRY: A contains byte to be displayed
MACRO DEV_PRINT_HEX
  pha : phx : phy
  jsr OSB2HEX
  jsr OSWRSBUF
  ply : plx : pla
ENDMACRO

\ ------------------------------------------------------------------------------
\ ---  DEV_PRINT_INT
\ ---  Display a byte value in decimal integer format
\ ------------------------------------------------------------------------------
\ ON ENTRY: A contains byte to be displayed
MACRO DEV_PRINT_INT
  pha : phx : phy
  jsr OSB2HEX
  jsr OSB2ISTR        ; FUNC_RESULT contains number of digits
  ply : plx : pla
ENDMACRO
