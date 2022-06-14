# Zolatron64

Homebrew 65C02-based microcomputer.

This is a backplane design because that allows me to work, fix and improve various parts of the design.

The main CPU board has decoding for ROM, RAM and the /RD_EN & /WR_EN signals.

Each I/O board has its own address decoding (1K blocks).

Currently, the modules are:
  - Main board: 65C02 CPU @ 1MHz, 32KB RAM, 16KB ROM (EEPROM), oscillator.
  - VIA Interface boards: 65C22 VIA chip providing general-purpose I/O. One of these boards is currently used to drive a 16x2 character LCD display and five status LEDs.
  - Serial board: 6551-based UART used for conole connection.
  - Dual UART board: NXP SC28L92 providing two serial ports and other general-purpose I/O.
  - Raspberry Pi board: Has a 65C22 VIA and a Raspberry Pi Zero 2 W which provides terminal access and acts as a mass storage device.
  - Parallel port board: Uses a 65C22 VIA connecting to a 25-pin Centronics-like port for connecting to my dot-matrix printer (work in progress).

Using Beebasm as the assembler.

Read all about it: https://mansfield-devine.com/speculatrix/category/projects/zolatron/

The branches are:
* _dev_: This is the version I'm working on at any given time. It's quite likely to be unstable and contain features that are incomplete and/or buggy.
* _main_: Any time the 'dev' branch is acceptably stable and all current features are complete, they get merged back into 'main'.
