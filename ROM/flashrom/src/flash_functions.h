#ifndef __FLASH_FUNCTIONS_H__
#define __FLASH_FUNCTIONS_H__

#include <avr/io.h>
#include <util/delay.h>
#include "smd_std_macros.h"
#include "defines.h"
#include "functions.h"

#define FLASH_SECTOR_SIZE 4096
#define FLASH_SECTOR_ERASE_DELAY 25 // ms - MAX is 25ms
#define FLASH_BYTE_DELAY 15         // us - MAX byte program time is 20us
#define FLASH_READ 1
#define FLASH_WRITE 0

extern uint8_t flashBank;

// PROTOTYPES
uint16_t addrSet(uint16_t addr);
void disableFlashControl(void);
// void disableSDP(void);
void enableFlashControl(void);
void flashByteWrite(uint16_t address, uint8_t value);
void _flashWrite(uint16_t address, uint8_t value);
uint8_t readFlash(uint16_t address);
void sectorErase(uint16_t startAddress);
void setFlashBank(void);

/**
 * @brief set the FA14 signal according to the address selected.
 * @param uint16_t addr - the address desired
 * @retval uint16_t just returns the parameter value.
 *
 * The main address bus connection between the MCU and the flash ROM is
 * 14-bit (A0-A13). But when we're writing commands to the flash chip, such
 * as 0x5555, we need to be able to set a 15-bit address. So this function
 * decides whether we need to set the FA14 output on the MCU, which connects
 * to A14 on the flash chip.
 * NB: This can leave the FA14 output set high. You may need to ensure it's
 * reset low at some point after this function is called.
 */
uint16_t addrSet(uint16_t addr) {
	if (addr & (1 << 14)) { 	// Check if the desired address has bit 14 set
		FL_MEMBANK_PORT.OUTSET = FA14; 		// If so, set A14 on the flash chip
	} else {
		FL_MEMBANK_PORT.OUTCLR = FA14; 		// Otherwise ensure it's unset.
	}
	return addr;
}

/**
 * @brief Stop management mode of flash & return to normal operations.
 */
void disableFlashControl(void) {
	ADDRL_PORT.DIR = 0;						// Set address lines as inputs
	ADDRH_PORT.DIRCLR = ADDRH_MASK;
	DATA_PORT.DIR = 0;						// Set data lines as inputs
	FL_EN_PORT.OUTCLR = A14 | A15;			// Disable flash /CE, take lines low
	FL_EN_PORT.DIRCLR = A14 | A15;			// Set these as inputs
	CTRL_PORT.OUTSET = CPU_RDY;				// Release CPU
	CTRL_PORT.OUTSET = CPU_BE;				// Release buses
	CTRL_PORT.OUTSET = CPU_RWB;				// Set R/W to read
	CTRL_PORT.OUTSET = FL_WE;				// Disable flash writes
	CTRL_PORT.OUTSET = CLK_CTRL;			// Release clock
	CTRL_PORT.DIRCLR = CTRL_PORT_MASK;		// Set CTRL pins as inputs
}

/**
 * @brief Disable Software Data Protection
 */
 // void disableSDP(void) {
 // 	FLASH_CE_ENABLE;
 // 	FLASH_OE_DISABLE;

 // 	_flashWrite(0x1555, 0xAA);
 // 	_flashWrite(0x0AAA, 0x55);
 // 	_flashWrite(0x1555, 0x80);
 // 	_flashWrite(0x1555, 0xAA);
 // 	_flashWrite(0x0AAA, 0x55);
 // 	_flashWrite(0x1555, 0x20);  // Disable SDP command

 // 	_delay_ms(10);
 // 	FLASH_CE_DISABLE;
 // }

 /**
  * @brief Halt computer & setup flash for management operations.
  */
void enableFlashControl(void) {
	CTRL_PORT.DIRSET = CTRL_PORT_MASK;	// Set CTRL pins as outputs
	// Set initial states for control pins
	CTRL_PORT.OUTSET = CPU_RDY; 		// We'll set this low later
	CTRL_PORT.OUTSET = CLK_CTRL; 		//  "     "   "    "    "
	CTRL_PORT.OUTCLR = CPU_RWB;			// Disable /OE
	CTRL_PORT.OUTSET = SYS_RES;			// Ensure reset high
	CTRL_PORT.OUTSET = FL_WE;			// Disable /WE
	CTRL_PORT.OUTCLR = CPU_BE;			// Pull low to free buses
	CTRL_PORT.OUTCLR = CPU_RDY; 		// Take RDY low - stops CPU
	_delay_ms(100);
	CTRL_PORT.OUTCLR = CLK_CTRL;		// Stop the clock in a high state

	// Set the address bus to outputs & low
	ADDRL_PORT.DIR = 0xFF;		 		// A0-A7 as outputs
	ADDRH_PORT.DIRSET = ADDRH_MASK;		// A8-A13 as outputs
	ADDRL_PORT.OUT = 0;					// set low
	ADDRH_PORT.OUTCLR = ADDRH_MASK;		// set low
	// Enable the data bus as output, low
	DATA_PORT.DIR = 0xFF;				// D0-D7 as outputs
	DATA_PORT.OUT = 0;					// set low

	// A14 & A15 are used for ROM decoding. We set them both high to select
	// /ROM_ENABLE via the system's ROM/RAM decoding chip. This signal is
	// connected to the ROM via its /CE pin.
	// Initially, we'll set these signals (so the flash ROM isn't enabled) and
	// do the chip enabling closer to the read & write actual operations.
	FL_EN_PORT.OUTCLR = A14 | A15;	// Set them high to enable /CE on flash
	FL_EN_PORT.DIRSET = A14 | A15;	// Set these as outputs
}

