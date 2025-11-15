#ifndef __FLASH_FUNCTIONS_H__
#define __FLASH_FUNCTIONS_H__

#include <avr/io.h>
#include <util/delay.h>
#include "smd_std_macros.h"
#include "defines.h"
#include "functions.h"

#define FLASH_SECTOR_SIZE 4096
#define FLASH_SECTOR_ERASE_DELAY 40 // ms originally 25
#define FLASH_BYTE_DELAY 50         // us originally 20

// PROTOTYPES

void disableFlashControl(void);
void disableSDP(void);
void enableFlashControl(void);
void flashByteWrite(uint16_t address, uint8_t value);
void _flashWrite(uint16_t address, uint8_t value);
uint8_t readFlash(uint16_t address);
void sectorErase(uint16_t startAddress);
void setFlashBank(uint8_t bank);

/**
 * @brief Stop management mode of flash & return to normal operations.
 */
void disableFlashControl(void) {
	ADDRL_PORT.DIR = 0;						// Set address lines as inputs
	ADDRH_PORT.DIRCLR = ADDRH_MASK;
	DATA_PORT.DIR = 0;						// Set data lines as inputs
	FL_EN_PORT.OUTCLR = A14 | A15;			// Disable flash /CE
	FL_EN_PORT.DIRCLR = A14 | A15;			// Set these as inputs
	CTRL_PORT.OUTSET = CPU_RDY;				// Release CPU
	CTRL_PORT.OUTSET = CPU_BE;
	CTRL_PORT.OUTSET = CPU_RWB;
	CTRL_PORT.OUTSET = SYS_RES;
	CTRL_PORT.OUTSET = FL_WE;
	CTRL_PORT.OUTSET = CLK_CTRL;			// Release clock
	CTRL_PORT.DIRCLR = CTRL_PORT_MASK;		// Set CTRL pins as inputs
	resetSystem();
}

void disableSDP(void) {
	FLASH_CE_ENABLE;
	FLASH_OE_DISABLE;

	_flashWrite(0x1555, 0xAA);
	_flashWrite(0x0AAA, 0x55);
	_flashWrite(0x1555, 0x80);
	_flashWrite(0x1555, 0xAA);
	_flashWrite(0x0AAA, 0x55);
	_flashWrite(0x1555, 0x20);  // Disable SDP command

	_delay_ms(10);
	FLASH_CE_DISABLE;
}

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
	// the ROM (via its /CE). But for now, we'll set them low and do the
	// chip enabling closer to the actual operations.
	FL_EN_PORT.OUTCLR = A14 | A15;	// Set them high to enable /CE on flash
	FL_EN_PORT.DIRSET = A14 | A15;	// Set these as outputs
}

/**
 * @brief Write a byte to a single memory address
 * @param uint16_t address to store byte
 * @param uint8_t value of byte to store
 *
 * Assumes that /CE has been enabled on the flash chip and that /OE is
 * disabled. Makes multiple calls to flashWrite below.
 */
void flashByteWrite(uint16_t address, uint8_t value) {
	FLASH_CE_ENABLE;  // Enable once
	FLASH_OE_DISABLE;
	disableSDP();
	_flashWrite(0x1555, 0xAA);
	_flashWrite(0x0AAA, 0x55);
	_flashWrite(0x1555, 0xA0);
	_flashWrite(address, value);

	// Don't disable CE here! Keep it enabled for polling
	DATA_PORT_INPUT;
	setAddress(address);
	FLASH_OE_ENABLE;

	uint8_t expectedBit7 = value & 0x80;
	for (uint16_t i = 0; i < 1000; i++) {  // Shorter timeout for testing
		uint8_t readVal = DATA_PORT.IN;
		if ((readVal & 0x80) == expectedBit7) {
			break;
		}
		_delay_us(1);
	}

	FLASH_OE_DISABLE;
	DATA_PORT_OUTPUT;
	FLASH_CE_DISABLE;  // Disable CE only after everything is done
}

/**
 * @brief Write a byte value to an address
 * @param uint16_t address to write byte to
 * @param uint8_t byte value to write
 */
void _flashWrite(uint16_t address, uint8_t value) {
	setAddress(address);
	DATA_PORT.OUT = value;
	_delay_us(1); 	// make sure data is stable
	FLASH_WE_ENABLE;
	_delay_us(1); 	// pause for effect
	FLASH_WE_DISABLE;
	_delay_us(1); 	// pause for effect
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
	setAddress(address); 					// set address bus
	FLASH_CE_ENABLE;
	_delay_us(FLASH_BYTE_DELAY);
	value = DATA_PORT.IN;					// read data
	FLASH_CE_DISABLE;
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
	disableSDP();
	FLASH_CE_ENABLE;
	FLASH_OE_DISABLE;

	_flashWrite(0x1555, 0xAA);
	_flashWrite(0x0AAA, 0x55);
	_flashWrite(0x1555, 0x80);
	_flashWrite(0x1555, 0xAA);
	_flashWrite(0x0AAA, 0x55);
	_flashWrite(startAddress, 0x30);

	// Poll for completion
	DATA_PORT_INPUT;
	setAddress(startAddress);
	FLASH_OE_ENABLE;  // ← ADD THIS!

	uint32_t timeout = 100000;

	while (timeout--) {
		_delay_us(10);
		uint8_t read1 = DATA_PORT.IN;
		uint8_t read2 = DATA_PORT.IN;
		if ((read1 & 0x40) == (read2 & 0x40)) {
			break;
		}
	}

	FLASH_OE_DISABLE;
	DATA_PORT_OUTPUT;
	FLASH_CE_DISABLE;
}

/**
  * @brief Set the values of A14-A16 to select a 16K bank
  * @param uint8_t number (0-7) of bank
  *
  * A14-A16 are not connected to the system address bus, only to the flash chip.
*/
void setFlashBank(uint8_t bank) {
	FL_MEMBANK_PORT.OUT = (FL_MEMBANK_PORT.OUT & ~FL_MEMBANK_MASK) | (bank & FL_MEMBANK_MASK);
}

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
