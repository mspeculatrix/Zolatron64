_For A, X and Y columns_: **O** = overwritten, P = preserved, – = not affected or not applicable.
 

NB: These apply only to the top-level functions. Any sub-routines called from within them may affect A, X or Y.

|     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- |
| **OS Function** | **Source file & function** | **On Entry** | **On Exit / Notes** | **A** | **X** | **Y** |
| **Read** |     |     |     |     |     |     |
| **OSGETINP**<br><br>Creates an input loop waiting for the null received flag to be set | funcs\_io.asm<br><br>get\_input | Resets STDIN\_IDX to 0.  <br>Sets first byte of STDIN\_BUF to 0. | Clears the null received flag. |     |     |     |
| **OSGETKEY**<br><br>Get a single character from STDIN\_BUF | funcs\_io.asm<br><br>getkey | Resets STDIN\_IDX to 0. | Key ASCII code in FUNC\_RESULT.  <br> <br><br>0 means just <return> was entered.<br><br>STDIN\_IDX and STDIN\_BUF are reset. | **O** | –   | –   |
| **OSRDASC**<br><br>Wrapper to OSRDBYTE. Reads next _printable_ char (including space) from STDIN\_BUF | funcs\_io.asm<br><br>read\_ascii | Uses STDIN\_IDX to get next char. | FUNC\_RESULT contains char code.<br><br>FUNC\_ERR contains error code.<br><br>STDIN\_IDX updated.<br><br>STDIN\_BUF not affected. | **O** | **O** | –   |
| **OSRDBYTE**<br><br>Reads next byte from STDIN\_BUF | funcs\_io.asm  <br> <br><br>read\_byte | Uses STDIN\_IDX to get next char. | FUNC\_RESULT contains char code.<br><br>FUNC\_ERR contains error code.<br><br>STDIN\_IDX updated.<br><br>STDIN\_BUF not affected. | **O** | **O** | –   |
| **OSRDHBYTE**<br><br>Reads 2 ASCII chars from STDIN\_BUF and converts to 16-bit value. | funcs\_io.asm  <br> <br><br>read\_hex\_byte | Uses STDIN\_IDX to get next char.<br><br>Expects pair of ASCII chars in STDIN\_BUF | FUNC\_RESULT contains value.<br><br>FUNC\_ERR contains error code. | P   | P   | P   |
| **OSRDHADDR** | funcs\_io.asm  <br> <br><br>read\_hex\_addr | Expects nul- or space-terminated string of ASCII hex characters in STDIN\_BUF.<br><br>Uses OSRDHBYTE to get each pair of chars & convert to value. | FUNC\_RES\_L/H contain 16-bit value.<br><br>FUNC\_ERR contains last error raised by OSRDHBYTE | P   | –   | P   |
| **OSRDCH**<br><br>Wrapper to OSRDBYTE. Reads next _non-space_ printable char from STDIN\_BUF | funcs\_io.asm  <br> <br><br>read\_char | Uses STDIN\_IDX to get next char. | FUNC\_RESULT contains char code.<br><br>FUNC\_ERR contains error code.<br><br>STDIN\_IDX updated.<br><br>STDIN\_BUF not affected. | **O** | **O** | –   |
| **OSRDINT16**<br><br>Read a 16-bit decimal integer from STDIN\_BUF | funcs\_io.asm  <br> <br><br>read\_int16 | Uses STDIN\_IDX to get next char. | FUNC\_RES\_L/H contain 16-bit number.<br><br>FUNC\_ERR contains error code.<br><br>STDIN\_IDX updated.<br><br>STDIN\_BUF not affected. | P   | P   | P   |
| **OSRDFNAME**<br><br>Reads string from STDIN\_BUF. Checks conforms to filename specs. | funcs\_io.asm  <br> <br><br>read\_filename | Assumes next data in STDIN\_BUF pointed to by STDIN\_IDX is a filename. | STR\_BUF contains nul-terminated filename.<br><br>FUNC\_ERR contains error code.<br><br>STDIN\_IDX updated. | P   | P   | P   |
| **OSRDSTR**  <br> <br><br>Reads string from STDIN\_BUF | funcs\_io.asm  <br> <br><br>read\_string | Assumes next data in STDIN\_BUF pointed to by STDIN\_IDX is a filename. | STR\_BUF contains nul-terminated string.<br><br>FUNC\_ERR contains error code.<br><br>STDIN\_IDX updated. | P   | P   | P   |
| **Write** |     |     |     |     |     |     |
| **OSWRBUF**<br><br>Write STDOUT\_BUF to output stream |     | STDOUT\_BUF must contain null-terminated stream of characters. |     | _**O**_ | _**O**_ | _**–**_ |
| **OSWRCH**<br><br>Write single character to output stream |     | A contains ASCII value of character. |     | –   | –   | –   |
| **OSWRERR**<br><br>Write OS error string to output stream | funcs\_io.asm  <br> <br><br>os\_print\_error | The error code must be in FUNC\_ERR |     | **O** | **O** | –   |
| **OSWRMSG**<br><br>Write text pointed to by MSG\_VEC to output stream |     | MSG\_VEC and MSG\_VEC+1 must contain address of a null-terminated message string. |     | P   | –   | P   |
| **OSWROP**<br><br>Write to Output Port on DUART board | funcs\_uart\_sc28L92.asm<br><br>duart\_writeOP | A contains value (0 or 1) to be set on pin.  <br> <br><br>X contains pin number constant – eg, SC28L92\_OP2 |     | P   | P   | –   |
| **OSWRSBUF**<br><br>Write STR\_BUF to output stream |     | STR\_BUF must contain a nul-terminated string. |     | P   | –   | –   |
| **OSSOAPP**<br><br>Append string to STDOUT\_BUF | funcs\_io.asm  <br> <br><br>stdout\_append | Assumes STDOUT\_IDX points to next char in buffer.  <br> <br><br>MSG\_VEC/+1 must point to the string | FUNC\_ERR contains err code. 0 = success.<br><br>STDOUT\_IDX updated | **O** | P   | P   |
| **OSSOCH**  <br> <br><br>Append character to STDOUT\_BUF | funcs\_io.asm<br><br>stdout\_add\_char | ASCII character code in A. | STDOUT\_IDX updated | P   | P   | –   |
| **Conversions** |     |     |     |     |     |     |
| **OSB2BIN**<br><br>Converts 8-bit value to 2-char hex string representation | funcs\_conv.asm  <br> <br><br>byte\_to\_bin | A must contain value to be converted. | STR\_BUF contains 9 bytes containing binary characters plus nul terminator | **O** | P   | P   |
| **OSB2HEX**<br><br>Converts 8-bit value to 2-char hex string representation | funcs\_conv.asm  <br> <br><br>byte\_to\_hex\_str | A must contain value to be converted. | STR\_BUF contains 3 bytes containing hex characters plus nul terminator | **O** | –   | –   |
| **OSB2ISTR**  <br> <br><br>Converts 8-bit value to decimal integer string representation | funcs\_conv.asm  <br> <br><br>byte\_to\_int\_str | A must contain value to be converted. | STR\_BUF contains integer string plus nul terminator<br><br>FUNC\_RESULT contains number of digits (not including null terminator) | P   | P   | P   |
| **OSHEX2B**<br><br>Converts 2-char hex string to byte value | funcs\_conv.asm  <br> <br><br>hex\_str\_to\_byte | BYTE\_CONV\_L/H must contain ASCII hex codes for low/high nibbles. | FUNC\_RESULT contains byte value<br><br>FUNC\_ERR contains error code generated by OSHEX2DEC | P   | P   | –   |
| **OSU16ISTR**<br><br>Converts a 16-bit value to a decimal string | funcs\_conv.asm<br><br>uint16\_to\_int\_str | MATH\_TMP\_A\_L/H contains 16-bit value | STR\_BUF contains nul-terminated decimal string | P   | P   | P   |
| **OSU16HEX**<br><br>Converts a 16-bit value to a 4-char hex string | funcs\_conv.asm  <br> <br><br>uint16\_to\_hex\_str | TMP\_ADDR\_A\_L/H contains 16-bit value | STR\_BUF contains nul-terminated hex string | P   | –   | –   |
| **OSHEX2DEC**<br><br>Converts 1-byte integer representing a hex char (ie, '0' to 'F') to integer value (0-15) | funcs\_conv.asm  <br> <br><br>asc\_hex\_to\_dec | A contains ASCI character value | A contains numeric value<br><br>FUNC\_ERR contains error code | **O** | P   | –   |
| **LCD** |     |     |     |     |     |     |
| **OSLCDCH**<br><br>LCD write char |     | A contains ASCII value of character |     | P   | –   | –   |
| **OSLCDCLS**<br><br>LCD clear screen |     |     |     | **O** | –   | –   |
| **OSLCDERR**<br><br>LCD write OS error string |     | FUNC\_ERR is assumed to contain an error code |     | **O** | **O** | –   |
| **OSLCDMSG**<br><br>LCD write text pointed to by MSG\_VEC |     | MSG\_VEC and MSG\_VEC+1 must contain address of a null-terminated message string. |     | P   | P   | P   |
| **OSLCDB2HEX**<br><br>Print byte value as hex |     | A must contain byte value | Uses STR\_BUF as temporary store | **O** | –   | –   |
| **OSLCDSBUF**  <br> <br><br>Print contents of STR\_BUF to LCD |     | STR\_BUF must contain a nul-terminated string. |     | **O** | –   | –   |
| **OSLCDSC**<br><br>LCD Set Cursor |     | X should contain the X param in range 0-15.<br><br>Y should be 0 or 1. |     | **O** | –   | **O** |
| **OSLCDWRBUF**<br><br>Write STDOUT\_BUF to LCD |     | STDOUT\_BUF must contain a nul-terminated string. |     | **O** | –   | –   |
| **Parallel/Printer** |     |     |     |     |     |     |
| **OSPRTBUF**<br><br>Print contents of STDOUT\_BUF | funcs\_prt.asm<br><br>prt\_stdout\_buf | STDOUT\_BUF should contain a nul-terminated string. Calls OSPRTMSG. | FUNC\_RESULT will contain a result code<br><br>Wrapper to OSPRTMSG<br><br>A is overwritten | **O** | –   | –   |
| **OSPRTCH**<br><br>Print character | funcs\_prt.asm<br><br>prt\_char | A must contain ASCII char code. |     | **O** | –   | –   |
| **OSPRTCHK**<br><br>Check printer state | funcs\_prt.asm  <br> <br><br>prt\_check\_state |     | FUNC\_RESULT contains one of following error codes:  <br> <br><br>0 (available/no error)  <br> <br><br>ERR\_PRT\_STATE\_OL<br><br>ERR\_PRT\_STATE\_PE<br><br>ERR\_PRT\_STATE\_ERR | **O** | –   | P   |
| **OSPRTINIT**<br><br>Initialise the printer VIA | funcs\_prt.asm<br><br>prt\_init |     |     | **O** | –   | –   |
| **OSPRTMSG**<br><br>Print string pointed to by MSG\_VEC | funcs\_prt.asm<br><br>prt\_msg | MSG\_VEC/+1 should contain pointer to a nul-terminated string | FUNC\_RESULT will contain a result code | **O** | –   | **O** |
| **OSPRTSBUF**<br><br>Print contents of STR\_BUF | funcs\_prt.asm<br><br>prt\_str\_buf | STR\_BUF should contain a nul-terminated string. Calls OSPRTMSG. | FUNC\_RESULT will contain a result code<br><br>Wrapper to OSPRTMSG | **O** | –   | –   |
|     |     |     |     |     |     |     |
| **ZolaDOS** |     |     |     |     |     |     |
| **OSZDDEL**<br><br>Delete a file on the ZolaDOS server. | funcs\_ZolaDOS<br><br>zd\_delfile | STR\_BUF must contain nul-terminated filename | FUNC\_ERR contains error code (0 if successful). | **O** | –   | –   |
| **OSZDLOAD**<br><br>Load a file from the ZolaDOS server into memory at USR\_START | funcs\_ZolaDOS<br><br>zd\_loadfile | STR\_BUF must contain nul-terminated filename<br><br>FILE\_ADDR/+1 must contain address to which data will be loaded | FUNC\_ERR contains error code (0 if successful).<br><br>LOMEM is set. | **O** | –   | –   |
| **OSZDSAVE**<br><br>Save a block of memory to a file. | funcs\_ZolaDOS<br><br>zd\_save\_data | TMP\_ADDR\_A/+1 must contain start address of memory<br><br>TMP\_ADDR\_B/+1 must contain end address of memory<br><br>STR\_BUF must contain nul-terminated filename | FUNC\_ERR contains error code (0 if successful). | **O** | –   | –   |
| **MISC** |     |     |     |     |     |     |
| **OSDELAY**<br><br>General-purpose delay function. Blocking | funcs\_4x20\_lcd.asm<br><br>delay | LCDV\_TIMER\_INTVL/+1 contains 16-bit delay value (in ms) |     | P   | –   | –   |
| **OSUSRINT**  <br> <br><br>For vectoring user-program interrupts |     | \-- to come -- |     |     |     |     |
| **SPI** |     |     |     |     |     |     |
| **OSSPIEXCH**  <br> <br><br>Performs an SPI byte exchange | funcs\_spi65  <br> <br><br>spi\_exchange\_byte | **A** contains byte to be sent | **A** contains byte received | **O** | –   | –   |
| **OSRDDATE**<br><br>Read date from RTC |     |     | Date data starting at RTC\_DAT\_BUF |     |     |     |
| **OSRDTIME**<br><br>Read time from RTC |     |     | Time data starting at RTC\_CLK\_BUF |     |     |     |
|     |     |     |     |     |     |     |
| **OSSFTRST**<br><br>Soft reset |     | \-- | Use direct JMP (not JSR or vectored/indirect) | –   | –   | –   |
| **OSHRDRST**<br><br>Hard reset |     | \-- | Use direct JMP (not JSR or vectored/indirect) | –   | –   | –   |
|     |     |     |     |     |     |     |