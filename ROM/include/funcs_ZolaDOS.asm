\ funcs_ZolaDOS.asm

\ Library for ZolaDOS using a 6522 VIA

\ HOW STREAMING MIGHT WORK:
\ * OSZDOPENR - open file for reading

\ Load A with ZD_OPCODE_OPENR or ZD_OPCODE_OPENW
.zd_fopen
  pha
  \ check for 'file is open' flag. If set, error
  pla
  jsr zd_handshake
  \ check for error. If none, set 'file is open flag'
  rts

.zd_fclose
  \ check for 'file is open' flag
  lda #ZD_OPCODE_CLOSE
  jsr zd_handshake
  \ check for error. If none, unset 'file is open flag'
  rts


\   - check for error
\ * For each block/byte:
\   + Use ZD_INIT_PROCESS with the opcode ZD_OPCODE_RBYTE or ZD_OPCODE_RBLK.
\   + Check return code: 0 = OK, 255 = no more data, anything else is an error.
\     - If OK, run ZD_RCV_DATA
\ * OSZDCLOSE

\ To implement:
\ These all require a file to have been opened and an active file handle.
\  OSZDRBLK                 ; Read block
\  OSZDWBLK                 ; Write block
\  OSZDRBYTE                ; Read byte
\  OSZDWBYTE                ; Write byte
\  OSZDRSTR                 ; Read nul-terminated string
\  OSZDWSTR                 ; Write nul-terminated string

\ ON ENTRY: - FILE_ADDR/+1 must point to next position in memory into which we
\             want to load the data.
\ ON EXIT : - FUNC_ERR contains 0 for OK, 255 for 'end of file' and anything
\             else is an error code.
.zd_read_blk
  lda #ZD_OPCODE_RBLK
  jsr zd_init_process
  lda FUNC_ERR
  bne zd_read_blk_end       ; Non-0 - an error or end of file
  jsr zd_rcv_data          ; Get data
.zd_read_blk_end
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_INIT
\ ------------------------------------------------------------------------------
\ Set up the VIA and other general initialisation.
\ A - O     X - n/a     Y - n/a
.zd_init
  lda #ZD_CTRL_PINDIR               ; Set pin directions
  sta ZD_CTRL_DDR
  lda #ZD_DATA_SET_OUT              ; Set data port to output
  sta ZD_DATA_DDR
  stz ZD_DATA_PORT
  ; Initialise timeout & delay timer - using Timer 1
  lda #%11000000		; Setting bit 7 enables interrupts and bit 6 enables Timer 1
  ZD_SET_CO_ON                      ; Signal to server that Z64 is online.
  sta ZD_IER
  lda #%00000000                    ; Set timer to one-shot mode
  sta ZD_ACR
  stz ZD_TIMER_COUNT		            ; Zero-out counter
  stz ZD_TIMER_COUNT + 1            ; "
  ; Initialise outputs
  ZD_SET_CA_OFF                     ; Takes line high
  ZD_SET_CR_OFF                     ; Takes line high
  lda #ZD_FSTATE_CLOSED             ; Start with no file open
  sta ZD_FSTATE
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_FILELOAD_OK
\ ------------------------------------------------------------------------------
\ Print the appropriate message if file load operation went okay. Also set
\ appropriate value for LOMEM.
\ ON EXIT : LOMEM is set to first free byte above top of program.
\ A - O     X - n/a     Y - n/a
.zd_fileload_ok
  LOAD_MSG file_act_complete_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  lda USR_START+CODEHDR_END    ; Get info about first free byte after prog
  sta LOMEM                    ; to put into our LOMEM variable
  lda USR_START+CODEHDR_END+1
  sta LOMEM + 1
  ; Now we'll set the PROG_END variable
  sta PROG_END + 1             ; Start by assuming high byte same as LOMEM
  lda LOMEM
  bne zd_fileload_ok_cont      ; If low byte wasn't 0
  dec PROG_END + 1             ; If low byte was 0, dec high byte
