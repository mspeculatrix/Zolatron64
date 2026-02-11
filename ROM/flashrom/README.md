# FLASHROM

This is firmware for the ATmega4809 microcontroller on a version B CPU board for the Zolatron.

It is designed to be used in conjunction with the `flashz.py` Python program.

This code depends on a number of my libaries, which you can find [on GitHub](https://github.com/mspeculatrix/avrlib).

## ATmega4809-A PIN ASSIGNMENTS

| Signal                  | Port  | Pin(s) |
|------------------------:|:-----:|--------|
| Address bus    A0 .. A7 | PORTC | 0 .. 7 |
|               A8 .. A13 | PORTF | 0 .. 5 |
|                A14, A15 | PORTB | 0, 1   |
| Flash addr FA14 .. FA16 | PORTE | 0 .. 2 |
| Data bus         D0..D7 | PORTD | 0 .. 7 |
| CPU_RDY                 | PORTA | 2      |
| CPU_BE                  | PORTA | 3      |
| CLK_CTRL                | PORTA | 4      |
| CPU_RWB                 | PORTA | 5      |
| FL_WE                   | PORTA | 6      |
| SYS_RES                 | PORTA | 7      |

## Banking

The SST39SF010 is a 1Mbit (128KB) memory. As the ROM images for the Zolatron are 16KB each, that means the flash can hold up to 8 ROM images.

## TO DO

- Implement banking properly with a command to select a bank.
  - Is there any way we could have the bank selected from the 6502 side?
