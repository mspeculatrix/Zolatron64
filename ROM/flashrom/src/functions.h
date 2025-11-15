#ifndef __FUNCTIONS_H__
#define __FUNCTIONS_H__

#include <avr/io.h>
#include <util/delay.h>
#include "defines.h"
#include "smd_avr0_serial.h"

extern SMD_AVR0_Serial serial;

// PROTOTYPES
bool checkForMessage(const char* msg, char* buf);
void clearBuf(char* buf, uint8_t len);
uint8_t getCommand(char* buf);
uint16_t getWord(void);
void resetSystem(void);
void sendWord(uint16_t word);
void setAddress(uint16_t addr);

// Look for a specific incoming message. Wrapper to getCommand()
// Returns false if it doesn't get what it's looking for.
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
uint16_t getWord(void) {
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

// Strobe the reset pin (which is attached to the Zolatron's system
// reset line) low.
void resetSystem(void) {
	CTRL_PORT.DIRSET = SYS_RES; // set as output
	CTRL_PORT.OUTCLR = SYS_RES; // Take low
	_delay_ms(250);
	CTRL_PORT.OUTSET = SYS_RES; // Take high
	CTRL_PORT.DIRCLR = SYS_RES; // set as input
}

// Set a 14-bit address on the address pins.
// We're only using 14-bit addresses because we're
// only writing 16KB images.
void setAddress(uint16_t addr) {
	ADDRL_PORT.OUT = (uint8_t)(addr & 0x00FF);
	ADDRH_PORT.OUT = ADDRH_MASK & (uint8_t)(addr >> 8);
}

// Send a 16-bit integer, MSB-first.
void sendWord(uint16_t word) {
	serial.sendByte((uint8_t)(word >> 8));		// MSB
	serial.sendByte((uint8_t)(word & 0x00FF));	// LSB
}

// void setAddrPortDir(uint8_t dir) {
// 	if (dir == ADDR_PORT_INPUT) {			// INPUT
// 		ADDRL_PORT.DIR = 0;
// 		ADDRH_PORT.DIRCLR = ADDRH_MASK;
// 	} else {								// OUTPUT
// 		ADDRL_PORT.DIR = 0xFF;
// 		ADDRH_PORT.DIRSET = ADDRH_MASK;
// 	}
// }
#endif
