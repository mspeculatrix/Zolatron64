# CPU BOARD

The soul of this machine, the CPU board holds ... well, the CPU. I mean, you probably already worked that out.

Alongside the 65C02 microprocessor is the AT28C256 EEPROM holding the machine's operating system, and an AS6C62256 32KB RAM chip.

A 74HCT00 quad NAND IC is used for some decoding – primarily the clock-qualified read enable (/RD_EN) and write enable (/WR_EN) signals that go out over the backplane.

A DS1813 IC provides for a smooth reset.

I also included a 74HC1G00 single NAND gate to provide a base level of decoding for I/O boards. This signal also goes out over the backplane, but I haven't used it nearly as much as I thought I would.

There's also a 1MHz oscillator can (I tried a 2MHz one – didn't go so well) and a reset button.
