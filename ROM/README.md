## Zolatron 64 ROM

The Zolatron's ROM code occupies the top 16KB of the address space – $C000-$FFFF.

I'm using a 32KB EEPROM chip, the AT28C256. So the code needs to sit in the top 16KB of this. That's why the start address for the ROM – ie, the bytes that will be written to the file – start at $8000. But the first 16KB will just be random (and will be ignored because the ROM isn't enabled at addresses below $C000). The real code starts at $C000.

Communication with the Zolatron is via serial at 9600 baud 8N1. As we're not using any form of flow control (yet) any terminal that connects to the Zolatron needs to have a slight delay after sending each character. I'm currently using 30ms, but will experiment with that. Data sent to the Zolatron should be terminated with a null character (ASCII 0) or the line end character – currently I'm using linefeed (ASCII 10, $0A).

The branches are:
* _unstable_: This is work in progress. It will contain code that is incomplete and/or buggy. It's what I'm working on at any given time and so nothing is guaranteed to function.
* _dev_: When each new feature is reasonably stable and complete, it gets merged back into this branch. The 'dev' branch should work reasonably well - as well as any of this is likely to work. But it may still have features (such as commands) that are incomplete, although they shouldn't cause problems.
* _main_: Any time the 'dev' branch is acceptably stable and all current features are complete, they get merged back into 'main'. This won't happen frequently, so the 'main' branch will lag well behind.

The output-nn.txt files in the _output_ folder are the output from Beebasm when the code is assembled. Just in case.

_build_ is just a small Bash script I use to save typing (and remembering) the commands to assemble the code and write it to the EEPROM. Documentation is in the script itself.

_burn_ is a Bash script to write a bin file to the EEPROM. I use it to write older bin files. You need to be in the ROM directory to run it and it looks in the bin/ directory within that for its files.

As the source file was starting to get rather long, and I got tired of scrolling, I've now carved out many discrete parts of the code and have put them in include files, in the _include_ directory. These are likely to change frequently.
