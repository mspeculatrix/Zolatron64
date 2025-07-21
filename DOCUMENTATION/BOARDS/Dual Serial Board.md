# DUAL SERIAL BOARD

The Zolatron 64 was always going to have a serial interface. That's how it talks to me and I to it.

The first board used a 6551 ACIA. It's a age-appropriate chip for a machine that is evoking the late 1970s, and it's also very easy to program. But most versions of the 6551 do have bugs.

So I upgraded to the NXP SC28L92 DUART.

This offers numerous advantages. For a start, it provides not one but two serial ports. And it also has a whole bunch of input and output pins. (Each one is either in or out – the direction can't be switched like on a Raspberry Pi's GPIOs.)

These extra pins are intended, I believe, for tasks like controlling modems. But you can use them for whatever you want.

The SC28L92 doesn't require much in the way of support: a crystal and three caps is all you need.

I made one big mistake with this board, though. I added a pullup resistor to the RX line of port A. This was to prevent the line floating and possibly producing spurious 'inputs'. However, this is the line that I connect to the Raspberry Pi's TX pin. The Zolatron operates at 5V and the Pi at 3.3V. Yes - I was pulling up the Pi's TX pin to 5V all the time. Long story short, the UART on that particular Raspberry Pi no longer works.

I solved the problem by simply removing the pullup resistor. The Pi is always connected and holds that line high anyway. In future, I might be tempted to pull up that line to 3.3V on the Raspberry Pi board.

The SC28L92 is somewhat more complex than the 6551 to program – but not a lot. It is, however, obsolete. Luckily, MaxLinear (which bought Exar) offers the XR88C92 or XR88C192 which are drop-in, pin-compatible replacements (so long as you don't want the SC28L92's Motorola mode). The XR88C92 has 8-byte FIFOs, while the 192 variant matches the SC28L92's 16-byte buffers. (Dammmit. XR88C192 is now also obsolete. Try https://www.ti.com/lit/ds/symlink/tl28l92.pdf?ts=1745106137548)

Aside from the DUART chip and the inevitable address decoding, the board has a buffer chip driving LEDs for the TX and RX lines of both ports. It's actually a 74LV14 Schmitt inverter, as these are active low signals.

I've also allowed for the use of pullups on the input pins – just in case.

## How it works

The Zolatron has the chip at base address $B400.

The chip's registers are at the following addresses:

Registers for GENERAL operations

- SC28L92_MRA       $B400 Mode Register A
- SC28L92_MRB       $B408 Mode Register B
- SC28L92_ACR       $B404 Auxiliary Control Register
- SC28L92_IMR       $B405 Interrupt mask register
- SC28L92_ISR       $B405 Interrupt status register

Registers for READ operations - /RD_EN = 0

- SC28L92_SRA       $B401 Status Register A
- SC28L92_RxFIFOA   $B403 RX Holding Register A
- SC28L92_IPCR      $B404 Input Port Change Register
- SC28L92_CTU       $B406 Counter/Timer Upper
- SC28L92_CTL       $B407 Counter/Timer Lower
- SC28L92_SRB       $B409 Status Register B
- SC28L92_RxFIFOB   $B40B RX Holding Register B
- SC28L92_MISC_R    $B40C Miscellaneous register
- SC28L92_IPR       $B40D Input Port Register
- SC28L92_STRT_CNTR $B40E Start counter command
- SC28L92_STOP_CNTR $B40F Stop counter command

Registers for WRITE operations - /WR_EN = 0

- SC28L92_CSRA      $B401 Clock Select Register A
- SC28L92_CRA       $B402 Command Register A
- SC28L92_TxFIFOA   $B403 TX Holding Register A
- SC28L92_CTPU      $B406 C/T Upper Preset Register
- SC28L92_CTPL      $B407 C/T Lower Preset Register
- SC28L92_CSRB      $B409 Clock Select Register B
- SC28L92_CRB       $B402 Command Register B
- SC28L92_TxFIFOB   $B403 TX Holding Register B
- SC28L92_OPCR      $B40D Output Port Config Register
- SC28L92_SOPR      $B40E Set Output Ports Bits cmd
- SC28L92_ROPR      $B40F Reset Output Ports Bits cmd

### Sending a byte

To send a byte, you do the following:

1. Check the status register SC28L92_SRA
2. AND it with SC28L92_TxRDY bit %00000100
3. if that bit isn't set, loop back to 1
4. Write the byte to SC28L92_TxFIFOA

### Receiving a byte

The interrupt will have been triggered.

- Load the SC28L92_ISR register.
- AND with bit DUART_RxA_RDY_MASK - %00000010
- If the bit is set, yes it's the Serial Port
- Get the byte from the incoming FIFO at SC28L92_RxFIFOA
- If the byte is a NULL (0)
  - Load the STDIN_STATUS_REG
  - set the null byte received flag DUART_RxA_NUL_RCVD_FL %00000001
  - Resave the register
- Load the SC28L92_SRA status reg to see if more bytes waiting
- AND with the #SC28L92_RxRDY RxRDY bit
  - If it's still set, there's more data...
