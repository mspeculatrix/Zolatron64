# Zolatron64

Homebrew 65C02 backplane-based microcomputer.

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

I'm using Beebasm as the assembler.

The branches are:

- _dev_: This is the version I'm working on at any given time. It's quite likely to be unstable and contain features that are incomplete and/or buggy.
- _main_: Any time the 'dev' branch is acceptably stable and all current features are complete, they get merged back into 'main'.

## MEMORY MAP

- $0000 - $7FFF - Main RAM 32KB
- $8000 - $9FFF - Banked ROM/RAM 8x 8KB banks
- $A000 - $BBFF - 7x I/O (8KB)
- $BF00 - $BFFF - 8x I/O (32-byte)
- $C000 - $FFFF - ROM 16KB

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/B0B312WQJV)
