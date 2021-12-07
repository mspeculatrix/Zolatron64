## ROM Code

The Zolatron's ROM code occupies the top 16KB of the address space – $C000-$FFFF.

I'm using a 32KB EEPROM chip, the AT28C256. So the code needs to sit in the top 16KB of this. That's why the start address for the ROM – ie, the bytes that will be written to the file – start at $8000. But the first 16KB will just be random (and will be ignored because the ROM isn't enabled at addresses below $C000). The real code starts at $C000.

How I was doing versioning, especially once I'd switched to using include files, wasn't working. So I've now moved versions 01-05, which just had a single source file, into the Previous_Versions directory. Subsquent versions will each get their own folder with a complete set of include files appropriate to that version.

The current version will simply be called z64-dev and is to be regarded as a work in progress (ie, it almost certainly doesn't work).

Versions:
* z64-01: Uses the VIA to print a message to the 16x2 LCD.
* z64-02: As above, but also prints a message via the serial port.
* z64-03: Accepts input via serial and prints it to the LCD. Because of performance issues, the sending terminal needs to add a 10ms delay between chars, to avoid an overrun condition. Currently no checking for buffer overflows, so don't use this code in high-security environments <-=ahem=->.
* z64-04: Some tidying up. Added check for size of receive buffer (although not tested). Removed the looping within the ISR.
* z64-05: Added some additional LCD printing options. At this point, we have a system that seems to reliably accept serial input and prints it to the LCD.
* z64-06: Added parsing of commands received via serial. The commands are parsed, but nothing is done with them yet. All it does is print the token value for the command via serial. Also has routines for converting a one-byte value to a hex string representation, which I'll be needing for a planned memory monitor, and the opposite (string to byte).
* z64-07: Implemented the commands that have been parsed - or, at least, stubs for them. Only one is actually working (VERS).
* z64-08: Some tidying up from v07. Basically consolidating stuff, so this should be regarded as a landmark version.
* z64-dev: WORK IN PROGRESS.

The output-nn.txt files in the _output_ folder are the output from Beebasm when the code is assembled. Just in case.

_build_ is just a small Bash script I use to save typing (and remembering) the commands to assemble the code and write it to the EEPROM. Documentation is in the script itself.

As the source file was starting to get rather long, and I got tired of scrolling, I've now carved out certain discrete parts of the code and have put them in include files, in the _include_ directory.