.zd_fileload_ok_cont
  dec A                        ; Decrement low byte
  sta PROG_END
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_GETFILE
\ ------------------------------------------------------------------------------
\ Get a filename from STDIN_BUF and load the file into memory.
\ Assumes the load address has already been stored in FILE_ADDR(+1).
\ ON ENTRY: The filename must be in STDIN_BUF
\           A should contain 1 to show loading message, 0 to not
\ ON EXIT : FUNC_ERR contains an error code - 0 for success.
\ A - O     X - n/a     Y - n/a
.zd_getfile
  LED_ON LED_FILE_ACT
  jsr read_filename           ; Puts filename in STR_BUF
  lda FUNC_ERR
  bne zd_getfile_done
  LOAD_MSG loading_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  lda #ZD_OPCODE_LOAD         ; Use opcode for loading .EXE files
  jsr zd_loadfile
.zd_getfile_done
  LED_OFF LED_FILE_ACT
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_INIT_PROCESS
\ ------------------------------------------------------------------------------
\ When intiating a specific process, this provides the first communication with
\ the RPi, sending a code designating which action is required.
\ ON ENTRY: The relevant opcode must be in A.
\ ON EXIT : FUNC_ERR contains an error code - 0 for success.
\ A - P     X - n/a     Y - n/a
.zd_init_process
  pha
  lda #ZD_DATA_SET_OUT
  sta ZD_DATA_DDR
  lda ZD_CTRL_PORT
  ora #ZD_DDIR_OUTPUT
  sta ZD_CTRL_PORT
  lda ZD_CTRL_PORT
  and #ZD_CA_ON
  sta ZD_CTRL_PORT
  pla
  sta ZD_DATA_PORT
  jsr zd_signalDelay          ; Slight pause to ensure data loaded
  ZD_SET_CR_ON                ; Take /CR low - signals that we're ready to rock
  jsr zd_signalDelay          ; Slight pause to settle down
  jsr zd_waitForSR            ; Wait for server's response
;  lda FUNC_ERR
  ZD_SET_CR_OFF               ; Take /CR high
  ZD_SET_CA_OFF               ; Take /CA high
.zd_svr_resp_init_end
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_DELFILE
\ ---  Implements: OSZDDEL
\ ------------------------------------------------------------------------------
\ Deletes a file on the ZolaDOS server.
\ ON ENTRY: STR_BUF must contain filename
\ ON EXIT : FUNC_ERR contains error code - 0 for success
\ A - O     X - n/a     Y - n/a
.zd_delfile
  lda #ZD_OPCODE_DEL
  jsr zd_handshake
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_HANDSHAKE
\ ------------------------------------------------------------------------------
\ The handshake consists of the following steps:
\   1. Send a code to the ZD server saying what operation we want to perform.
\   2. Send a filename (or other string) to the server.
\   3. Receive back a code - potentially an error code or 0 for OK.
\ ON ENTRY: - A must contain opcode we want to send to server.
\           - STR_BUF must contain a string such as a filename
\ ON EXIT : - FUNC_ERR contains error code - 0 for success
\ A - O     X - n/a     Y - n/a
.zd_handshake
  stz FUNC_ERR                ; Zero out the error code
  stz FUNC_RESULT             ; This is where we'll store the server's response
  jsr zd_init_process         ; Tell ZolaDOS device we want to perform a process
  lda FUNC_ERR
  bne zd_handshake_end        ; If this is anything but 0, that's an error
  jsr zd_send_strbuf          ; Send the string over the ZolaDOS port
  lda FUNC_ERR                ; Anything but 0 in FUNC_ERR is an error
  bne zd_handshake_end
  ZD_SET_DATADIR_INPUT        ; ----- SERVER RESPONSE --------------------------
  jsr zd_svr_resp
.zd_handshake_end
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_LOADFILE
\ ---  Implements: OSZDLOAD
\ ------------------------------------------------------------------------------
\ Loads a file into memory.
\ ON ENTRY: - A must contain ZD OPCODE - eg, #ZD_OPCODE_LOAD, #ZD_OPCODE_XLOAD
\           - STR_BUF must contain filename
\           - FILE_ADDR/+1 must contain address to which we wish to load file.
\ ON EXIT : FUNC_ERR is 0 for success, something else for an error.
\ A - O     X - n/a     Y - n/a
.zd_loadfile
  jsr zd_handshake            ; ----- INITIATE ---------------------------------
  lda FUNC_ERR
  bne zd_loadf_end            ; If this is anything but 0, that's an error
.zd_loadf_rcv_data            ; ----- TRANSFER DATA ----------------------------
  jsr zd_waitForSAoff
  lda FUNC_ERR
  bne zd_loadf_end
  jsr zd_rcv_data
