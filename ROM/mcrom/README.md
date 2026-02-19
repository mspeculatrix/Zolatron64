# MCROM

**This isn't working out** The ATmega4809 is too slow. Maybe revisit this using the STM32H523CE.

The 'Microcontroller ROM' (McROM) project is an experiment in using a microcontroller as a programmable ROM for a homebrew computer (the [Zolatron](https://medium.com/machina-speculatrix/subpage/0b8cf602629b) in my case).

I've chosen the ATmega4809 as my MCU of choice because ... well, I like it.

The articles detailing the concepts and implentation are here (Medium sub required):

- [Alternatives to ROM for a homebrew computer](https://medium.com/machina-speculatrix/alternatives-to-rom-for-a-homebrew-computer-faf009bf840d)
- (more to come)

The aim is that the McROM will stay in circuit, so there are issues to be resolved around power and system signals. I'm thinking that maybe it will require powering down the computer for reprogramming, but I don't see that as a major obstacle. However, we would need to provide 5V to the MCU for reprogramming.
