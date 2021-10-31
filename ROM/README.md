## ROM Code

The Zolatron's ROM code occupies the top 16KB of the address space – $C000-$FFFF.

I'm using a 32KB EEPROM chip, the AT28C256. So the code needs to sit in the top 16KB of this. That's why the start address for the ROM – ie, the bytes that will be written to the file – start at $8000. But the first 16KB will just be random (and will be ignored because the ROM isn't enabled at addresses below $C000). The real code starts at $C000.

Versions:
* z64-01: Uses the VIA to print a message to the 16x2 LCD.
* z64-02: As above, but also prints a message via the serial port.
* z64-03: Accepts input via serial and prints it to the LCD. Because of performance issues, the sending terminal needs to add a 10ms delay between chars, to avoid an overrun condition. Currently no checking for buffer overflows, so don't use this code in high-security environments <-=ahem=->.
* z64-04: Some tidying up. Added check for size of receive buffer (although not tested). Removed the looping within the ISR.
* z64-05: Added some additional LCD printing options. At this point, we have a system that seems to reliably accept serial input and prints it to the LCD.
* z64-06-dev: WORK IN PROGRESS: Now attempting to do parsing of commands received via serial.

(*-dev.asm versions are development versions - ie, works in progress - and almost certainly don't work.)

The output-nn.txt files in the output folder are the output from Beebasm when the code is assembled.

_build_ is just a small Bash script I use to save typing (and remembering) the commands to assemble the code and write it to the EEPROM.