.zd_loadf_end
  ZD_SET_CA_OFF
  ZD_SET_CR_OFF
  ZD_SET_DATADIR_OUTPUT
  rts

\ ---  ZD_OPEN_FILE
.zd_open_file
\ ON ENTRY: - A must contain ZD OPCODE - eg, #ZD_OPCODE_OPENR
\           - STR_BUF must contain filename
\           - FILE_ADDR/+1 must contain address to which we wish to load file.
  jsr zd_handshake            ; ----- INITIATE ---------------------------------
  lda FUNC_ERR
  bne zd_openf_end            ; If this is anything but 0, that's an error
.zd_openf_end
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_RCV_DATA
\ ------------------------------------------------------------------------------
\ This receives data from the server and stores it starting at the address
\ specified by FILE_ADDR. The process is:
\   * Wait for Server Active signal (low).
\   * LOOP:
\     + Wait for Server Ready signal active (low).
\     + Load byte on bus.
\     + Store byte in memory.
\     + Wait for Server Ready signal inactive.
\     + Send Client Ready strobe.
\     + Check if Server Active is still set:
\       - If so, LOOP
\       - Otherwise done.
\ ON ENTRY: FILE_ADDR/+1 must contain the 16-bit address
\           for where to store the data.
\ ON EXIT : FUNC_ERR contains an error code - 0 for success.
\ A - O     X - n/a     Y - n/a
.zd_rcv_data
  jsr zd_waitForSA            ; Wait for /SA signal to go low
  lda FUNC_ERR
  bne zd_rcv_data_end         ; If this is anything but 0, that's an error
.zd_rcv_data_loop             ; READ LOOP
  jsr zd_waitForSR            ; Wait for server to say there's a byte ready
  lda FUNC_ERR
  bne zd_rcv_data_chkSA       ; If not 0, might be error or loading complete
  lda ZD_DATA_PORT            ; Read byte on data bus
  sta (FILE_ADDR)             ; Store byte
  inc FILE_ADDR               ; Increment address low byte
  bne zd_rcv_data_loop_cont   ; If it didn't roll over to 0, carry on...
  inc FILE_ADDR + 1           ; Otherwise, increment high byte
.zd_rcv_data_loop_cont
  jsr zd_waitForSRoff         ; Wait for /SR to go high again
  ZD_SET_CR_ON                ; Strobe /CR line
  jsr zd_strobeDelay          ; "
  ZD_SET_CR_OFF               ; "
  lda ZD_CTRL_PORT            ; Check if /SA still low
  and #ZD_SA_MASK             ; If /SA is still low, this returns 0
  bne zd_rcv_data_end         ; If not 0, then we're done, otherwise...
  jmp zd_rcv_data_loop        ; Go around for the next byte
.zd_rcv_data_chkSA
  jsr zd_strobeDelay
  jsr zd_waitForSAoff         ; Returns 0 if no error
.zd_rcv_data_end
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_SAVE_DATA
\ ---  Implements: OSZDSAVE
\ ------------------------------------------------------------------------------
\ Saves a section of memory to a file.
\ ON ENTRY: - A must contain the save type opcode - eg, #ZD_OPCODE_SAVE_CRT
\           - TMP_ADDR_A must contain 16-bit start address
\           - TMP_ADDR_B must contain end address
\           - STR_BUF must contain nul-terminated filename string
\ ON EXIT : FUNC_ERR contains error code
\ A - O     X - n/a     Y - n/a
.zd_save_data
  jsr zd_handshake
  lda FUNC_ERR
  bne zd_save_data_end
  jsr zd_waitForSAoff
  lda FUNC_ERR
  bne zd_save_data_end
  ; might need a pause here
  jsr zd_strobeDelay
  jsr zd_send_data            ; ----- SEND DATA ----------------------
.zd_save_data_end
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_SEND_DATA
\ ------------------------------------------------------------------------------
\ A - O     X - n/a     Y - n/a
.zd_send_data
  ZD_SET_CR_OFF               ; Not sure if needed - but to be sure
  ZD_SET_DATADIR_OUTPUT
  ZD_SET_CA_ON
  jsr zd_waitForSRoff         ; Wait for server response to end
  lda FUNC_ERR
  bne zd_send_data_end
