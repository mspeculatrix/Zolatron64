\ Just for development. Not intended for use in final code

\ This prints messages for the errors returned in an R1 response. This is
\ really for development only, so might want to move this to a '-dev' lib.
.sd_print_R1_errors
  ldx #0
  lda SD_RESP_BUF
  clc
.sd_print_R1_errors_loop
  lsr A                     ; Puts bit 0 into Carry
  bcs sd_print_R1_errors_prt
.sd_print_R1_errors_next
  inx
  cpx #7
  beq sd_print_R1_errors_done
  jmp sd_print_R1_errors_loop
.sd_print_R1_errors_prt
  pha : phx
  txa                             ; Put X index into A
  asl A                           ; Multiply by 2 to get offset
  tax                             ; Move offset back into X
  lda sd_R1_err_ptrs,X    ; Get LSB of relevant address from the cmd_ptrs table
  sta MSG_VEC             ; and put in MSG_VEC
  lda sd_R1_err_ptrs+1,X   ; Get MSB
  sta MSG_VEC+1           ; and put in MSG_VEC high byte
  jsr OSWRMSG             ; Print to console
  plx : pla
  jmp sd_print_R1_errors_next
.sd_print_R1_errors_done
  rts

.sd_print_R1_err
  rts

.sd_R1_err_ptrs
  equw sd_R1_err_msg0
  equw sd_R1_err_msg1
  equw sd_R1_err_msg2
  equw sd_R1_err_msg3
  equw sd_R1_err_msg4
  equw sd_R1_err_msg5
  equw sd_R1_err_msg6

.sd_R1_err_msg0
  equs "SD card idle",10,0
.sd_R1_err_msg1
  equs "Erase reset",10,0
.sd_R1_err_msg2
  equs "Illegal command",10,0
.sd_R1_err_msg3
  equs "CRC error",10,0
.sd_R1_err_msg4
  equs "Erase sequence error",10,0
.sd_R1_err_msg5
  equs "Address error",10,0
.sd_R1_err_msg6
  equs "Parameter error",10,0
