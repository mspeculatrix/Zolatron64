# FLASHROM

This is firmware for the ATmega4809 microcontroller on a version B1 CPU board for the Zolatron.

It is designed to be used with the `flashburn.py` Python program.

## ATmega4809-A PIN ASSIGNMENTS

| Signal                  | Port  | Pin    |
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
