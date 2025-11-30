# Zolatron64

Homebrew 65C02 microcomputer.

This is a backplane design because that allows me to work, fix and improve various parts of the design.

The main CPU board has decoding for ROM, RAM and the /RD_EN & /WR_EN signals.

Each I/O board has its own address decoding.

Currently, the modules are:

- Main board: 65C02 CPU @ 1MHz, 32KB RAM, 16KB ROM (EEPROM), oscillator.
- VIA Interface boards: 65C22 VIA chip providing general-purpose I/O. One of these boards is currently used to drive a 16x2 character LCD display and five status LEDs. The other provides two eight-bit user ports.
- (Serial board: 6551-based UART used for console connection - not currently in use).
- Dual UART board: NXP SC28L92 providing two serial ports and other general-purpose I/O. One of the serial ports has now taken over the role of providing console access to the Z64.
- Raspberry Pi board: Has a 65C22 VIA talking to a Raspberry Pi Zero 2 W which provides terminal access (via the serial port) and acts as a mass storage device.
- Parallel port board: Uses a 65C22 VIA connecting to a 25-pin Centronics-like port for connecting to my dot-matrix printer.
- Extended memory board: Has a 128KB RAM chip providing 16 x 8KB memory banks mapped in at address $8000. The four lowest slots (0-3) can also be used to address EEPROMs. Switching between EEPROMs and RAM is via jumpers. Selecting which of the 16 banks is currently mapped in is via software. Using an ATF1502ASL CPLD on this board for decoding.
- SPI Interface board / RTC / SRAM / SD Card. This uses SPI65 in a CPLD to provide a SPI interface. Up to eight devices are supported, three of which are built into the board:
  - Battery-backed real-time clock (RTC).
  - Battery-backed Serial RAM (64KB).
  - SD card drive.

I'm using [Beebasm](https://github.com/stardot/beebasm/) as the assembler.

The branches are:

- _dev_: This is the version I'm working on at any given time. It's quite likely to be unstable and contain features that are incomplete and/or buggy.
- _main_: Any time the 'dev' branch is acceptably stable and all current features are complete, they get merged back into 'main'.

## MEMORY MAP

- $C000 - $FFFF - ROM 16KB
- $BF00 - $BFFF - 8x I/O (32-byte)
  - $BFE0 - $BFFF - Extended memory select
  - $BF00 - $BF1F - 65SPI, RTC, SD card, SRAM
- $A000 - $BBFF - 8x I/O (1KB)
  - $BC00 - $BFFF (Used by 32K I/O)
  - $B800 - $BBFF - not used
  - $B400 - $B7FF - DUART - dual serial ports
  - $B000 - $B3FF - not used
  - $AC00 - $AFFF - VIA D - Parallel printer port
  - $A800 - $ABFF - VIA C - User ports, user timer
  - $A400 - $A7FF - VIA B - RPi, ZolaDOS
  - $A000 - $A3FF - VIA A - LCD, Delay timer
- $8000 - $9FFF - Banked ROM/RAM - 8x 8KB banks
- $0000 - $7FFF - Main RAM 32KB
  - $0800 - $7FFF - User program space
  - $0700 - $07FF - PAGE 7 - SPI config
  - $0600 - $06FF - PAGE 6 - ZolaDOS workspace
  - $0500 - $05FF - PAGE 5 - User program workspace
  - $0400 - $04FF - PAGE 4 - Misc buffers & system variables
  - $0300 - $03FF - PAGE 3 - I/O buffers & indices
  - $0200 - $02FF - PAGE 2 - OS vectors
  - $0100 - $01FF - PAGE 1 - used by 6502 for stack
  - $00E0 - $00FF - PAGE 0 - Zero-page addresses used by OS