/**
 * @brief Write a byte to a single memory address
 * @param uint16_t address to store byte
 * @param uint8_t value of byte to store
 *
 * Assumes that /CE has been enabled on the flash chip and that /OE is
 * disabled. Makes multiple calls to _flashWrite below.
 */
void flashByteWrite(uint16_t address, uint8_t value) {
	FLASH_CE_ENABLE;
	_flashWrite(addrSet(0x5555), 0xAA);
	_flashWrite(addrSet(0x2AAA), 0x55);
	_flashWrite(addrSet(0x5555), 0xA0);
	setFlashBank(); 		// because we messed with FA14
	// FL_MEMBANK_PORT.OUTCLR = FA14; 	// ensure this is off after using addrSet()
	_flashWrite(address, value);
	_delay_us(FLASH_BYTE_DELAY);
	FLASH_CE_DISABLE;
}

/**
 * @brief Write a byte value to an address
 * @param uint16_t address to write byte to
 * @param uint8_t byte value to write
 */
void _flashWrite(uint16_t address, uint8_t value) {
	// Ensure data port is output and /OE is disabled
	DATA_PORT_OUTPUT;
	setAddress(address);
	DATA_PORT.OUT = value;
	_delay_us(1); // tried 1, 10 - not helping
	FLASH_WE_ENABLE;
	_delay_us(10); // tried 1, 10, 20
	FLASH_WE_DISABLE;
	_delay_us(10);
}

/**
 * @brief Read a byte value from an address
 * @param uint16_t address of memory byte to read
 * @retval uint8_t byte value at address
 *
 * Assumes that /CE and /OE have been enabled on the flash chip.
 */
uint8_t readFlash(uint16_t address) {
	uint8_t value = 0;
	DATA_PORT_INPUT;
	setAddress(address);
	FLASH_CE_ENABLE;
	FLASH_OE_ENABLE;
	_delay_us(1);
	value = DATA_PORT.IN;
	FLASH_OE_DISABLE;
	FLASH_CE_DISABLE;
	DATA_PORT_OUTPUT;
	return value;
}

/**
 * @brief Erase an entire 4KB sector starting at a given address
 * @param uint16_t start address of sector
 *
 * Assumes that /CE has been enabled on the flash chip and that /OE is
 * disabled.
 */
void sectorErase(uint16_t startAddress) {
	FLASH_OE_DISABLE;
	FLASH_CE_ENABLE;
	_flashWrite(addrSet(0x5555), 0xAA);
	_flashWrite(addrSet(0x2AAA), 0x55);
	_flashWrite(addrSet(0x5555), 0x80);
	_flashWrite(addrSet(0x5555), 0xAA);
	_flashWrite(addrSet(0x2AAA), 0x55);
	// FL_MEMBANK_PORT.OUTCLR = FA14; 	// ensure this is off after using addrSet()
	setFlashBank(); 		// because we messed with FA14
	_flashWrite(startAddress, 0x30);
	_delay_ms(FLASH_SECTOR_ERASE_DELAY);
	// // Poll for completion
	// DATA_PORT_INPUT;
	// setAddress(startAddress);
	// FLASH_OE_ENABLE;
	// uint32_t timeout = 100000;
	// while (timeout--) {
	// 	_delay_us(10);
	// 	uint8_t read1 = DATA_PORT.IN;
	// 	uint8_t read2 = DATA_PORT.IN;
	// 	if ((read1 & 0x40) == (read2 & 0x40)) {
	// 		break;
	// 	}
	// }
	// FLASH_OE_DISABLE;
	// DATA_PORT_OUTPUT;

	FLASH_CE_DISABLE;
}

/**
  * @brief Set the values of A14-A16 to select a 16K bank
  * @param uint8_t number (0-7) of bank
  *
  * FA14-FA16 are not connected to the system address bus, only to the
  * flash chip.
  * This code works because the three pins are the lowest three in the port
  * (ie, 0, 1 and 2). If pins higher up in the port are used, it will need
  * amending.
*/
void setFlashBank(void) {
	const uint8_t pin_mask = FA14 | FA15 | FA16;
	FL_MEMBANK_PORT.OUTCLR = pin_mask; // set to 0
	FL_MEMBANK_PORT.OUT |= flashBank & pin_mask;
}

/**
 * @brief Set input signals on flash ROM to select either READ or WRITE mode
 * @param uint_t mode - FLASH_READ or FLASH_WRITE
 */
void setFlashRW(uint8_t mode) {
	if (mode == FLASH_READ) {			// READ mode
		CTRL_PORT.OUTSET = FL_WE;		// Disable /WE
		CTRL_PORT.OUTSET = CPU_RWB;		// Enable /OE
		DATA_PORT.DIR = 0;				// Data port to input
	} else {							// WRITE mode
		CTRL_PORT.OUTCLR = CPU_RWB;		// Disable /OE
		// We don't set FL_WE because that needs to be done on a byte-by-byte
		// basis.
		DATA_PORT.DIR = 0xFF;			// Data port to output
	}
	_delay_us(100);	// Don't think this is necessary - for testing
}

#endif
