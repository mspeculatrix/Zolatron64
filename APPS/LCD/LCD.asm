; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i TESTA.asm

CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"
INCLUDE "../../LIB/cfg_user_port.asm"

LCDG_DI  = %00000001 ; PB0 Data/Instruction - H = data, L = instr
LCDG_RW  = %00000010 ; PB1 Read/Write data  - H = read, L = write
LCDG_E   = %00000100 ; PB2 Enable input     - H = enabled
LCDG_CS1 = %00001000 ; PB3 CS for IC1       - active high
LCDG_CS2 = %00010000 ; PB4 CS for IC2       - active high
LCDG_RST = %00100000 ; PB5 Reset            - active low
LCDG_BUSY_FL = %10000000

LCDG_CLS       = %00000001  ; Clear screen & reset display memory
LCDG_TYPE      = %00111000  ; Set 8-bit mode; 2-line display; 5x8 font
LCDG_MODE      = %00001100  ; Display on; cursor off; blink off

MACRO LCDG_SET_CTL ctl_bits        ; set control bits for LCD
  lda USRP_CTRL                  ; load the current state of PORT A
;  and #LED_MASK                   ; clear the top three bits
  ora #ctl_bits                   ; set those bits. Lower 5 bits should be 0s
  sta USRP_CTRL                  ; store result
ENDMACRO

ORG USR_PAGE
.header                     ; HEADER INFO
  jmp startprog             ;
  equw header               ; @ $0803 Entry address
  equw reset                ; @ $0805 Reset address
  equw endcode              ; @ $0807 Addr of first byte after end of program
  equs 0,0,0,0              ; -- Reserved for future use --
  equs "LCD",0            ; @ $080D Short name, max 15 chars - nul terminated
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

; PORTA is Data Port
; PORTB is control port

.main

  lda #$FF
  sta USRP_DDRA
  sta USRP_DDRB

  lda #%00111111
  sta USRP_DATA
  lda USRP_CTRL
  and #%00111111     ; DI & RW low
  sta USRP_CTRL

  


; SETUP LCD display & LEDs




.prog_end
  jmp OSSFTRST


\ ------------------------------------------------------------------------------
\ ---  LCD_CLEAR_SIG
\ ------------------------------------------------------------------------------
\ Clear the RS, RW & E bits on PORT A
.lcdg_clear_sig
  lda USRP_CTRL
  and #%00011111
  sta USRP_CTRL
  rts

\ ------------------------------------------------------------------------------
\ ---  LCDG_CMD
\ ------------------------------------------------------------------------------
\ Send a command to the LCD
\ ON ENTRY: A must contain command byte
.lcdg_cmd
;  pha                              ; preserve A on the stack
  jsr lcdg_wait                      ; check LCD is ready to receive
  sta USRP_DATA                    ; assumes command byte is in A
  jsr lcdg_clear_sig                 ; Clear RS/RW/E bits. Writing to instr reg
  LCDG_SET_CTL LCDG_E                ; Set E bit to send instruction
  jsr lcdg_clear_sig
;  pla
  rts

\ ------------------------------------------------------------------------------
\ ---  LCDG_WAIT
\ ------------------------------------------------------------------------------
\ Wait until LCD is ready to receive next byte. Blocking!
.lcdg_wait         ; Check to see if LCD is ready to receive next byte
  pha             ; Save current contents of A in stack, so it isn't corrupted
  lda #%00000000  ; Set data as input
  sta USRP_DATA_DDR
.lcdg_busy
  LCDG_SET_CTL LCDG_RW
  ora #(LCDG_RW OR LCDG_E)
  sta USRP_CTRL
  lda USRP_DATA
  and #LCDG_BUSY_FL      ; Sets zero flag - non-0 if LCD busy flag set
  bne lcdg_busy            ; If result was non-0, keep looping
  LCDG_SET_CTL LCDG_RW
  lda #%11111111          ; Set data as output
  sta USRP_DATA_DDR
  pla                     ; pull previous A contents back from stack
  rts




.start_msg
  equs "LCD Graphic Panel", 0

.second_msg
  equs "Hello world!", 0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/LCD.BIN", header, endcode
