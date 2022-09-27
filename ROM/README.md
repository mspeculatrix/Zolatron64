## Zolatron 64 ROM

This is V3 of the ROM. It considers the following boards to be intrinsic parts of the computer (which need to be served by the OS):

* CPU board (duh!)
* LCDV  - LCD/LED board - VIA also provides timer 1 for delay function
* DUART - SC28L92 DUART board - two serial ports plus other I/O
* ZD    - RPi/ZolaDOS board - provides terminal & mass storage
* USRP  - User Port VIA board (provides timers available for user programs)
* EXMEM - Extended memory (ROM/RAM) board
* PRT   - Parallel interface board

The Zolatron's ROM code occupies the top 16KB of the address space – $C000-$FFFF.

I'm using a 32KB EEPROM chip, the AT28C256. So the code needs to sit in the top 16KB of this. That's why the start address for the ROM – ie, the bytes that will be written to the file – start at $8000. But the first 16KB will just be random (and will be ignored because the ROM isn't enabled at addresses below $C000). The real code starts at $C000.

Communication with the Zolatron is via serial at 9600 baud 8N1. As we're not using any form of flow control (yet) any terminal that connects to the Zolatron needs to have a slight delay after sending each character. I'm currently using 30ms, but will experiment with that. Data sent to the Zolatron should be terminated with a null character (ASCII 0) or the line end character – currently I'm using linefeed (ASCII 10, $0A).

The output-nn.txt files in the _output_ folder are the output from Beebasm when the code is assembled. Just in case.

_build_ is just a small Bash script I use to save typing (and remembering) the commands to assemble the code and write it to the EEPROM. Documentation is in the script itself.
