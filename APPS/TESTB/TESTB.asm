; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i TESTB.asm

MACRO PRT_ADDR addr
  lda addr
  sta TMP_ADDR_A_L
  lda addr + 1
  sta TMP_ADDR_A_H
  jsr OSU16HEX
  jsr OSWRSBUF
ENDMACRO

\ USRP_PORTA
\ USRP_DDRA

\ This is based on Ben Eater's code and works only if you use these specific
\ bits for the signals.
\ https://www.youtube.com/watch?v=MCi7dCBhVpQ
SPI_CLK = %00000001
SPI_SDO = %00000010                     ; MOSI
SPI_SDI = %01000000                     ; MISO - Bit 6 so we can use BIT opcode
SPI_CS  = %00000100

CPU 1                               ; use 65C02 instruction set

NUM = $545E ; 21598
;NUM = $0

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"
INCLUDE "../../LIB/cfg_user_port.asm"

ORG USR_START
.header                     ; HEADER INFO
  jmp startprog             ;
  equb "E"                  ; Designate executable file
  equb <header              ; Entry address
  equb >header
  equb <reset               ; Reset address
  equb >reset
  equb <endcode             ; Addr of first byte after end of program
  equb >endcode
  equs 0,0,0                ; -- Reserved for future use --
.prog_name
  equs "TESTB",0           ; @ $080D Short name, max 15 chars - nul terminated
.version_string
  equs "1.0",0              ; Version string - nul terminated

.startprog
.reset
  sei             ; don't interrupt me yet
  cld             ; we don' need no steenkin' BCD
  ldx #$ff        ; set stack pointer to $01FF - only need to set the
  txs             ; LSB, as MSB is assumed to be $01

  lda #0
  sta PRG_EXIT_CODE

  cli

.main
  LOAD_MSG start_msg
  jsr OSWRMSG

  jsr spi_init

  \ EXAMPLE: Writing to registers
  stz USRP_PORTA          ; Takes all lines low, including CS, so starts session
  lda #75                 ; Load register value
  jsr spi_transceive
  lda #%00000110          ; Load value to put in register
  jsr spi_transceive      ; Send it
  lda #SPI_CS             ; Load bit mask
  sta USRP_PORTA          ; Sets CS high, ends session

  \ EXAMPLE: Sending command & receiving response
  stz USRP_PORTA          ; Takes all lines low, including CS, so starts session
  lda #$FA                ; Load command
  jsr spi_transceive      ; Send command
  jsr spi_transceive      ; Receive response - byte in A
  sta SOMEWHERE
  lda #SPI_CS             ; Load bit mask
  sta USRP_PORTA          ; Sets CS high, ends session

.prog_end
  jmp OSSFTRST

\ ------------------------------------------------------------------------------
\ -----  FUNCTIONS
\ ------------------------------------------------------------------------------

.spi_init
  lda #SPI_CS
  sta USRP_PORTA                      ; Set high by default
  ; The above also has the effect of setting the clock bit to 0.
  stz USRP_DDRA                       ; Reset to all inputs as default
  lda #(SPI_CLK OR SPI_SDO OR SPI_CS) ; Set these as outputs
  sta USRP_DDRA
  rts

\ ------------------------------------------------------------------------------
\ ---  SPI_TRANSCEIVE
\ ------------------------------------------------------------------------------
\ Going into this function, the SPI_CLK bit is assumed to be 0, so that
\ incrementing USRP_PORTA has the effect of setting the clock line high
\ and decrementing it sets the clock line low.
\ WORKS FOR SPI MODES 0 & 3 - sampling on rising edge
\ ON ENTRY: - Byte to be sent (if any) in A
\ ON EXIT : - Received byte in A
.spi_transceive
  stz SPI_INBUF                       ; Clear input buffer
  sta SPI_OUTBUF                      ; Store outgoing byte
  ldy #8                              ; Counter for loop
  lda #SPI_SDO                        ; Sets A to MOSI bit mask
.spi_transceive_loop
  asl SPI_OUTBUF                      ; Puts msb into Carry flag
  bcs spi_transceive_send1            ; If it's a 1...
  ; TRB (Test and Reset Bits)
  ; Any bit set to 1 in A is set to 0 in memory.
  ; Any bit set to 0 in A have no effect.
  ; A is unaffected.
  ; Also sets Z flag if a bitwise AND of A and memory location would result in
  ; a 0. No other flags affected.
  trb USRP_PORTA                      ; MOSI was high - set it low
  jmp spi_transceive_input
.spi_transceive_send1
  ; TSB (Test and Set Bits) is like a bitwise OR with the accumulator. The
  ; result is stored back in the memory address (USRP_PORTA in this case).
  ; Any bit set to 1 in A is set to 1 in memory.
  ; Any bit set to 0 in A have no effect.
  ; A is unaffected.
  ; Also sets Z flag if a bitwise AND of A and memory location would result in
  ; a 0. No other flags affected.
  tsb USRP_PORTA                  ; Effective OR - sets MOSI high
.spi_transceive_input
  inc USRP_PORTA                  ; Set SPI_CLK high
  bit USRP_PORTA                  ; Put MISO into Overflow flag
  clc                             ; Clear Carry
  bvc spi_transceive_setinbit     ; Test the Overflow flag
  sec                             ; Overflow was set, set Carry
.spi_transceive_setinbit
  rol SPI_INBUF                   ; Rotate Carry flag into receive buffer
  dec USRP_PORTA                  ; Set SPI_CLK low
  dey                             ; Decrement counter
  bne spi_transceive_loop
  lda SPI_INBUF                   ; Put the receive buffer into A
  clc
  rts

;INCLUDE "../../LIB/funcs_math.asm"
;INCLUDE "../../LIB/math_uint16_div.asm"

.start_msg
  equs "SPI Test",0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/TESTB.EXE", header, endcode
