# EXTENDED MEMORY BOARD

It's not that the Zolatron 64 is exactly short of memory: 16KB of ROM and 32KB of RAM is a lot more than you think, especially when you're writing all the code yourself in 6502 assembly.

It's that there was this 8KB blank space in the memory map that I'd originally labelled as 'for future expansion' – which is another way of saying 'I can't think what to do with this'.

And then I got to thinking about the BBC Micro's shadow RAM and sideways ROMs. I'm not up to that kind of sophistication, but I thought some kind of banked memory would be within my grasp. Turned out to be one of the easiest things I've implemented on this machine.

At the heart of it is an AS6C1008 128KB RAM chip. The contents of this chip get paged into the Zolatron's memory map starting at address $8000 and going up to $9FFF. That's an 8KB space, so the RAM chip effectively holds 16 'banks' of memory which can be used one at a time.

The decoding for all this chicanery is handled by a CPLD (an ATF1502AS). The code for this creates four latches that are connected to the top four address pins of the RAM chip. That allows us to set a four-bit value (0-15) which then selects which part of the chip's memory we're addressing.

The CPLD also decodes the address $BFE0. Writing to this address sets the latches. So, to select, say, bank 3, you simply write the value 3 to the address $BFE0 – something like:

```asm
lda #3
sta $BFE0
```

Naturally, the CPLD decodes for the address $8000 in order to set the RAM's chip enable line. But in fact the CPLD has not one but five chip enable outputs. And this is because I decided to add four ROM sockets.

The ROMs offer an alternative to the first four banks (0-3) of the RAM.

Which chip enable line is selected (by the CPLD) depends on which bank is selected. If any of banks 0-3 is chosen, then the corresponding chip enable signal (CEN0 to CEN3) is active. If any of banks 4-15 is chosen, line CEN4 is active. The signals CEN0 to CEN3 are each connected either to one ROM or to CEN4 – depending on the position of a jumper. CEN4 is connected to the RAM.

Let's take bank 2 as an example. If the jumper is in one position, CEN2 will activate the chip enable on ROM 2, but isn't connected to the RAM. If the jumper is in the other position, CEN2 connects to CEN4 and therefore to the RAM, leaving ROM 2 unconnected and not activated.

There's one slight issue. The chip enable signals are active low. To prevent spurious enabling of chips, these signals need to be pulled high by default.

For any ROM that shouldn't be active, the corresponding chip enable pin on the CPLD will naturally be set high. But this creates its own problem. With all the chip enable lines ultmately connected to CEN4, enabling the RAM became impossible because that line would be pulled low and high at the same time (assuming that not all four of the ROM sockets are in use).

My first solution was to add diodes to the chip enable lines so that they can pull lines low but won't drive them high. Then I added pullup resistors on the ROM side of the jumpers. When a ROM is not connected (the jumper is selecting RAM for that bank), the ROM will be rendered inactive by the pullup but the pullup is isolated from CEN4.

After much discussion on 6502.org, another possibly solution came up – making the chip enable outputs from the CPLD open collector. They would then pull lines low when needed but would otherwise float. As discussed in my blog post, I actually implemented this in the CUPL code for the CPLD, but haven't tested it yet. The diode method is working fine.

ZolaDOS has a number of CLI commands to manage the extended memory, and it's easy to incorpporate into user code, too.

## Optional extra

The extended memory board is not regarded as standard equipment on the Zolatron. During boot-up, the Zolatron checks for the existence of the board by selecting a bank that is never configured as ROM, writing a sequence of values to $8000 and reading them back. If the read values are the same as the written ones, the machine assumes that the board is present and sets a flag in the SYS_REG register. It also prints a message to indicate whether the board is present.

## Boot ROM

Also on boot-up, the OS selects bank 0 and looks to see if there's a boot ROM present. It does this by examining address $8000 and looking for the value $4C (a JMP instruction). If it finds that, it examines address $8003, which is where the file type code lives. If it finds a 'B' (hex value $42), it assumes that this is a boot ROM and attempts to execute the code at $8000. If there isn't a boot ROM present, and those values existed by a pure fluke, the Zolatron is not going to have its best day.
