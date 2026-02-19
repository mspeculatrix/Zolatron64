# EXTMEMDECODE

This provides decoding for extended memory on the Zolatron 64. This code programs a CPLD that sits on the extended memory board itself.

It's CUPL code for programming an ATF1502ASL CPLD.

The memory sits at address $8000. The decoding allows us to select one of 16 8K banks at this address.

The bank is selected by writing a value 0-15 to the address `$BFE0` (which sets the `BSEL_EN` value in the CUPL code). This CPLD provides the decoding for that address. It sets the value written to `$BFE0` into a register (`BSEL`) of four D-type flip-flops.

These flip-flops have their clocks enabled. The flip-flop is set to the appropriate value when `CLK` transitions low - ie, on the falling edge. The flip-flop is also enabled only when `RWB` is low (ie doing write operations).

The flip-flops will set according to the inputs on `D0-D3`. When the clock goes high again, these values are latched. When we no longer have `$BFE0` as the address, the values will remain latched.

These four flip-flops are connected to `A13-A16` on the RAM chip, thus selecting the effective address of the bank. They're not attached to the system address bus - so they don't interfere with anything else.

The `CHIP_EN` register is used to select among five chip enable signals - four for the RAM chips and one for the RAM. If the `BSEL` value is 0-3 then the appropriate `CHIP_EN` line 0-3 is selected. If `BSEL` is 4-15 then `CHIP_EN4` is selected.

On the board itself, four jumpers individually select whether `CHIP_EN` lines 0-3 go to their respective ROMs or to the RAM (ie, are connected to `CHIP_EN4`).
