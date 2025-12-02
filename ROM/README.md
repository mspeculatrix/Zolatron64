# Zolatron 64 OS ROM

The ROM code was initially intended to be flashed to an AT28C256 EEPROM. And it still works that way with the Model A CPU board.

The default binary file produced is 32KB in size but the ROM code lives in the top 16KB. That's to do with the fact that the EEPROM chip I'm using is 32KB in size and it's also connected with the Zolatron's decoding logic.

The Model B CPU board uses flash memory in place of the EEPROM. For this, the `build` script for the ROM also has the option to output a 16KB file.

## FLASH PROGRAMS

### FLASHPROG

Firmware for ATmega4809 on the B model CPU board with flash.

### FLASHZ.PY

Python code to run on dev machine to talk to MCU on CPU board. Developed from `flashburn.py`.

### FLASHBURN.PY (discontinued)

Python code to run on dev machine to talk to MCU on CPU board. Working but discontinued in favour of `flashz.py`.

## BUILD SCRIPT

The build script calls Beebasm to assemble the code into a binary and then invokes either miinipro to write the binary to EEPROM or `flashz.py` to write it to flash memory, depending on the CPU board in use.

The script is **heavily** geared to my dev environment and almost certainly won't work for you.

## CHANGELOG

### 5.3.4 in progress

### 5.3.3 02/12/2025

- Fixed some problems with maths operations.
- Created `flashz.py` to succeed `flashburn.py`.

### 5.3.1 19/11/2025

- Working versions of `flashrom` and `flashburn.py`. Prior to switching to `flashz`.

### 5.2.0

- Moved stuff in zero page to the high part of the page, starting at $E0.
- Added OS labels in code & Python script to output lists.
- Added system VIA constants: basically the same as constants for the LCD VIA, but these new ones are to be used for functions (such as the main timer) that are not specific to the LCD. I might phase out the LCD at some point.

### 5.1.3

- Added OSLCDINIT call.

### 5.1.2 - committed

- Not sure if there are any changes, but it's been a while since I worked on this so burning a new version just in case.
- Updated zapp util (not in this repo).

### 5.1.1 - committed

- Added IRQ handling for User Port. IRQ_REG now holds flags relating to CA1, CA2, CB1, CB2, Timer 1 and Timer 2 interrupts.

### 5.1.0 - committed

- Fixed bug in date handling.
- Added SD card init routine to ROM.
- Initial/basic SD card functions.

### 5.0.6 - committed

- Swapped functionality of PEEK and ?.
- Added OSRDDATE and OSRDTIME OS functions.
- Added TIME and DATE commands.
- Improved POKE command - can now enter multiple bytes.
- Added 'get input' function and OSGETINP OS call.
- Added 'null input' error code.
- Added SPI functionality. Created OSSPIEXCH OS call. Added basic real-time clock functions.
- Updated OSB2ISTR to return number of digits in FUNC_RESULT.
- Changed filename reading routine to control when an extension is or isn't included in the maximum filename length check. Created the ZD_CTRL_REG register to manage this. Set bit 7 to 1 before reading a filename if the extension isn't to be included.
- Fixed bug with DEL command.
- Fixed bug with input routine where junk was being left in input buffer.
- Added user program interrupt vector.

### 5.0.5 - committed

- Improved response to backspace - now sets input index correctly if backspacing goes beyond the beginning of the buffer.

### 5.0.4 - committed

- Input now works with Backspace character (ASCII 8) by decrementing input buffer index.
- Modified messages shown when loading a file. 'Loading ...' message now optional.
- Fixed bug with filename length checking. Was hanging when two-char commands were entered and causing a reboot when one-char commands were used.
- Fixed bug with ZD_CO_ON/\_OFF signals. Then fixed them again.
- Improved build script so that only one edit is needed to change the version number.
- Tidied up messages when loading files.

### 5.0.3 - committed

- Renamed EX command to CHAIN
- Removed 'Loading...' message when directly calling an .EXE program from the command line (ie, not using LOAD or CHAIN).
- Fixed bugs in the command pointer jump table.

### 5.0.2 - committed

- Added ability to load & run .EXE programs from command line - eg, as with DOS, CP/M, Unix etc, when a command is typed into the CLI, first the OS checks to see if it's a built-in command. If not, it then looks to see if it can load an executable file of that name from storage (the '.EXE' extension is added automatically). If a load succeeds, the code is run automatically.

### 5.0.1 - committed

- Added PDUMP command.
- Fixed the hex memory display (last line of ASCII output wasn't shown if it wasn't a full 16 bytes).
- Linefeeds (ASCII 10) are no longer treated specially in the CLI's main loop. Before, they were treated the same as a Null (ASCII 0) - in fact, that's what they were converted to. Now, a linefeed (or carriage return, for that matter) is treated like any other character. To indicate end of transmission, whatever is sending to the Zolatron must send a Null.

The following boards are considered to be intrinsic parts of the computer (which need to be served by the OS):

- CPU board (duh!)
- LCDV - LCD/LED board - VIA also provides timer 1 for delay function.
- DUART - SC28L92 DUART board - two serial ports plus other I/O. One port is used as the main console.
- ZD - RPi/ZolaDOS board - provides terminal & mass storage.
- USRP - User Port VIA board (provides timers available for user programs).

The following boards are optional. The OS checks for their existence on boot. But I've still put routines to handle these boards into the OS, rather than expecting user code to manage them.

- EXMEM - Extended memory (ROM/RAM) board
- PRT - Parallel interface board

The Zolatron's ROM code occupies the top 16KB of the address space – $C000-$FFFF.

I'm using a 32KB EEPROM chip, the AT28C256. So the code needs to sit in the top 16KB of this. That's why the start address for the ROM – ie, the bytes that will be written to the file – start at $8000. But the first 16KB will just be random (and will be ignored because the ROM isn't enabled at addresses below $C000). The real code starts at $C000.

Communication with the Zolatron is via serial at 9600 baud 8N1. As we're not using any form of flow control (yet) any terminal that connects to the Zolatron needs to have a slight delay after sending each character. I'm currently using 30ms, but will experiment with that. Data sent to the Zolatron should be terminated with a null character (ASCII 0) to mark end of transmission.

The output-nn.txt files in the _output_ folder are the output from Beebasm when the code is assembled. Just in case.
