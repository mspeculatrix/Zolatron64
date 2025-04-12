# BOARDS OVERVIEW

The Zolatron 64 uses a backplane design where all the functionality, including the CPU itself, is provided by plug-in boards.

I chose a size of just a hair under 100x100mm for the boards in order to get the cheapest pricing for PCBs. I'm very happy with this decision.

I also adopted a standard layout for the boards which includes four M3 mounting holes. This allows me to join the boards together with standoffs for greater rigidity.



Selecting an I/O board's address is as simple as placing a jumper.

Each I/O board (except for the SPI one) carries its own decoding, mostly in the form of a 74HCT1G00 single NAND gate and a 74HC138 three-to-eight line decoder. (The extended memory board is an exception – it uses a CPLD.) The outputs from the 138 go through a double row of header pins. Selecting the address for the board is a matter of placing one jumper.

I could have done this once on the main CPU board and carried the chip enable signals from the 138 over the backplane (this is why the backplane connector has lines USR0-USR7). That would have saved me a bunch of ICs. But doing the decoding on each board allows me to easily change the address of an I/O interface, and I count this as one of my good decisions. (They are few, so I'll take the win where I can.)

In the picture on the right you can see the headers, the 74HC138 and, just below that, the 74HCT1G00.

Boards
CPU board

Dual serial board

Parallel board

65C22 VIA board

SPI board – RTC, SD card and SRAM

Raspberry Pi board

Extended memory board

Backplane