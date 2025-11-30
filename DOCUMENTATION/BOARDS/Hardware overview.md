# HARDWARE OVERVIEW

The Zolatron 64 uses a backplane design where all the functionality, including the CPU itself, is provided by plug-in boards.

## BACKPLANE

Although the backplane itself is a relatively simple critter, it also involved some of the hardest decision-making.

There was the question over what kind of connector. Some people use simple header pins for this sort of thing, which are cheap and easy to implement. But they didn't seem sufficiently serious (or robust). IDE-style edge connectors were another way to go, but can add cost to PCBs.

In the end I settled on DIN 41612 64P AC connectors. These use two rows of 32 pins each. (The connectors in the picture above have three rows, but the middle one is unused.)

These connectors are very stable and quite tolerant of frequent plugging/unplugging. And I figured 64 pins should be enough. (Spoiler alert: I was right.)

### The big decision

But that wasn't the big decision. That came next.

Which signals do I connect to which pins? Yikes!

I looked at a whole bunch of small system buses and agonised over what signals I needed to include and where. With the address bus, for example, do I run all 16 signals in a continous row or have eight in one column and the other eight alongside in the other column?

In the end, much came down to guesswork. After all, I hadn't built the damn machine yet. I wasn't even sure which signals I needed. So I fudged. I borrowed a few signal names from other computers which I ultimately didn't use (I'm looking at you /BUSACK and /BUSREQ) and others I forgot to implement on the appropriate cards (TX and RX, doh!).

The full list of signals not currently used is: VPB, RDY, SYNC, BE (these are all 6502 signals that might be wanted in future projects), RAMSEL (no idea what I was thinking there), /BUSREQ, /BUSACK, TX and RX. Also, the USR0-USR7 signals are intended for decoding peripherals in some clever way I haven't invented yet – but I do have a slight inkling of how I might use those.

There are VCC and GND connections at both top and bottom, with GND lines also bracketing the PHI2 clock signal, because that felt like a good idea. There are also ground connections in the centre. Can't have too many grounds. In fact, I probably should have had more.

Having clock-qualified read enable (/RD_EN) and write enable (/WR_EN) signals for distribution to all boards turned out to be a good choice.

And yes, the address and data signals are in a line, mostly because I couldn't make a case for not doing that.

The bus as viewed on the backplane. Due to right-angle connections, the columns are swapped on the plug-in cards.

### No termination

One thing you won't find on the backplane are termination resistors. The signal traces on the board are about 160mm long and this is a 1MHz system, so I figured transmission line echoes were unlikely to cause me grief.

All signals are broken out to pins at the edges of the board.

Apart from that, I added power input (not regulated, so a clean +5V input is required), a power LED, some capacitors for good measure (this is a four-layer board, so it also has ground and power planes), and two four-pin rows of header pins connected to ground to use when probing with a multimeter or oscilloscope (something I also add to all the plug-in boards).

## PLUGIN BOARDS

I chose a size of just a hair under 100x100mm for the boards in order to get the cheapest pricing for PCBs.

I also adopted a standard layout for the boards which includes four M3 mounting holes. This allows me to join the boards together with standoffs for greater rigidity.

Selecting an I/O board's address is as simple as placing a jumper.

Each I/O board (except for the SPI one) carries its own decoding, mostly in the form of a 74HCT1G00 single NAND gate and a 74HC138 three-to-eight line decoder. (The extended memory board is an exception – it uses a CPLD.) The outputs from the 138 go through a double row of header pins. Selecting the address for the board is a matter of placing one jumper.

I could have done this once on the main CPU board and carried the chip enable signals from the 138 over the backplane (this is why the backplane connector has lines USR0-USR7). That would have saved me a bunch of ICs. But doing the decoding on each board allows me to easily change the address of an I/O interface, and I count this as one of my good decisions.

### Boards in use

| BOARD         | Vers | Description                                           |
|---------------|:----:|-------------------------------------------------------|
|**CPU A**      | A5   | 65C02 CPU, main ROM (EEPROM), RAM and clock           |
|**CPU B**      | B1   | 65C02 CPU, main ROM (flash), RAM and clock            |
|**Dual Serial**| A1b  | SC28L92 dual 5V UART                                  |
|**Parallel**   | A2   | 65C22-based 8-bit printer port                        |
|**User Ports** | A2   | 65C22 VIA providing two 8-bit I/O ports               |
|**SPI**        | A1   | RTC, SD card, battery-backed Serial RAM, SPI ports    |
|**RPi**        | A4   | Storage & serial terminal                             |
|**Ext Memory** | A2   | Provides banked RAM and ROM                           |
