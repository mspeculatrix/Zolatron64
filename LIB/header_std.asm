\ header_std.asm

\ Standard header for program files. Include directly after .header label.
  jmp startprog             ;
  equb <header               ; @ $0803 Entry address
  equb >header
  equb <reset                ; @ $0805 Reset address
  equb >reset
  equb <endcode              ; @ $0807 Addr of first byte after end of program
  equb >endcode
