## EXTMEMDECODE

This provides decoding for extended memory on the Zolatron 64.

It's CUPL code for programming an ATF1502ASL CPLD.

The memory sits at address $8000. The decoding allows us to select one of 16 8K banks at this address.

The bank is selected by writing the value 0-15 to the address $BFE0. This CPLD provides the decoding for that address as well as a register (BSEL) of four D-type flip-flops that hold the selected value.

This register connects to address lines A13-A16 of the RAM, thus selecting the effective address of the bank.

The BSEL register is also used to select among five chip enable signals - four for the RAM chips and one for the RAM. If the BSEL value is 0-3 then the appropriate CHIP_EN line 0-3 is selected. If BSEL is 4-15 then CHIP_EN4 is selected.

On the board itself, four jumpers individually select whether CHIP_EN lines 0-3 go to their respective ROMs or to the RAM (ie, are connected to CHIP_EN4).
