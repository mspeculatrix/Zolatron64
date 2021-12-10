## Zolatron 64 ROM

The Zolatron's ROM code occupies the top 16KB of the address space – $C000-$FFFF.

I'm using a 32KB EEPROM chip, the AT28C256. So the code needs to sit in the top 16KB of this. That's why the start address for the ROM – ie, the bytes that will be written to the file – start at $8000. But the first 16KB will just be random (and will be ignored because the ROM isn't enabled at addresses below $C000). The real code starts at $C000.

Communication with the Zolatron is via serial at 9600 baud 8N1. As we're not using any form of flow control (yet) any terminal that connects to the Zolatron needs to have a slight delay after sending each character. I'm currently using 30ms, but will experiment with that. Data sent to the Zolatron should be terminated with a null character (ASCII 0) or the line end character – currently I'm using linefeed (ASCII 10, 0x0A).

The 'main' branch of the code should be fairly stable. The 'dev' branch is a work in progress. There may be other, temporary, branches created for working on specific features, but these will be merged into 'dev' once the feature is (reasonably) complete.

Old versions of the code are now in the folder Previous_Versions and are of historic interest only.

The output-nn.txt files in the _output_ folder are the output from Beebasm when the code is assembled. Just in case.

_build_ is just a small Bash script I use to save typing (and remembering) the commands to assemble the code and write it to the EEPROM. Documentation is in the script itself.

As the source file was starting to get rather long, and I got tired of scrolling, I've now carved out certain discrete parts of the code and have put them in include files, in the _include_ directory.
