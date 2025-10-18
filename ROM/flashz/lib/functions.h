#ifndef __FUNCTIONS_H__
#define __FUNCTIONS_H__

#include <avr/io.h>
#include <util/delay.h>
#include "defines.h"
#include "smd_avr_serial4809.h"

extern SMD_AVR_Serial4809 serial;

// PROTOTYPES
bool checkForMessage(const char* msg, char* buf);
void clearBuf(char* buf, uint8_t len);
void disableFlashControl();
void enableFlashControl();
uint8_t getCommand(char* buf);
uint16_t getWord();
void resetSystem();
void sendWord(uint16_t word);
void setAddress(uint16_t addr);

// Look for a specific incoming message. Wrapper to getCommand()
// Returns flase if it doesn't get what it's looking for.
bool checkForMessage(const char* msg, char* buf) {
	bool error = false;
	getCommand(buf);
	if (!strcmp(buf, msg) == 0) {
		error = true;
	}
	return error;
}

// Clear any buffer you like by writing zeros to it.
void clearBuf(char* buf, uint8_t len) {
	for (uint8_t i = 0; i < len; i++) {
		buf[i] = 0;
	}
}

void disableFlashControl() {
	// Set CTRL_PORT as inputs except SYS_RES
	ADDRL_PORT.DIR = 0;
	ADDRH_PORT.DIRCLR = 0b00111111;
	DATA_PORT.DIR = 0;
	FL_EN_PORT.DIRCLR = A14 | A15;	// Set these as inputs
	CTRL_PORT.OUTSET = CPU_RDY;
	CTRL_PORT.OUTSET = CLK_CTRL;
	CTRL_PORT.DIRCLR = CTRL_PORT_MASK;
	resetSystem();
}

void enableFlashControl() {

	// Set initial states for control pins
	CTRL_PORT.OUTCLR = CPU_BE;		// To free buses
	CTRL_PORT.OUTSET = CPU_RDY; 	// We'll set this low later
	CTRL_PORT.OUTSET = CLK_CTRL; 	//  "     "   "    "    "
	CTRL_PORT.OUTCLR = CPU_RWB;		// Set low to disable /READ_EN
	CTRL_PORT.OUTSET = SYS_RES;		// Ensure reset high
	CTRL_PORT.OUTSET = FL_WE;		// Disable writes by default

	// We'll also want to drive A14 & A15 high to enable the flash chip
	FL_EN_PORT.DIRSET = A14 | A15;	// Set these as outputs
	FL_EN_PORT.OUTCLR = A14 | A15;	// Set them low by default

	CTRL_PORT.DIRSET = CTRL_PORT_MASK;	// Set CTRL pins as outputs

	// Stop the CPU - Need a slight pause here?
	_delay_us(50);
	CTRL_PORT.OUTCLR = CPU_RDY; 		// Take RDY low - stop CPU
	CTRL_PORT.OUTCLR = CLK_CTRL;		// Stops the clock in high state

	// Set the address bus pins to outputs
	ADDRL_PORT.DIR = 0b11111111; 		// A0-A7
	ADDRH_PORT.DIRSET = 0b00111111;		// A8-A13

	// Enable the data bus pins
	DATA_PORT.DIR = 0b11111111;			// D0-D7
	DATA_PORT.OUTCLR = 0b11111111;
}

// Checks for characters coming in over serial and adds them to the given
// command buffer. It's used for commands only.
// Returns the number of chars received, although I don't think I do anything
// with that information right now.
// Returns when it encounters a linefeed or the buffer is full.
uint8_t getCommand(char* buf) {
	clearBuf(buf, CMD_BUF_LEN);
	bool recvd = false;
	uint8_t idx = 0;
	uint8_t inChar = 0;
	while (!recvd && idx < CMD_BUF_LEN) {
		if (serial.readByte(&inChar)) {
			if (inChar == NEWLINE && idx > 0) {
				buf[idx] = 0;	// terminate
				recvd = true;
			} else if (inChar == CR) {
				// ignore carriage returns
			} else {
				buf[idx] = inChar;
				idx++;
			}
		}
	}
	return idx;
}

// Retrieve two bytes from the serial input and return as uint16_t integer.
// Blocking. It won't return until it has received two bytes.
uint16_t getWord() {
	uint16_t word = 0;
	uint8_t byteCount = 2; // because MSB first
	uint8_t wordBuf[2];
	while (byteCount > 0) {
		if (serial.inWaiting()) {
			byteCount--;
			wordBuf[byteCount] = serial.getByte();
		}
	}
	word = (wordBuf[1] << 8) + wordBuf[0];
	return word;
}

// Pulse the reset pin (which is attached to the Zolatron's system
// reset line) low.
void resetSystem() {
	CTRL_PORT.DIRSET = SYS_RES; // set as output
	CTRL_PORT.OUTCLR = SYS_RES; // Take low
	_delay_ms(50);
	CTRL_PORT.OUTCLR = SYS_RES; // Take high
	CTRL_PORT.DIRCLR = SYS_RES; // set as input
}

// Set a 14-bit address on the address pins. Assumes that
// enableAddressBusCtrl() has already been called.
// We're only using 14-bit addresses because we're
// only writing 16KB images.
void setAddress(uint16_t addr) {
	ADDRL_PORT.OUT = uint8_t(addr);
	addr = addr >> 8;
	ADDRH_PORT.OUT = uint8_t(addr);
}

// The bank param should be 0-7
void setBank(uint8_t bank) {
	BANK_ADDR_PORT.OUT = (BANK_ADDR_PORT.OUT & ~BANK_ADDR_MASK) | (bank & BANK_ADDR_MASK);
}

// Send a 16-bit integer, MSB-first.
void sendWord(uint16_t word) {
	serial.sendByte((uint8_t)(word >> 8));		// MSB
	serial.sendByte((uint8_t)(word & 0x00FF));	// LSB
}

#endif