.zd_send_data_loop
  lda (TMP_ADDR_A)            ; Put byte on data bus
  sta ZD_DATA_PORT
  ZD_SET_CR_ON                ; Signal that it's ready
  jsr zd_strobeDelay
  ZD_SET_CR_OFF
  jsr zd_waitForSR            ; Wait for server response
  lda FUNC_ERR
  bne zd_send_data_end
  jsr zd_waitForSRoff         ; Wait for server response to end
  lda FUNC_ERR
  bne zd_send_data_end
  jsr compare_addr        ; Check if we've reached the end
  lda FUNC_RESULT
  cmp #EQUAL
  beq zd_send_data_end        ; If equal, we're done
  cmp #MORE_THAN
  beq zd_send_data_bounds_err
  inc TMP_ADDR_A_L            ; Otherwise, increment address low byte
  bne zd_send_data_next       ; If it didn't roll over, got to next step
  inc TMP_ADDR_A_H            ; Otherwise increment high byte
.zd_send_data_next
  jmp zd_send_data_loop
.zd_send_data_bounds_err
  lda #ERR_FILE_BOUNDS
  sta FUNC_ERR
.zd_send_data_end
  ZD_SET_CA_OFF
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_SEND_STRBUF
\ ------------------------------------------------------------------------------
\ Send the contents of STR_BUF via the ZD data port. This feels like it might
\ want to grow up to be an OS call someday.
\ This can be used for sending things like a filename (the read_filename
\ function puts the filename into STR_BUF).
\ ON ENTRY: The data needs to be in STR_BUF with a null terminator.
\ ON EXIT : FUNC_ERR contains an error code - 0 for success.
\ A - O     X - O     Y - n/a
.zd_send_strbuf
  ldx #0                      ; Offset for STR_BUF
  ZD_SET_CA_ON                ; Take /CA low
  stz FUNC_ERR                ; Set result to 0
.zd_sendstrbuf_next_chr
  jsr zd_waitForSRoff         ; NOT SURE ABOUT THIS !!!
  lda FUNC_ERR                ; *** MAYBE REMOVE THESE THREE LINES ??? ***
  bne zd_sendstrbuf_end       ; OR MOVE TO LATER IN THE LOOP ????
  lda STR_BUF,X
  beq zd_sendstrbuf_end       ; Got a null byte so we're done
  inx
  sta ZD_DATA_PORT            ; Put byte on data bus
  ZD_SET_CR_ON                ; Take /CR low - signals that we're ready to rock
  jsr zd_signalDelay          ; Slight pause to settle down
  jsr zd_waitForSR            ; Wait for server response - might need long wait
  lda FUNC_ERR
  bne zd_sendstrbuf_end
  ZD_SET_CR_OFF
  ; MAYBE DO WAIT FOR SR OFF HERE INSTEAD
  jmp zd_sendstrbuf_next_chr
.zd_sendstrbuf_end
  ZD_SET_CA_OFF
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_SIGNALDELAY
\ ------------------------------------------------------------------------------
\ Pause to allow signals to stabilise
\ A - O     X - n/a     Y - n/a
.zd_signalDelay
  lda #%11000000		; Setting bit 7 enables interrupts and bit 6 enables Timer 1
  sta ZD_IER
  lda #%00000000                    ; set timer to one-shot mode
  sta ZD_ACR
  lda #<ZD_SIGNALDELAY              ; Set timer delay
  sta ZD_T1CL
  lda #>ZD_SIGNALDELAY
  sta ZD_T1CH		                    ; Starts timer
.zd_signalDelay_loop
  nop
  bit ZD_IFR                        ; Bit 6 copied to overflow flag
  bvc zd_signalDelay_loop           ; If clear, interrupt bit not set, so loop
  lda ZD_T1CL                       ; Clears interrupt flag
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_STREAMIN *** UNDER CONSTRUCTION ***
\ ---  Implements: OSZDSTRIN (to be added)
\ ------------------------------------------------------------------------------
\ Stream in a file from storage in ZD_STREAM_SZ size chunks.
\ ON ENTRY: - FILE_ADDR/+1 must contain address for where we're going to buffer
\             the data.
\           - STR_BUF must contain filename
\ ON EXIT : FUNC_ERR is 0 for success, something else for an error.
.zd_streamin
  lda #ZD_OPCODE_OPENR
  jsr zd_handshake            ; ----- INITIATE ---------------------------------
  lda FUNC_ERR
  bne zd_streamin_end         ; If this is anything but 0, that's an error

  lda #ZD_FSTATE_OPENR
  sta ZD_FSTATE

