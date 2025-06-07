# ZolOS OS Function Calls

JSR addresses are the locations of the jump instructions. To call an OS function, you JSR to this address.

FUNC ADDR addresses are the start addressed of the actual function code.

| OS FUNCTION | JSR | FUNC ADDR | Comment |
|---|:---:|:---:|---|
| OSB2BIN | FF36 | DA0C | 1-byte integer value to a binary string |
| OSB2HEX | FF39 | DA2F | 8-bit value to 2-char hex string |
| OSB2ISTR | FF3C | DA4E | 8-bit value to decimal integer string |
| OSDELAY | FF81 | DF65 | General-purpose delay function. Blocking |
| OSGETINP | FF03 | DC6D | Create input loop |
| OSGETKEY | FF00 | DC90 | Get char, waits for user to enter a key & return |
| OSHEX2B | FF3F | DA8B | 2-char hex string to byte value |
| OSHEX2DEC | FF48 | DAB7 | 1-byte char (ie, '0' to 'F') to int (0-15) |
| OSHRDRST | FFF7 |  | Hard reset - use JMP (not JSR) |
| OSLCDB2HEX | FF5A | E076 | Print byte value as hex |
| OSLCDCH | FF4E | E109 | Write char |
| OSLCDCLS | FF51 | E04C | Clear screen |
| OSLCDERR | FF54 | E130 | Write OS error string |
| OSLCDINIT | FF4B | E055 | Initialise LCD |
| OSLCDMSG | FF57 | E0A2 | Write text pointed to by MSG_VEC |
| OSLCDSBUF | FF5D | E094 | Print contents of STR_BUF |
| OSLCDSC | FF60 | E143 | Set cursor |
| OSLCDWRBUF | FF63 | E086 | Write STDOUT_BUF |
| OSPRTBUF | FF66 | E244 | Print contents of STDOUT_BUF |
| OSPRTCH | FF69 | E157 | Print character |
| OSPRTCHK | FF6C | E1BC | Check printer state, set flags |
| OSPRTINIT | FF6F | E1E5 | Initialise the printer VIA |
| OSPRTMSG | FF72 |  | Print string pointed to by MSG_VEC |
| OSPRTSBUF | FF75 | E250 | Print contents of STR_BUF |
| OSRDASC | FF06 | DCB0 | Get next printable char from STDIN_BUF |
| OSRDBYTE | FF09 | DCC2 | Read next byte from STDIN_BUF |
| OSRDCH | FF0C | DCE8 | Get next non-space printable char from STDIN_BUF |
| OSRDDATE | FF87 | E3F7 | Read date from RTC |
| OSRDFNAME | FF18 | DD84 | Read string from STDIN_BUF |
| OSRDHADDR | FF12 | DE5F | Read 4 hex chars, convert to 16-bit int |
| OSRDHBYTE | FF0F | DE97 | Read 2 hex chars, convert to 8-bit int |
| OSRDINT16 | FF15 | DCFA | Read a 16-bit decimal ineteged from STDIN_BUF |
| OSRDSTR | FF1B | DE00 | Read string from STDIN_BUF |
| OSRDTIME | FF8A | E437 | Read time from RTC |
| OSSFTRST | FFF4 |  | Soft reset - use JMP (not JSR) |
| OSSOAPP | FF30 | DEF9 | Append string to STDOUT_BUF |
| OSSOCH | FF33 | DEEA | Append character to STDOUT_BUF |
| OSSPIEXCH | FF84 | E3EB | Perform an SPI byte exchange |
| OSU16HEX | FF42 | DACD | 16-bit value to a 4-char hex string |
| OSU16ISTR | FF45 | DAF5 | 16-bit value to a decimal string |
| OSWRBUF | FF1E | D611 | Write STDOUT_BUF to output stream |
| OSWRCH | FF21 | D62C | Write single character to output stream |
| OSWRERR | FF24 | DED4 | Write OS error string to output stream |
| OSWRMSG | FF27 | D5E7 | Write text pointed to by MSG_VEC to output stream |
| OSWROP | FF2A | D633 | Write to Output Port on DUART board |
| OSWRSBUF | FF2D | D603 | Write STR_BUF to output stream |
| OSZDDEL | FF78 | D726 | Delete a file on the ZolaDOS server |
| OSZDLOAD | FF7B | D74F | Load a file from the ZolaDOS server |
| OSZDSAVE | FF7E | D7C6 | Save a block of memory to a file |
