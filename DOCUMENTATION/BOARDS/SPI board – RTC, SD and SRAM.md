# SPI BOARD – RTC, SD and SRAM

This board adds an SPI interface to the Zolatron, based around Daryl Rictor's 65SPI project. This uses an addressable ATF1504 CPLD to provide the interface. I've put this interface at address $BF00.

The board also uses a new CPLD-based address decoding solution that was developed for a future, single-board version of the Zolatron but which I'm testing out here.

There are three SPI devices on the board – a real-time clock chip (DS3234), a 64KB serial RAM (SRAM) chip (23LCV512) and an SD card drive. The RTC and SRAM chips are both battery-backed. The CR2023 battery is mounted on the rear of the board.

There are five groups of headers to connect other SPI-based devices.