.zd_streamin_close
  lda #ZD_OPCODE_CLOSE
  jsr zd_init_process
  lda FUNC_ERR
  ;  deal with error
  lda #ZD_FSTATE_CLOSED
  sta ZD_FSTATE
.zd_streamin_end
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_STROBEDELAY
\ ------------------------------------------------------------------------------
\ A - O     X - n/a     Y - n/a
.zd_strobeDelay
  lda #%11000000		; Setting bit 7 enables interrupts and bit 6 enables Timer 1
  sta ZD_IER
  lda #%00000000                    ; Set timer to one-shot mode
  sta ZD_ACR
  lda #<ZD_STROBETIME               ; Set timer delay
  sta ZD_T1CL
  lda #>ZD_STROBETIME
  sta ZD_T1CH		                    ; Starts timer
.zd_strobeDelay_loop
  nop
  bit ZD_IFR                        ; Bit 6 copied to overflow flag
  bvc zd_strobeDelay_loop           ; If clear, interrupt bit not set, so loop
  lda ZD_T1CL                       ; Clears interrupt flag
  rts

\ ------------------------------------------------------------------------------
\ ---  ZD_SVR_RESP
\ ------------------------------------------------------------------------------
\ Get a response code from the server. It's actually looking for an error code,
\ which is why we're storing the result in FUNC_ERR. If it returns a 0, that
\ means no error.
\ ON ENTRY: Must have set the appropriate data direction on the data port -
\           eg, with the macro ZD_SET_DATADIR_INPUT.
\ ON EXIT : FUNC_ERR contains an error code - 0 for success.
\ A - O     X - O     Y - n/a
.zd_svr_resp
  ldx #128                    ; For longer timeout counter
.zd_svr_resp_SA_waitloop
  jsr zd_waitForSA            ; Wait for server's response - extended wait
  lda FUNC_ERR
  beq zd_svr_resp_nextwait
  dex
  bne zd_svr_resp_SA_waitloop
  jmp zd_svr_resp_svr_end     ; If this is anything but 0, that's an error
.zd_svr_resp_nextwait
  ZD_SET_CR_ON                ; Take /CR low
  jsr zd_waitForSR            ; Wait for server's response
  lda FUNC_ERR
  bne zd_svr_resp_svr_end     ; If this is anything but 0, that's an error
  lda ZD_DATA_PORT            ; Read code
  bne zd_svr_resp_resp_err    ; Anything but 0 is an error
  ZD_SET_CR_OFF
  jmp zd_svr_resp_svr_end
.zd_svr_resp_resp_err
  sta FUNC_ERR                ; Store error code from server
.zd_svr_resp_svr_end
  rts

\ ------------------------------------------------------------------------------
\ ---  TIMER FUNCTIONS
\ ------------------------------------------------------------------------------
\ Check to see if the counter has incremented
\ A - P     X - n/a     Y - n/a
.zd_chk_timer
  sei                           ; to the same value as the set limit. This is
  pha                           ; basically a standard 16-bit comparison.
  lda ZD_TIMER_COUNT + 1        ; compare the high bytes first as if they aren't
  cmp #>ZD_TIMEOUT_LIMIT        ; equal, we don't need to compare the low bytes
  bcc zd_chk_timer_less_than    ; count is less than limit
  bne zd_chk_timer_more_than    ; count is more than limit
  lda ZD_TIMER_COUNT            ; high bytes were equal - what about low bytes?
  cmp #<ZD_TIMEOUT_LIMIT
  bcc zd_chk_timer_less_than
  bne zd_chk_timer_more_than
  lda #EQUAL				            ; COUNT = LIMIT - this what we're looking for.
  jmp zd_chk_timer_end
.zd_chk_timer_less_than
  lda #LESS_THAN			          ; COUNT < LIMIT - counter isn't big enough yet
  jmp zd_chk_timer_end          ; so let's bug out.
.zd_chk_timer_more_than
  lda #MORE_THAN			          ; COUNT > LIMIT - shouldn't happen, but still...
.zd_chk_timer_end
  sta FUNC_RESULT
  pla
  cli
  rts

