CUPL code for the ATF1502ASL CPLD which provides decoding for the Extended RAM board.

The memory sits at address $8000. The decoding allows us to select one of 16 8K banks at this address.

The bank is selected by writing the value 0-15 to the address $BFE0. This CPLD provides the decoding for that address as well as a register (BSEL) of four D-type flip-flops that hold the selected value.

This register connects to address lines A13-A16 of the RAM, thus selecting the effective address of the bank.

This code is intended for the simplest version of the board, with just RAM. Two other versions are available - one provides for four 8K ROM slots and the other adds a sound generator.
