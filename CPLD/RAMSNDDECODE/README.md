CUPL code to program the ATF1502ASL CPLD which provides decoding for the Extended RAM & Sound board.

The memory sits at address $8000. The decoding allows us to select one of 16 8K banks at this address.

The bank is selected by writing the value 0-15 to the address $BFE0. This CPLD provides the decoding for that address as well as a register (BSEL) of four D-type flip-flops that hold the selected value.

This register connects to address lines A13-A16 of the RAM, thus selecting the effective address of the bank.

The CPLD also provides decoding for a 65C22 VIA, which sits at address $BFC0. This controls an SN76489AN sound generator chip (as used on the BBC Micro and elsewhere).
