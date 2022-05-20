; ZERO PAGE CONFIG -- cfg_page_0.asm ----------------------------------------
; v08 - 25 Nov 2021
;
; Zero-page addresses
TEST_VAL    = $50

FUNC_RESULT = $60   ; to hold the 8-bit result of a subroutine
FUNC_RES_L  = FUNC_RESULT+1   ; for 16-bit subroutine results
FUNC_RES_H  = FUNC_RES_L+1
FUNC_ERR    = FUNC_RES_H+1	  ; store an error code for functions
BYTE_CONV_L = FUNC_ERR+1      ; for converting bytes between num & string
BYTE_CONV_H = BYTE_CONV_L+1
BUF_PTR     = BYTE_CONV_H+1   ; multi-purpose buffer pointer

MSG_VEC     = $70         	  ; Message to be printed. LSB is MSG_VEC, MSB is +1
TBL_VEC_L   = MSG_VEC+2   	  ; table vector - for searching tables
TBL_VEC_H	= TBL_VEC_L+1
TMP_ADDR_A  = TBL_VEC_H+1     ; temporary 2-byte vector/store for address
TMP_ADDR_A_L = TMP_ADDR_A	  ; alias
TMP_ADDR_A_H = TMP_ADDR_A+1
TMP_ADDR_B  = TMP_ADDR_A+2    ; temporary 2-byte vector/store for address
TMP_ADDR_B_L = TMP_ADDR_B	  ; alias
TMP_ADDR_B_H = TMP_ADDR_B+1

UART_STATUS_REG = $80 	      ; used to store various flags
PROC_REG = UART_STATUS_REG+1  ; process flags

; PROCESS REGISTER FLAGS
IGNORE_MSB    = %00001000        ; ignore high byte

; UART FLAGS for use with UART_STATUS_REG
;ACIA_RXRDY_FL    = %00000100		; 6551 has data in RX buffer
STDIN_NUL_RCVD_FLG = %00000001   ; we've received a null terminator
SC28L92_RXRDY_FL = %00000010 		; SC28L92 has data in RX FIFO
