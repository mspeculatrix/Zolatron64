; Zero-page addresses
TEST_VAL    = $50
FUNC_RESULT = $60
FUNC_RES_L  = $61
FUNC_RES_H  = $62
BYTE_CONV_L = $63   ; scratch space for converting bytes between num & string
BYTE_CONV_H = $64
MSG_VEC     = $70  ; Message to be printed. LSB is MSG_VEC, MSB is +1
TBL_VEC     = $72  ; table vector - for searching tables
