# ZolOS OS Function Calls

JSR addresses are the locations of the jump instructions. To call an OS function, you JSR to this address.

FUNC ADDR addresses are the start addressed of the actual function code.

| OS FUNCTION | JSR | FUNC ADDR | Comment |
|---|:---:|:---:|---|
| OSB2BIN | FF36 | DA0C |  |
| OSB2HEX | FF39 | DA2F |  |
| OSB2ISTR | FF3C | DA4E |  |
| OSDELAY | FF81 | DF65 |   |
| OSGETINP | FF03 | DC6D | Create input loop |
| OSGETKEY | FF00 | DC90 | Get char |
| OSHEX2B | FF3F | DA8B |  |
| OSHEX2DEC | FF48 | DAB7 |  |
| OSHRDRST | FFF7 |  |   |
| OSLCDB2HEX | FF5A | E076 |  |
| OSLCDCH | FF4E | E109 |  |
| OSLCDCLS | FF51 | E04C |  |
| OSLCDERR | FF54 | E130 |  |
| OSLCDINIT | FF4B | E055 |  |
| OSLCDMSG | FF57 | E0A2 |  |
| OSLCDSBUF | FF5D | E094 |  |
| OSLCDSC | FF60 | E143 |   |
| OSLCDWRBUF | FF63 | E086 |   |
| OSPRTBUF | FF66 | E244 |   |
| OSPRTCH | FF69 | E157 |   |
| OSPRTCHK | FF6C | E1BC |   |
| OSPRTINIT | FF6F | E1E5 |   |
| OSPRTMSG | FF72 |  |   |
| OSPRTSBUF | FF75 | E250 |   |
| OSRDASC | FF06 | DCB0 | Get next printable char from STDIN_BUF |
| OSRDBYTE | FF09 | DCC2 | Read next byte from STDIN_BUF |
| OSRDCH | FF0C | DCE8 | Get next non-space printable char from STDIN_BUF |
| OSRDDATE | FF8D | E3F7 |   |
| OSRDFNAME | FF18 | DD84 | Read string from STDIN_BUF |
| OSRDHADDR | FF12 | DE5F | Read 4 hex chars, convert to 16-bit int |
| OSRDHBYTE | FF0F | DE97 | Read 2 hex chars, convert to 8-bit int |
| OSRDINT16 | FF15 | DCFA | Read a 16-bit decimal ineteged from STDIN_BUF |
| OSRDSTR | FF1B | DE00 | Read string from STDIN_BUF |
| OSRDTIME | FF90 | E437 |   |
| OSSFTRST | FFF4 |  | Use direct JMP with these (not indirected/vectored) |
| OSSOAPP | FF30 | DEF9 |  |
| OSSOCH | FF33 | DEEA |  |
| OSSPIEXCH | FF8A | E3EB |   |
| OSU16HEX | FF42 | DACD |  |
| OSU16ISTR | FF45 | DAF5 |  |
| OSUSRINT | FF84 |  |   |
| OSUSRINTRTN | FF87 |  |   |
| OSWRBUF | FF1E | D611 | Write STDOUT_BUF to output stream |
| OSWRCH | FF21 | D62C |  |
| OSWRERR | FF24 | DED4 |  |
| OSWRMSG | FF27 | D5E7 |  |
| OSWROP | FF2A | D633 |  |
| OSWRSBUF | FF2D | D603 |  |
| OSZDDEL | FF78 | D726 |   |
| OSZDLOAD | FF7B | D74F |   |
| OSZDSAVE | FF7E | D7C6 |   |
