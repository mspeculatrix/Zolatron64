Versions:
* z64-01: Uses the VIA to print a message to the 16x2 LCD.
* z64-02: As above, but also prints a message via the serial port.
* z64-03: Accepts input via serial and prints it to the LCD. Because of performance issues, the sending terminal needs to add a 10ms delay between chars, to avoid an overrun condition. Currently no checking for buffer overflows, so don't use this code in high-security environments <-=ahem=->.
* z64-04: Some tidying up. Added check for size of receive buffer (although not tested). Removed the looping within the ISR.
* z64-05: Added some additional LCD printing options. At this point, we have a system that seems to reliably accept serial input and prints it to the LCD.
* z64-06: Added parsing of commands received via serial. The commands are parsed, but nothing is done with them yet. All it does is print the token value for the command via serial. Also has routines for converting a one-byte value to a hex string representation, which I'll be needing for a planned memory monitor, and the opposite (string to byte).
* z64-07: Implemented the commands that have been parsed - or, at least, stubs for them. Only one is actually working (VERS).
* z64-08: Some tidying up from v07. Basically consolidating stuff, so this should be regarded as a landmark version.
