# ZolOS OS Function Calls

JSR addresses are the locations of the jump instructions. To call an OS function, you JSR to this address.

FUNC ADDR addresses are the start addressed of the actual function code.

| OS FUNCTION | JSR | FUNC ADDR | Comment |
|---|:---:|:---:|---|
| OSB2BIN | FF36 | DA12 | 1-byte integer value to a binary string |
| OSB2HEX | FF39 | DA35 | 8-bit value to 2-char hex string |
| OSB2ISTR | FF3C | DA54 | 8-bit value to decimal integer string |
| OSDELAY | FF81 | E0FF | General-purpose delay function. Blocking |
| OSGETINP | FF03 | DC73 | Create input loop |
| OSGETKEY | FF00 | DC96 | Get char, waits for user to enter a key & return |
| OSHEX2B | FF3F | DA91 | 2-char hex string to byte value |
| OSHEX2DEC | FF48 | DABD | 1-byte char (ie, '0' to 'F') to int (0-15) |
| OSHRDRST | FFF7 |  | Hard reset - use JMP (not JSR) |
| OSLCDB2HEX | FF5A | E01E | Print byte value as hex |
| OSLCDCH | FF4E | E0B1 | Write char |
| OSLCDCLS | FF51 | DFF4 | Clear screen |
| OSLCDERR | FF54 | E0D8 | Write OS error string |
| OSLCDINIT | FF4B | DFFD | Initialise LCD |
| OSLCDMSG | FF57 | E04A | Write text pointed to by MSG_VEC |
| OSLCDSBUF | FF5D | E03C | Print contents of STR_BUF |
| OSLCDSC | FF60 | E0EB | Set cursor |
| OSLCDWRBUF | FF63 | E02E | Write STDOUT_BUF |
| OSPRTBUF | FF66 | E24A | Print contents of STDOUT_BUF |
| OSPRTCH | FF69 | E15D | Print character |
| OSPRTCHK | FF6C | E1C2 | Check printer state, set flags |
| OSPRTINIT | FF6F | E1EB | Initialise the printer VIA |
| OSPRTMSG | FF72 |  | Print string pointed to by MSG_VEC |
| OSPRTSBUF | FF75 | E256 | Print contents of STR_BUF |
| OSRDASC | FF06 | DCB6 | Get next printable char from STDIN_BUF |
| OSRDBYTE | FF09 | DCC8 | Read next byte from STDIN_BUF |
| OSRDCH | FF0C | DCEE | Get next non-space printable char from STDIN_BUF |
| OSRDDATE | FF87 | E3F7 | Read date from RTC |
| OSRDFNAME | FF18 | DD8A | Read string from STDIN_BUF |
| OSRDHADDR | FF12 | DE65 | Read 4 hex chars, convert to 16-bit int |
| OSRDHBYTE | FF0F | DE9D | Read 2 hex chars, convert to 8-bit int |
| OSRDINT16 | FF15 | DD00 | Read a 16-bit decimal ineteged from STDIN_BUF |
| OSRDSTR | FF1B | DE06 | Read string from STDIN_BUF |
| OSRDTIME | FF8A | E437 | Read time from RTC |
| OSSFTRST | FFF4 |  | Soft reset - use JMP (not JSR) |
| OSSOAPP | FF30 | DEFF | Append string to STDOUT_BUF |
| OSSOCH | FF33 | DEF0 | Append character to STDOUT_BUF |
| OSSPIEXCH | FF84 | E3EB | Perform an SPI byte exchange |
| OSU16HEX | FF42 | DAD3 | 16-bit value to a 4-char hex string |
| OSU16ISTR | FF45 | DAFB | 16-bit value to a decimal string |
| OSWRBUF | FF1E | D617 | Write STDOUT_BUF to output stream |
| OSWRCH | FF21 | D632 | Write single character to output stream |
| OSWRERR | FF24 | DEDA | Write OS error string to output stream |
| OSWRMSG | FF27 | D5ED | Write text pointed to by MSG_VEC to output stream |
| OSWROP | FF2A | D639 | Write to Output Port on DUART board |
| OSWRSBUF | FF2D | D609 | Write STR_BUF to output stream |
| OSZDDEL | FF78 | D72C | Delete a file on the ZolaDOS server |
| OSZDLOAD | FF7B | D755 | Load a file from the ZolaDOS server |
| OSZDSAVE | FF7E | D7CC | Save a block of memory to a file |
