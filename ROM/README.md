## ROM Code

The Zolatron's ROM code occupies the top 16KB of the address space – $C000-$FFFF.

I'm using a 32KB EEPROM chip, the AT28C256. So the code needs to sit in the top 16KB of this. That's why the start address for the ROM – ie, the bytes that will be written to the file – start at $8000. But the first 16KB will just be random (and will be ignored because the ROM isn't enabled at addresses below $C000). The real code starts at $C000.

Versions:
* z64-01: Uses the VIA to print a message to the 16x2 LCD.
* z64-02: As above, but also prints a message via the serial port.
* z64-03-wip - WORK IN PROGESS: Trying to add serial receive capabilities, but it's not going well so far...
