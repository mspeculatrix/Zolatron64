# ZOLADOS FILE SYSTEM

I considered lots of options for persistent storage on the Zolatron – including CF cards, SD cards and even actually floppy disks. In the end, though, I decided to roll my own.

The reason is simply – the Zolatron project is all about learning, and I knew I would get more out of designing my own solution (however slow and inefficient) than by merely adapting an existing technology.

And so ZolaDOS was born.

In truth, a lot of the heavy lifting is done by the Pi Zero running on the Raspberry Pi board. This runs the zolados program (written in Go) as a systemd service.

The Pi is connected to the Zolatron via a 65C22 VIA chip. One port on the VIA is used as a bidirectional data port. The other port provides a number of unidirectional signals.

These are mostly flow control pins. For example, when sending data, the Zolatron pulls the Client Ready line low after it has placed a byte on the data port. The Client Active (controlled by the Zolatron) and Server Active (Pi) lines are taken low to indicate the start of an operation and go high again when finished – eg, when there's no more data to send.

In file transfers, I'm currently getting around 500 bytes/sec when loading and 1,000 byte/sec saving. Not exactly NVMe speeds, but good enough.

All operations are initiated by the Zolatron.

Client (Z64)
	dir
	Server (RPi)


CLIENT ACTIVE
Taken low by the Z64 to indicate that it wishes to initiate an action. It's held low by the Z64 until everything is done.
When sending, taken high again to indicate that everything has been sent.



PB0
/CA

	-->

GPIO5
PIN 29



Server polls this line. When it goes low, that initiates a Zolados process.


CLIENT READY
When idle, the client wishes to initiate a read or write operation.
When sending, a byte has been placed on the data bus.
When receiving, the byte on the data bus has been received & processed.

PB1
/CR

	-->

GPIO6
PIN 31

	After /CA has gone low, server monitors this line. When it goes low, server strobes /SR low to acknowledge.


DATA DIRECTION
Sets the direction of the data bus. Connects to pin 2 of the 74LVC4245.
HIGH = Z64 to Server
LOW = Server to Z64



PB2
DDIR

	-->	--



CLIENT ONLINE
Normally pulled high, this is taken low by the Z64 to show that it is powered & connected.



PB3
/CO

	-->

GPIO13
PIN 33

	Server constantly polls this line to check that client is active & available.

	PB4	<--

GPIO19
PIN 35
/SR

	SERVER READY
When sending, a byte has been placed on the data bus.
When receiving, the byte on the data bus has been received & processed.

	PB5	<--

GPIO16
PIN 36
/SA



 SERVER ACTIVE
When sending, taken low to indicate the server is sending data. Goes high again when server has finished sending data.

All files are stored in the ~/zd_files directory on the Pi. There's no concept of 'folders'.

File types

ZolaDOS currently recognises four file types that are given different file extension: executable program to run in user RAM (.EXE); executable program to run in extended memory (.ROM); data (.DAT) and binary (.BIN).

Executable and data files use file headers – small amount of data at the beginning of the file. This includes a type code (the ASCII code for 'E' with executable files and 'D' for data files).

Executable files
BYTE	CONTENTS	NOTE
0	$4C	JMP instruction - jmp .startprog
1	16-bit address of .startprog label	Address for previous JMP instruction. Machine will jump over this header info.
2
3	'E'	Type code
4	16-bit address of .header label	Address of <code>.header</code> label – tells ZolaDOS the load address of the file – either USR_PAGE or EXTMEM_LOC
5
6	16-bit address of .reset label	Usually the same as the .startprog label, but not necessarily. Where to jump to when resetting.
7
8	16-bit address of .endcode label	Address of first byte available after end of program. I put the <code>.endcode</code> label at the very end of the program code.
9
A	-- reserved --	(For future expansion)
B	-- reserved --	(For future expansion)
C	-- reserved --	(For future expansion)
D	.prog_name	Nul-terminated string containing short version of program name
varies	.version_string	Nul-terminated version string

You can see that the first byte is a JMP instruction, so that when the code is executed, it jumps over the header data. Here's an example of how the header code looks in assembly:

[code].header              ; HEADER INFO
    jmp startprog    ; Jump to start of actual program
    equb "E"         ; Designate executable file
    equb &lt;header     ; Entry address
    equb &gt;header
    equb &lt;reset      ; Reset address
    equb &gt;reset
    equb &lt;endcode    ; Addr of first byte after end of program
    equb &gt;endcode
    equs 0,0,0       ; -- Reserved for future use --
.prog_name
    equs "ZUMPUS",0  ; Short name, max 15 chars - nul terminated
.version_string
    equs "1.3.2",0   ; Version string - nul terminated
.startprog
  ; ... rest of program ...
[/code]
Data files

Data files have a shorter header:

BYTE	CONTENTS	NOTE
0	$FF

1	$00 or load address LSB	These bytes can be zero or the 16-bit address of the usual load location for the data.
2	$00 or load address MSB
3	'D'	Type code
