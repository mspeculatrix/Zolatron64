\ ------------------------------------------------------------------------------
\ --- CMD: FLOAD  :  LOAD INTO FLASH MEMORY
\ ------------------------------------------------------------------------------
.cmdprcFLOAD
  ; retrieve a decimal number from STDIN_BUF. Check it's in the range 0-15.
  ; Do this in a way that it can also be called from user software, so that
  ; user software can load additional modules into Flash memory.
  ; Here, we're dealing with user input in the OS. But the actual load
  ; routine should be implemented as an OS call. We can, for example, load
  ; the number for the memory bank into FUNC_PARAM.
  jmp cmdprc_end

.cmdprcFLOAD_fail
  jmp cmdprc_fail

\ ------------------------------------------------------------------------------
\ --- CMD: FSEL  :  SELECT FLASH MEMORY BANK
\ ------------------------------------------------------------------------------
.cmdprcFSEL
  jmp cmdprc_end

  