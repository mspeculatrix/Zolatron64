# CPLD code

This folder is for CUPL code for CPLDs used on the Zolatron 64 platform.

I'm using the ATF150xASL family of CPLD chips.

## Projects

- EXTMEMDECODE is for the Extended Memory board.
- Z64IODECODE - This is really meant for a future version of the Zolatron. It replicates some of the I/O decoding (ie, the 1K I/O address spaces) and other signals that we're already doing by other means. But it also provides decoding for the 32-byte I/O address spaces. It's used on the SPI interface board.

## More info

You can read about my initial (yet oddly successful) attempts at coding CPLDs here: https://mansfield-devine.com/speculatrix/2022/06/a-newbies-introduction-to-cupl-and-cplds/
