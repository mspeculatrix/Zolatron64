# ROMs for the Zolatron 64

This folder will contain software designed to be run from ROMs sitting in the extended memory section starting at address $8000. They are loaded into RAM in the extended memory, using the XLOAD command or might be burned into EEPROMs.

The maximum size of each program is 8K.

The extended memory banks 0-15 can hold standalone programs, code designed to work as overlays for a program in main memory or data (such as lookup tables or whatever). Everything stored in one of these banks should start with a header block using the following structure:

```
ORG EXTMEM_START            ; $8000
.header                     ; HEADER INFO LABEL
  jmp startprog or startdata   ; Must always have this jump - see below
  equw header               ; @ $8003 Entry address
  equw reset                ; @ $8005 Reset address
  equw endcode              ; @ $8007 Addr of first byte after end of program
  equb 'E'                  ; @ $8008
  equs 0,0,0                ; -- Reserved for future use --
  equs "ZUMPUS",0           ; @ $800D Short name, max 15 chars - null terminated
.version_string
  equs "1.0",0              ; Version string - null terminated

.startprog or .startdata
.reset ; Sometimes this may be different from startprog
```

The jump at the start must always be there, even if the contents of this file is just data. In the case of data, the second and third bytes provide the address of the start of the data.

Valid codes for the byte at $8008 are:
'E' Executable program
'O' Program overlay/library
'D' Data
'X' OS extension
