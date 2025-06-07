# Zolatron CLI Commands

Functions available from the command line.

Notes:

- `<addr>` means a 4-digit hex address - eg, 3FFF.
- `<hh>` means a 2-digit hex number - eg, 0A.
- `<filename>` is an ASCII filename with NO extension. ZolaDOS will assume a relevant extension.
- `<filename.ext>` is an ASCII filename WITH extension.
- `USR_START` is the start of user memory. It's where we load programs. Currently, it's at address $0800.
- `EXTMEM_START` is the start of extended (paged) ROM/RAM memory - currently $8000.

```
?       !       BRK     CHAIN   CLEAR   DATE    DEL
DUMP    HELP    JMP     LM      LOAD    LP      LS
(MV)    OPEN    PDUMP   PEEK    POKE    RUN     SAVE
STAT    TIME    VERS    XCHAIN  XCLR    XLOAD   XLS
XOPEN   XRUN    XSAVE   XSEL
```

**`? <addr>`** - Shows the contents of memory (1 byte) at the address given.

**`! <addr> <hh>`** - Sets the contents of memory at the specified address.

**`BRK`** - Performs a soft reset of the machine.

**`CHAIN <filename>`** - Looks for the file <filename>.EXE (the .EXE is assumed) and, if found, loads it at address USR_START and then jumps to that address to execute it.

**`CLEAR`** - Zeroes out a number of bytes, starting at USR_START, to effectively clear a program from memory. Also resets LOMEM and PROG_END to USR_START.

**`DATE`** - Displays the current date (if the SPI board is fitted).

**`DEL <filename.ext>`** - Delete a file on the ZolaDOS server. No confirmation is asked and no quarter given.

**`DUMP <start_addr> <end_addr> <filename>`** - Save a block of memory to the ZolaDOS device. The start and end addresses must be 4-char hex addresses. The extension '.BIN' will be appended automatically by ZolaDOS.

**`HELP`** - List the CLI commands.

**`JMP <addr>`** - Jump to the address and start executing code from there.

**`LM <start_addr> <end_addr>`** - List memory contents between given 4-digit hex addresses.

**`LOAD <filename>`** - Searches for a file called <filename>.EXE (the .EXE is assumed) and if found, loads it into memory at address USR_START.

**`LP <hh>`** - Hex listing of a page of memory. The two-digit hex address gives the memory page - eg, if you specify 08 you will get memory contents from 0800 to 08FF.

**`LS`** - List storage (ie, show files available).

**(MV)** - Not implemented yet.

**`OPEN <filename.ext> <addr>`** - Load any kind of file into a specific memory location. The filename needs to include the extension.

**`PDUMP`** - Do a hex listing of the program currently in user memory. Lists the memory contents starting at USR_START and continuing until it finds the EOF marker.

**`PEEK <addr>`** - Examine the contents of the byte at the given memory address. Hitting <return> will take you to the next byte. Enter Q <return> to quit.

**`POKE <addr>`** - Enter a value for the given memory address. You'll be prompted for the value, which must be entered as a 2-digit hex value. Press <return> to move to the next address. To quit, press <return> without entering a value.

**`RUN`** - Jump to location USR_START and begin executing code from there.

**`SAVE <filename>`** - Save the currently loaded program, starting at address USR_START, to persistent storage. Useful if we want to save a copy of an executable under another name. Also might be useful for any programs that are self-modifying or which store data within the program space. The .EXE extension will be appended automatically.

**`STAT`** - Prints out the status of some registers. Not very useful.

**`TIME`** - Displays the current time (if the SPI board is fitted).

**`VERS`** - Prints out the version string of the ZolOS ROM.

**`XCHAIN <filename>`** - Performs an XLOAD (see below) and then jumps to EXTMEM_START to execute the code. No extension needed for the filename (assumes .ROM).

**`XCLR`** - 'Clears' the currently selected sideways RAM bank by erasing the header details of any file stored there.

**`XLOAD <filename> <0-15>`** - Loads a program code into extended memory (the extension .ROM is assumed). The memory_bank must be in the range 0-15. The code will check that the selected bank is writeable (ie, that it has not been switched to ROM).

**`XLS`** - Lists the 16 extended ROM/RAM banks, showing any programs loaded.

**`XOPEN <filename.ext> <0-15>`** - Open a file and load its contents into an extended RAM bank (0-15). Similar to XLOAD, except that no extension is automatically added by ZolaDOS. Use for loading data files into extended memory.

**`XRUN`** - Performs a jump to EXTMEM_START. First checks for a 'P' code - indicating that an executable program is loaded in the currently selected bank.

**`XSAVE <0-15> <filename.ext>`** - Saves the contents of the given ROM/RAM bank to a file. ZolaDOS doesn't assume any extension.

**`XSEL <0-15>`** - Select a ROM/RAM bank to be the active bank.
