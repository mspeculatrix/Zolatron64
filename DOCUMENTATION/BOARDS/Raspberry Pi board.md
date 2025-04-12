# RASPBERRY PI BOARD



[Click to see larger version]

This board provides both serial communication with the Zolatron and persistent storage.

The Raspberry Pi Zero 2 has onboard wifi, which means I can SSH to it from anywhere. Its serial port is routed out to an edge connector (top-left in the picture) which I connect to the Zolatron's serial port via a three-strand cable.

The Pi runs the ZolaDOS program as a systemd unit. This provides persistent storage for the Zolatron, allowing me to load and save programs, dump memory contents, delete files and so on.

The Pi communicates with the Zolatron through a 65C22 VIA.

As the Pi operates at 3.3V and the Zolatron at 5V, some level shifting was required. Port B on the VIA is used for control signals. These are unidirectional. Those coming from the Pi (which are therefore at 3V3) are left alone. That's a good enough logic level for the VIA. Those coming from the VIA to the Pi (at 5V) are shifted down using resistor dividers.

Port A on the VIA is for data and this needs to be bi-directional. I'm using a 74LVC4245 for this task. Its direction pin (2) is connected to a pin on Port B of the VIA. So ZolaDOS functions on the Zolatron use this pin to determine whether the Z64 is reading or writing.

One of the Pi's GPIO pins controls a MOSFET which is capable of pulling the Zolatron's reset line low. This is invaluable if I'm working on code but don't have access to the Zolatron itself (because I'm lying on the sofa and am too lazy to get up and go to the office). If the code hangs or does something unusual, typing /r while in Zolaterm resets the machine.

Another GPIO controls an LED (via a MOSFET) and I use this to indicate whenever ZolaDOS is doing something.

And yet another GPIO uses yet another MOSFET to pull the /IRQ line low. I haven't made use of this yet, but I thought it might come in handy.
