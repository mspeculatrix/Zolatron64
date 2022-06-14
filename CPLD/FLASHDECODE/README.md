### CPLD Decoding

This is CUPL code intended to program an ATF1502AS CPLD. It provides decoding that creates eight I/O addresses, in 32-byte intervals, starting at $BF00.

The top slot in this set, located at $BFE0, is the address for selecting banks within a Flash chip. This 128KB chip provides 16 8KB banks. So the CPLD also provides the decoding to set the top four address lines of the Flash according to which bank is required.
