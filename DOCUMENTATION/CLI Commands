# Zolatron CLI Commands

Functions available from the command line.

```
?       !       BRK     CHAIN   CLEAR   DATE    DEL
DUMP    HELP    JMP     LM      LOAD    LP      LS
(MV)    OPEN    PDUMP   PEEK    POKE    RUN     SAVE
STAT    TIME    VERS    XCHAIN  XCLR    XLOAD   XLS
XRUN    XSAVE   XSEL
```

**? <hhhh>** - Shows the contents of memory (1 byte) at the address given. Eg: `? 08FF`.

**! <hhhh> <hh>** - Sets the contents of memory at address `<hhhh>` to the hex value `<hh>`. Eg: `! 08FF EA`.

**BRK** - Performs a soft reset of the machine.

**CHAIN <filename>** -

**CLEAR** -

**DATE** - Displays the current date (if the SPI board is fitted).

**DEL <filename>** -

**DUMP** -

**HELP** List the CLI commands.

**JMP <hhhh>** - Jump to the given address and start executing code from there.

**LM <hhhh> <hhhh>** - List memory contents between given hex addresses.

**LOAD <filename>** - Searches for a file called <filename>.exe (the `.exe` is appended automatically and shouldn't be specified) and if found, loads it into memory at address $0800.

**LP <hh>** - List the contents of a page of memory. The two-digit hex address gives the memory page - eg, if you specify `08` you will get memory contents from `0800` to `08FF`.

**LS** - List storage (ie, show files available).

**(MV)** - Not implemented yet.

**OPEN <filename.ext> <hhhh>** - Load a file at the address given.

**PDUMP** -

**PEEK <hhhh>** - Examine the contents of the byte at the given memory address. Hitting `<return>` will take you to the next byte. Enter `Q <return>` to quit.

**POKE <hhhh>** - Enter a value for the given memory address. You'll be prompted for the value, which must be entered as a two-digit hex value. Press `<return>` to move to the next address. To quit, press `<return>` without entering a value.

**RUN** -

**SAVE** -

**STAT** - Prints out the status of some registers.

**TIME** - Displays the current time (if the SPI board is fitted).

**VERS** - Prints out the version string of the ROM.

**XCHAIN <filename>** -

**XCLR** - 'Clears' the currently selected sideways RAM bank by erasing the header details of any file stored there.

**XLOAD <filename>** -

**XLS** - Lists the 16 extended ROM/RAM banks, showing any programs loaded.

**XRUN** -

**XSAVE** -

**XSEL <n>** - Select a ROM/RAM bank to be the active bank. Enter a value 0-15.
