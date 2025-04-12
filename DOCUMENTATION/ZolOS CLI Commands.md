# ZOLOS CLI COMMANDS



[Click for a larger version]

These are the commands that can be called from the command line interface.

Updated: 19 Oct 2022

? <addr> : Similar to the PEEK command, but instead of just showing the contents of the given address it will continue to show the next address for as long as you type <return>. To stop this behaviour, type: Q <return>.
! <addr> <hexbyte> [<hexbyte>, <hexbyte>, ...] : Similar to POKE, but instead of entering one byte at the given command, you can enter up to 16 bytes, separated by spaces.
BRK : Does a soft break, resetting some registers and values (like input and output buffer indexes).
CLEAR : Clears the current user program from memory. Actually, all it does is write zeroes into the first 16 bytes of RAM at the start of user memory ($0800). I'm using header data in my programs – something I plan to write about soon – and this erases that metadata so that any check for an existing program will come up empty.
DEL <filename> : Deletes the file from the filesystem (without further prompting or warning). Requires the full filename, including extension.
DUMP <start_addr> <end_addr> <filename> : Saves the contents of memory from start address to end address. The filename should not have an extension (.BIN is added automatically).
EX <filename>: Loads a program to RAM, starting at USR_START (like LOAD) and then executes it.
HELP : Prints out a list of these commands, with no further helpful information!
JMP <addr> : Does what it says on the tin – jumps to the given address and starts execution from there.
LM <start_addr> <end_addr> : Does an on-screen hex dump from start address to end address. With LP (below) this has proven to be an invaluable debugging tool.
LOAD <filename> : Loads an executable (program) file to RAM, starting at USR_START ($0800). No extension is needed (.EXE is assumed).
LP <page> : Does an on-screen hex dump for a single page (256 bytes) of memory. You enter the upper byte of the address, so LP 08 displays the 256 bytes starting at $0800. This is even more useful than LM because it's so quick to use.
LS : List storage. Lists the files on the filesystem.
(MV <curr_name> <new_name>) : In progress. Equivalent to Unix's mv command – ie, renames a file. I'm still debating whether to call this REN.
OPEN <filename> <start_address>: Loads a file at the given address in memory. The full filename must be given.
PEEK <addr> : Shows the value of the byte at the given address.
POKE <addr> <byte> : Enters a value into the byte at the given address.
RUN : Executes the program currently loaded into user memory.
SAVE <filename> : Saves the contents of RAM from USR_START ($0800) to USR_END (the last byte of the currently loaded program). In other words, it saves a copy of the current user program, which might be useful in the case of self-modifying code. The '.EXE' extension is added automatically.


Typing the command XLS shows what's loaded into the 16 banks. The version of Zumpus in bank 3 is a ROM.

STAT : Prints some handy stats about registers & whatnot. A couple have proven to be useful for debugging.

VERS : Prints the version number of the OS. This was the first command I implemented and I never use it.
XCLR <bank> : Clear the contents of the designated extended memory bank. Like CLEAR above, it actually just zeroes out the first 16 bytes, erasing the file metadata.
XLOAD <filename> : Load an executable file into the currently selected extended memory bank. No filename extension is needed (.EXE is assumed).
XLS : List the contents of the extended memory banks.
XOPEN <filename> : Opens a data file and loads its contents into the currently selected extended memory bank. No filename extension is assumed so the filename needs to be supplied in full.
XRUN : Executives the code in the currently selected extended memory bank.
XSAVE <bank> <filename>: Saves the contents of the given bank to the filesystem. No extension is assumed so you need to give the full filename. The whole 8KB in the bank is saved.
XSEL <bank> : Selects an extended memory bank (0-15) as the currently active bank.

«« Back to main page ««