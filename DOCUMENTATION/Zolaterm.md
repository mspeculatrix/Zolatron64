# ZOLATERM

The Zolatron's serial interface allows it to be accessed by any computer with a TTL-level serial port.

However, I decided it would be useful to have a dedicated machine – a Raspberry Pi Zero 2 – hooked up to the Zolatron so that I could SSH into this machine and get a console session from anywhere on my home network. This RPi is mounted on its own board on the backplane.

At first, I used a bunch of terminal programs, such as Minicom, to communicate with the Zolatron. In the end, though, to save time with configuring & whatnot, and also to allow me to add some custom features, I wrote my own terminal program in Go.

Most of it is pretty straightforward. The program works in line mode – ie, it sends text when you hit <return>. This does present some input limitations (such as always having to press return for an input) but is somewhat inevitable when you're working in a terminal session on the client machine.

The program intercepts single-character commands starting with '/' and treats these as local commands. For example, '/g' toggles logging of the session (it's on by default).

One notable, and especially useful, local command is '/r'. This briefly takes one of the Pi's GPIO pins high which, in turn, strobes a MOSFET on the RPi board. This momentarily pulls the Zolatron's /RST line low, resetting the machine.

This has proven to be a lifesaver. When I'm lying on the sofa in the living room, developing a program for the Zolatron, and the code turns out to be somewhat less than optimal (ie, it hangs the machine or goes into an infinite loop), I can reboot the machine without clambering two floors up to the office. Because the '/r' command is local – ie, it's handled entirely by the RPi. It doesn't matter if the Zolatron is having a brainstorm and spewing all kinds of garbage to the screen (trust me, it's happened), the '/r' command always gets through to the RPi and resets the Zolatron.

The other useful feature is that Zolaterm automatically converts lowercase input to uppercase. The Zolatron requires uppercase commands.

The Zolaterm code is available on GitHub.
