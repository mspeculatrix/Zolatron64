; Zero-page addresses
TEST_VAL    = $50
FUNC_RESULT = $60   ; to hold the result of a subroutine
FUNC_RES_L  = $61   ; for 16-bit subroutine results
FUNC_RES_H  = FUNC_RES_L+1
BYTE_CONV_L = $63   ; scratch space for converting bytes between num & string
BYTE_CONV_H = BYTE_CONV_L+1
BUF_PTR     = $65   ; multi-purpose buffer pointer
MSG_VEC     = $70   ; Message to be printed. LSB is MSG_VEC, MSB is +1
TBL_VEC_L   = $72   ; table vector - for searching tables
TBL_VEC_H	= TBL_VEC_L+1