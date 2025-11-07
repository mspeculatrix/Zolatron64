#ifndef __FLASH_FUNCTIONS_H__
#define __FLASH_FUNCTIONS_H__

#include <avr/io.h>
#include <util/delay.h>
#include "smd_std_macros.h"
#include "defines.h"
#include "functions.h"

#define FLASH_SECTOR_SIZE 4096
#define FLASH_SECTOR_ERASE_DELAY 25 // ms
#define FLASH_BYTE_DELAY 20         // us

// PROTOTYPES

void flashByteWrite(uint16_t address, uint8_t value);
void flashWrite(uint16_t address, uint8_t value);
uint8_t readFlash(uint32_t address);
void sectorErase(uint16_t startAddress);

// This is the main function to call to write a byte to memory. Makes multiple
// calls to flashWrite below.
void flashByteWrite(uint16_t address, uint8_t value) {
	FLASH_CE_ENABLE;
	flashWrite(0x5555, 0xAA);
	flashWrite(0x2AAA, 0x55);
	flashWrite(0x5555, 0xA0);
	flashWrite(address, value);
	FLASH_CE_DISABLE;
}

// Write a byte value to an address
void flashWrite(uint16_t address, uint8_t value) {
	DATA_PORT_OUTPUT;
	setAddress(address);
	DATA_PORT.OUT = value;
	CTRL_PORT.OUTCLR = FL_WE;
	_delay_us(FLASH_BYTE_DELAY); 	// pause for effect
	CTRL_PORT.OUTSET = FL_WE;
	_delay_us(FLASH_BYTE_DELAY);
	DATA_PORT_INPUT; 				// To ensure high-Z state
}

// Read a byte value from an address
uint8_t readFlash(uint32_t address) {
	uint8_t value = 0;
	setAddress(address); 					// set address bus
	FLASH_CE_ENABLE;					// enable flash chip
	FLASH_OE_ENABLE;
	_delay_us(FLASH_BYTE_DELAY);
	value = DATA_PORT.IN;
	FLASH_OE_DISABLE;
	FLASH_CE_DISABLE;					// disable flash chip
	_delay_us(FLASH_BYTE_DELAY);
	return value;
}

// Erase an entire 4KB sector starting at a given address
void sectorErase(uint16_t startAddress) {
	FLASH_CE_ENABLE;					// enable flash chip
	flashWrite(0x5555, 0xAA);
	flashWrite(0x2AAA, 0x55);
	flashWrite(0x5555, 0x80);
	flashWrite(0x5555, 0xAA);
	flashWrite(0x2AAA, 0x55);
	flashWrite(startAddress, 0x30);
	_delay_ms(FLASH_SECTOR_ERASE_DELAY);	// allow the dust to settle
	FLASH_CE_DISABLE;					// disable flash chip
}

#endif
