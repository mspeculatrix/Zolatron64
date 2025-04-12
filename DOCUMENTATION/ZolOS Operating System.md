# ZOLOS OPERATING SYSTEM

The firmware for the Zolatron – which I choose to aggrandise by referring to it as the ZolOS operating system – is held in an EEPROM in the top 16KB of the memory map.

The EEPROM is a Microchip AT28C256, which is actually a 32KB chip but, for reasons of easy addressing, I'm using just the top half of the chip's memory.

The EEPROM lives in a ZIF socket on the main CPU board.

When I started this project, I was just throwing routines into the ROM to see if they worked. There was no plan to strive towards something cohesive, let alone comprehensive. However, lately I've been taking a more considered approach, which includes implementing hooks to the OS functions via vectors. This allows me to use ROM-based functions in RAM-based user programs. To further facilitate that, a lot of the configuration (mostly defining constants such as memory addresses) is carried out through configuration files that are included in both the ROM OS code and user programs.

The code is available on GitHub.

OS Function Calls

CLI commands