\ Stop timer running
\ A - O     X - n/a     Y - n/a
.zd_timer1_stop
  lda ZD_IER
  and #%10111111	; Setting bit 7 enables interrupts and bit 6 disables Timer 1
  sta ZD_IER
  rts

\ Start timeout timer
\ A - O     X - n/a     Y - n/a
.zd_timeout_timer_start
  stz ZD_TIMER_COUNT
  stz ZD_TIMER_COUNT + 1
  lda #%11000000		; setting bit 7 enables interrupts and bit 6 enables Timer 1
  sta ZD_IER
  lda #%01000000                    ; set timer to free-run mode
  sta ZD_ACR
  lda #>ZD_TIMEOUT_INTVL
  sta ZD_T1CL
  lda #<ZD_TIMEOUT_INTVL
  sta ZD_T1CH                       ; Starts timer
  rts

\ ------------------------------------------------------------------------------
\ --- FLOW CONTROL FUNCTIONS
\ ------------------------------------------------------------------------------
\ A - P     X - P      Y - n/a
.zd_waitForSA
  pha : phx
  jsr zd_timeout_timer_start
  ldx #0                            ; Using this for return result
.zd_waitForSA_loop
  lda ZD_CTRL_PORT
  and #ZD_SA_MASK                   ; SA signal is active LOW
  beq zd_waitForSA_end              ; The SA bit is set LOW, so we're all good
  jsr zd_chk_timer                  ; Result is in FUNC_RESULT
  lda FUNC_RESULT
  ;cmp #LESS_THAN
  beq zd_waitForSA_loop
  ldx #FREAD_TO_SA                  ; We timed out - error code
.zd_waitForSA_end
  stx FUNC_ERR
  jsr zd_timer1_stop
  plx : pla
  rts

\ A - P     X - P     Y - n/a
.zd_waitForSAoff
  pha : phx
  jsr zd_timeout_timer_start
  ldx #0                            ; Using this for return result
.zd_waitForSAoff_loop
  lda ZD_CTRL_PORT
  and #ZD_SA_MASK                   ; SA signal is active LOW
  bne zd_waitForSAoff_end           ; The SA bit is set LOW, so we're all good
  jsr zd_chk_timer                  ; Result is in FUNC_RESULT
  lda FUNC_RESULT
  ;cmp #LESS_THAN
  beq zd_waitForSAoff_loop
  ldx #FREAD_TO_SAO                  ; We timed out - error code
.zd_waitForSAoff_end
  stx FUNC_ERR
  jsr zd_timer1_stop
  plx : pla
  rts

\ A - P     X - P     Y - n/a
.zd_waitForSR
  pha : phx
  jsr zd_timeout_timer_start
  ldx #0                            ; Using this for return result
.zd_waitForSR_loop
  lda ZD_CTRL_PORT
  and #ZD_SR_MASK                   ; SR signal is active LOW
  beq zd_waitForSR_end              ; The SR bit is set LOW, so we're all good
  jsr zd_chk_timer                  ; Result is in FUNC_RESULT
  lda FUNC_RESULT
  beq zd_waitForSR_loop
  ldx #FREAD_TO_SR                  ; We timed out - error code
.zd_waitForSR_end
  stx FUNC_ERR
  jsr zd_timer1_stop
  plx : pla
  rts

\ A - P     X - P     Y - n/a
.zd_waitForSRoff
  pha : phx
  jsr zd_timeout_timer_start
  ldx #0                            ; Using this for return result
.zd_waitForSRoff_loop
  lda ZD_CTRL_PORT
  and #ZD_SR_MASK                   ; SR signal is active LOW
  bne zd_waitForSR_end              ; The SR bit is set HIGH, so we're all good
  jsr zd_chk_timer                  ; Result is in FUNC_RESULT
  lda FUNC_RESULT
  beq zd_waitForSRoff_loop
  ldx #FREAD_TO_SRO                 ; We timed out - error code
.zd_waitForSRoff_end
  stx FUNC_ERR
  jsr zd_timer1_stop
  plx : pla
  rts

\ --- DATA ---------------------------------------------------------------------
.deleting_msg
  equs "Deleting ... ",0
.loading_msg
  equs "Loading ... ",0
.searching_msg
  equs "Searching ... ",0
.saving_msg
  equs "Saving ... ",0
.file_act_complete_msg
  equs "OK",0
