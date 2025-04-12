# DUAL SERIAL BOARD

The Zolatron 64 was always going to have a serial interface. That's how it talks to me and I to it.

The first board used a 6551 ACIA. It's a age-appropriate chip for a machine that is evoking the late 1970s, and it's also very easy to program. But most versions of the 6551 do have bugs.

So I upgraded to the NXP SC28L92 DUART.

This offers numerous advantages. For a start, it provides not one but two serial ports. And it also has a whole bunch of input and output pins. (Each one is either in or out – the direction can't be switched like on a Raspberry Pi's GPIOs.)

These extra pins are intended, I believe, for tasks like controlling modems. But you can use then for whatever you want.

The SC28L92 doesn't require much in the way of support: a crystal and three caps is all you need.

I made one big mistake with this board, though. I added a pullup resistor to the RX line of port A. This was to prevent the line floating and possibly producing spurious 'inputs'. However, this is the line that I connect to the Raspberry Pi's TX pin. The Zolatron operates at 5V and the Pi at 3.3V. Yet I was effectively pulling up the Pi's TX pin to 5V all the time. Long story short, the UART on that particular Raspberry Pi no longer works.

I solved the problem by simply removing the pullup resistor. The Pi is always connected and holds that line high anyway. In future, I might be tempted to pull up that line to 3.3V on the Raspberry Pi board.

The SC28L92 is somewhat more complex than the 6551 to program – but not a lot. It is, however, obsolete. Luckily, MaxLinear (which bought Exar) offers the XR88C92 or XR88C192 which are drop-in, pin-compatible replacements (so long as you don't want the SC28L92's Motorola mode). The XR88C92 has 8-byte FIFOs, while the 192 variant matches the SC28L92's 16-byte buffers.

Aside from the DUART chip and the inevitable address decoding, the board has a buffer chip driving LEDs for the TX and RX lines of both ports. It's actually a 74LV14 Schmitt inverter, as these are active low signals.

I've also allowed for the use of pullups on the input pins – just in case.
