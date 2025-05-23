; ZERO PAGE CONFIG -- cfg_page_0.asm -------------------------------------------

MSG_VEC       = $E0    	 		    ; $E0 Message to print
FUNC_RES_L    = MSG_VEC + 2         ; $E2 For 16-bit subroutine results. Must be
FUNC_RES_H    = FUNC_RES_L + 1      ; $E3 in zero page.
FUNC_RESULT   = FUNC_RES_H + 1      ; $E4 To hold the 8-bit result of a function
FUNC_ERR      = FUNC_RESULT + 1	    ; $E5 Store an error code for functions

TBL_VEC_L     = FUNC_ERR + 1        ; $E6 Table vector - for searching tables
TBL_VEC_H     = TBL_VEC_L + 1       ; $E7
TMP_ADDR_A    = TBL_VEC_H + 1       ; $E8 Temp 2-byte vector/store for address
TMP_ADDR_A_L  = TMP_ADDR_A	        ; $E8 - Alias -
TMP_ADDR_A_H  = TMP_ADDR_A + 1      ; $E9
TMP_ADDR_B    = TMP_ADDR_A_H + 1    ; $EA Temp 2-byte vector/store for address
TMP_ADDR_B_L  = TMP_ADDR_B	        ; $EA - Alias -
TMP_ADDR_B_H  = TMP_ADDR_B + 1      ; $EB
TMP_ADDR_C    = TMP_ADDR_B_H + 1    ; $EC
TMP_ADDR_C_L  = TMP_ADDR_C	        ; $EC - Alias -
TMP_ADDR_C_H  = TMP_ADDR_C_L + 1	; $ED

FILE_ADDR     = TMP_ADDR_C_H + 1    ; $EE
PROG_END      = FILE_ADDR + 2       ; $F0 Last byte of user program
LOMEM         = PROG_END + 2        ; $F2 First available byte after user prog

STDIN_STATUS_REG = LOMEM + 2	    ; $F4 STDIN flags - see: cfg_main.asm
SYS_REG = STDIN_STATUS_REG + 1      ; $F5 System Register
; SYSTEM REGISTER
; The SYS_EXMEM and SYS_PARALELL must be in bits 0 and 1.
; Bit     Flag name            Function
;  0      SYS_EXMEM/_NO        Extended memory fitted     - 1=yes, 0=no
;  1      SYS_PARALLEL/_NO     Parallel board fitted      - 1=yes, 0=no
;  2      SYS_SPI/_NO          SPI interface board fitted - 1=yes, 0=no
;  3
;  4
;  5      LCD_SIZE             0 = 2x16, 1 = 4x20
;  6
;  7
; BIT MASKS FOR SYS_REG
SYS_EXMEM         = %00000001   ; ORA with reg to set or AND to test flag
SYS_EXMEM_NO      = %11111110   ; AND with reg to unset flag
SYS_PARALLEL      = %00000010   ; ORA with reg to set or AND to test flag
SYS_PARALLEL_NO   = %11111101   ; AND with reg to unset flag
SYS_SPI           = %00000100   ; ORA with reg to set or AND to test flag
SYS_SPI_NO        = %11111011   ; AND with reg to unset flag

IRQ_REG   = SYS_REG + 1         ; $F6 - IRQ register
; BIT MASKS FOR IRQ_REG
USRP_INT_CA2 = %00000001
USRP_INT_CA1 = %00000010
RTC_ALARM    = %00000100
USRP_INT_CB2 = %00001000
USRP_INT_CB1 = %00010000
USRP_INT_TM2 = %00100000
USRP_INT_TM1 = %01000000
ZD_IRQ       = %10000000
