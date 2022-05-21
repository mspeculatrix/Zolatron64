; ACIA CONFIG -- cfg_acia.asm --------------------------------------------------
; For 6551 ACIA

; ACIA addresses
ACIA_DATA_REG  = $B000 ; transmit/receive data register
ACIA_STAT_REG  = $B001 ; status register
ACIA_CMD_REG   = $B002 ; command register
ACIA_CTRL_REG  = $B003 ; control register

; see: cfg_page_2.asm for declaration of UART_STATUS_REG

; masks for setting/reading/resetting flags
;ACIA_FL_RX_BUF_DATA = %00000001   ; Receive buffer has data
;ACIA_FL_RX_DATA_RST = %11111110   ; Reset mask

; ACIA_FL_RX_BUF_FULL = %00001000
;STDOUT_BUF_DATA_FLG = %00010000   ; TX buffer has data to send
;STDOUT_BUF_FULL_FLG = %10000000
;STDOUT_CLEAR_FLAGS = %00001111   ; to be ANDed with reg to clear TX flags

; Following are values for the control register, setting eight data bits, 
; no parity, 1 stop bit and use of the internal baud rate generator
;ACIA_8N1_0300 = %10010110
;ACIA_8N1_1200 = %10011000
;ACIA_8N1_2400 = %10011010
ACIA_8N1_9600 = %10011110
;ACIA_8N1_19K2 = %10011111
; Value for the command register: No parity, echo normal, RTS low with no 
; transmit IRQ, IRQ enabled on receive, data terminal ready
ACIA_CMD_CFG = %00001001
; Mask values to be ANDed with status reg to check state of ACIA 
; ACIA_IRQ_SET = %10000000
ACIA_RDRF_BIT = %00001000     ; Receive Data Register Full
; ACIA_OVRN_BIT = %00000100     ; Overrun error
; ACIA_FE_BIT   = %00000010     ; Frame error
ACIA_TX_RDY_BIT = %00010000
ACIA_RX_RDY_BIT = %00001000

; UART FLAGS & MASKS for use with UART_STATUS_REG
;DUART_RxA_RDY_FL       = %00000010 	; Defined in cfg_uart_SC28L92.asm
;DUART_RxA_DATA_RCVD_FL = %00000100		;    "     "         "
;DUART_RxA_BUF_FULL_FL  = %00001000		;    "     "         "
;DUART_RxA_NUL_RCVD_FL  = %00010000		;    "     "         "
;DUART_RxA_CLR_FLAGS    = %11100111   ;    "     "         "
