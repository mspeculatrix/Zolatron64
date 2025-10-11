# PARALLEL INTERFACE BOARD

Does the Zolatron 64 really need a parallel interface? Well, when it comes to homebrew and retro computers, need has very little to do with it. It wants one.

Adding a parallel interface to the Zolatron is an extension of my playing around with my Epson MX-80 FT/III dot matrix printer. Previous projects include a microcontroller-based interface and using an HP JetDirect.

There's really not a lot to adding a printer interface. My board is based around the good ol' 65C22 VIA, one port of which provides the data output and the other handles the various control signals, the most important of which are /STROBE and BUSY.

The board has a couple of buffer chips – 74LV541 devices. A printer is a noisy thing, audibly, and I thought the same might be true electrically, so I decided to play safe. The chips are permanently enabled, so that they just pass through signals transparently.

Four of the signals – Error, Offline, Autofeed and Paper Out – are also buffered through a 74LV14 inverter IC to drive LEDs.

The printer plugs in via a DB25 connector. Of course, it could be something other than a printer. The control signals are configured with printing in mind, but ultimately it's just a parallel port, so could find other uses. It's really all down to software.

## Optional extra

The parallel board is not considered to be part of the Zolatron's basic spec. During boot-up, the OS tries writing a series of test values to one of the the VIA's registers (the Port A data direction register), and reads them back. If the read values are the same as the written values, the OS assumes the board is present and sets a flag in the SYS_REG register.
