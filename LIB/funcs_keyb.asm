\ KEYBOARD FUNCTIONS -- funcs_keyb.asm -----------------------------------------

\ This assumes there is a keyboard plugged into User Port A, via the
\ keyboard interface.
\ Calling program should also include the config for the User Port:
\ INCLUDE "../../LIB/cfg_user_port.asm"

\ ------------------------------------------------------------------------------
\ ---  KEYB_POLL
\ ------------------------------------------------------------------------------
\ This polls the IRQ_REG register to see if the flag bit for the CA1
\ interrupt has been set. If so, it reads User Port A and returns the value.
\ If not, it returns 0.
\ ON EXIT : - A either contains value of User Port A or 0.
\           - If a value was received, sets Carry
\           - If no value received, clears Carry
\ A: O  -  X: n/a  -  Y: n/a
.keyb_poll
  lda #USRP_INT_CA1           ; Check CA1 flag
  trb IRQ_REG                 ; This both tests and unsets the CA1 flag bit
  bne keyb_poll_getchar
  lda #0                      ; Return 0 if no incoming
  clc                         ; Clear Carry
  jmp keyb_poll_done
.keyb_poll_getchar
  lda USRP_PORTA              ; Load value from User Port
  sec                         ; Set Carry
.keyb_poll_done
  rts

\ ------------------------------------------------------------------------------
\ ---  KEYB_INPUT
\ ------------------------------------------------------------------------------
\ Wrapper to keyb_poll, but instead of returning the character, it
\ inserts it into the STDIN buffer.
\ A: O  -  X: n/a  -  Y: n/a
.keyb_input
  jsr keyb_poll
  beq keyb_input_done       ; If it returns a 0, do nothing
  sta STDIN_BUF
  inc STDIN_IDX
.keyb_input_done
  rts

\ ------------------------------------------------------------------------------
\ ---  KEYB_SETUP
\ ------------------------------------------------------------------------------
\ Configures User Port A as input and to generate an interrupt on a falling
\ edge on CA1.
\ A: O  -  X: n/a  -  Y: n/a
.keyb_setup
  stz USRP_DDRA             ; Set User Port A as all inputs
  lda USRP_IER              ; Load Interrupt Enable Register
  ora #%10000010            ; Enable interrupts for CA1
  sta USRP_IER
  lda USRP_PCR              ; Ensure bit 1 unset to have CA1 cause interrupt on
  and #%11111110            ; falling edge
  sta USRP_PCR
  rts
