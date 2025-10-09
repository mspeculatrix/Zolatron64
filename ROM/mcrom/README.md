# MCROM

The 'Microcontroller ROM' (McROM) project is an experiment in using a microcontroller as a programmable ROM for a homebrew computer (the [Zolatron](https://medium.com/machina-speculatrix/subpage/0b8cf602629b) in my case).

I've chosen the ATmega4809 as my MCU of choice because ... well, I like it.

The aim is that the McROM will stay in circuit, so there are issues to be resolved around power and system signals. I'm thinking that maybe it will require powering down the computer for reprogramming, but I don't see that as a major obstacle. However, we would need to provide 5V to the MCU for reprogramming.

Alternatively, maybe we could control the CPU's `BE` and `RDY` signals, pulling them low to halt the CPU while the MCU is reprogrammed. Obviously, this can't be done from the MCU itself, so might need some kind of switch on the Zolatron or other signals coming from the dev computer. The more I think about this option the less I like it.

This version of McROM is for early development purposes only. Ultimately, the code will be moved to the Zolatron repo and the most recent versions will be there. That hasn't happened yet.
