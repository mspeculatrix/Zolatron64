# VIA BOARD

The 'V' in VIA stands for 'versatile', and the 65C22 certainly lives up to its name. (The other two letters stand for 'interface adapter', in case you were wondering.)

The VIA is the heart of both the Raspberry Pi and parallel interface boards. But it can also serve as a general-purpose interface – much along the lines of the GPIO pins on a Raspberry Pi or Arduino, or the User Port on a BBC Micro.

The 65C22 has two eight-bit ports, each of which is accompanied by two control pins that are used for clever things like interrupts and utilising built-in shift registers.

The chip also offers two counters which I find I use quite a lot more than I imagined I would. For example, when talking to the Raspberry Pi via the ZolaDOS protocol, I use the timers for time-outs, so that routines don't hang up forever in the case of an error.

On this board, I've broken out the port pins, plus +5V and GND pins, to header pins and also IDC-style connectors.

In the Zolatron, one of these boards is being used to manage a 20x4 character LCD display and five status LEDs. Its main timer is employed to implement a delay function.

A second board is intended as a general-purpose 'user port' and its timers are available for user programs.

## LCD Board

The copy of the board used for the LCD panel has the following connections:

### PORT A

| PIN | FRONT PANEL              |
|-----|--------------------------|
| PA0 | LED_ERR                  |
| PA1 | LED_BUSY                 |
| PA2 | LED_OK                   |
| PA3 | LED_FILE_ACT             |
| PA4 | LED_DEBUG                |
| PA5 | LCD RS - Register select |
| PA6 | LCD RW - Read/Write      |
| PA7 | LCD E  - Execute         |

### PORT B

Pins PB0-7 connect to the LCD's Data pins 0-7.
