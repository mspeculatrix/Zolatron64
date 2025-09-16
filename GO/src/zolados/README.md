# ZolaDOS
Go-based file server for the Zolatron 64 6502-based homebrew computer.

https://bit.ly/zolatron64

This uses a Raspberry Pi (a Zero 2W in my case) as a 'disk drive' for the Zolatron.

The current version supports the following Z64 commands:

* __LOAD__ \<filename\> Sends data from a file from the RPi's zd_files directory to the Z64, which loads the data into RAM at USR_PAGE. On the RPi, suitable files have the '.BIN' extension, but this shouldn't be specified in the LOAD command - eg, use: LOAD TESTA to load the file TESTA.BIN.
* __LS__ List storage. Sends a list of all the files in the zd_files directory to the Z64.
* __SAVE__ \<addr1\> \<addr2\> \<filename\> Saves data from the Z64 from memory location addr1 to add2 to the zd_files directory on the RPi. The Pi appends the extension '.BIN', so this shouldn't be specified in the command.  

The Zolatron connects through a 65C22 VIA, using one port as a bidirectional 8-bit parallel data bus, and the other port for unidirectional control signals. Those signals are:

* __CA__ - Client Active - controlled by the Zolatron.
* __CR__ - Client Ready - controlled by the Zolatron.
* __SA__ - Server Active - controlled by this program.
* __SR__ - Server Ready - controlled by this program.
