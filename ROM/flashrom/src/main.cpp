
#ifndef __AVR_ATmega4809__
#define __AVR_ATmega4809__
#endif

#ifndef F_CPU
#define F_CPU 20000000UL // 20 MHz unsigned long
#endif

#include <avr/io.h>
#include <stdio.h>
#include <stdlib.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <string.h>
#include "src/defines.h"
#include "src/smd_avr0_serial.h"
#include "src/functions.h"
#include "src/flash_functions.h"

/*******************************************************************************
*****   GLOBALS                                                            *****
*******************************************************************************/

uint16_t dataSize = 0;			// size of incoming data
uint8_t dataChunk[CHUNKSIZE];	// for buffering incoming data
uint8_t flashBank = 0;

SMD_AVR0_Serial serial = SMD_AVR0_Serial(SERIAL_BAUDRATE);

/*******************************************************************************
*****   MAIN                                                               *****
*******************************************************************************/
int main(void) {

	//--------------------------------------------------------------------------
	//-----   SETUP                                                        -----
	//--------------------------------------------------------------------------

	CCP = CCP_IOREG_gc;     // Unlock protected registers
	CLKCTRL.MCLKCTRLB = 0;  // No prescaling, full main clock frequency

	// Set up control pins
	disableFlashControl();
	FL_MEMBANK_PORT.DIRSET = FA14 | FA15 | FA16; // Bank memory pins as outputs
	FL_MEMBANK_PORT.OUTCLR = FA14 | FA15 | FA16; // Set low by default
	setFlashBank();

	serial.begin();

	char cmdBuf[CMD_BUF_LEN]; 	// For receiving commands from remote PC
	bool cmdRecvd = false;		// Message received flag

	_delay_ms(500);				// Allow for Zolatron to settle on power-up then
	resetSystem();				// reset to ensure MCU is fully running first

	/***************************************************************************
	******   MAIN LOOP													   *****
	***************************************************************************/

	while (1) {
		if (cmdRecvd) {
			serial.clearInputBuffer();
			enableFlashControl();
			// serial.write("ACKN");
			if (strcmp(cmdBuf, "BURN") == 0) {
				// -------------------------------------------------------------
				// ----- BURN - Download data & write to Flash -----------------
				// -------------------------------------------------------------
				serial.write("ACKN");
				dataSize = 0; 				// reset
				bool error = false;
				error = checkForMessage("SIZE", cmdBuf);
				if (!error) {
					serial.write("SIZE"); 	// Send back 'SIZE' to confirm
					dataSize = getWord();	// Get two bytes with the data size
					sendWord(dataSize);		// Send back as confirmation
					error = checkForMessage("WFLS", cmdBuf);
					if (!error) {
						serial.write("WFLS"); 		// Send back as confirmation
					} else {
						serial.write("EB01");
					}
					// RECEIVE DATA
					if (!error) {
						uint16_t bytesWritten = 0;	// bytes written to Flash
						uint16_t fileIdx = 0;	// next byte in incoming data
						uint8_t chunkIdx = 0;	// index within chunk buffer
						// disableSDP();
						setFlashRW(FLASH_WRITE);	// set flash write mode
						while (bytesWritten < dataSize) {
							bool gotChunk = false;
							while (!gotChunk) {
								if (serial.inWaiting()) {
									dataChunk[chunkIdx] = serial.getByte();
									chunkIdx++;
									fileIdx++;
									if (chunkIdx == CHUNKSIZE
										|| fileIdx == dataSize) {
										// If we've received a chunk's worth
										// OR we're at the end of the incoming
										// data
										gotChunk = true;
									}
								}
							}
							// chunkIdx now contains how many bytes we have that
							// need to be written.
							// It may be less than the chunksize if it's the
							// last chunk.

							// check if we're at a sector boundary
							// - if so, erase sector
							if (bytesWritten % FLASH_SECTOR_SIZE == 0) {
								sectorErase(bytesWritten);
							}

							// write chunk bytes
							for (uint8_t i = 0; i < chunkIdx; i++) {
								flashByteWrite(bytesWritten, dataChunk[i]);
								bytesWritten++;
							}
							chunkIdx = 0;
							if (bytesWritten == dataSize) {
								serial.write("EODT"); // all bytes received
							} else {
								serial.write("ACKN"); // prompt sending of next chunk
							}
						}
						// CHECK DATA
						// Send back the first 16 bytes.
						// Read each one from RAM and send it across serial.
						serial.write("VRFY");
						setFlashRW(FLASH_READ);
						for (uint16_t addr = 0; addr < 16; addr++) {
							uint8_t testVal = readFlash(addr);
							serial.sendByte(testVal);
						}
						FLASH_OE_DISABLE;					// disable output
					}
				} else {
					serial.write("SERR");
				}
			} else if (strcmp(cmdBuf, "BANK") == 0) {
				// -------------------------------------------------------------
				// ----- BANK - Set memory bank            ---------------------
				// -------------------------------------------------------------
				serial.write("ACKN");
				// Get the bank number
				uint8_t bank = 0;
				bool recvd = getByte(&bank);
				if (recvd) {
					serial.write("BSET");
					flashBank = bank;
					setFlashBank();
				} else {
					serial.write("*ERR");
				}
			} else if (strcmp(cmdBuf, "CLRF") == 0) {
				// -------------------------------------------------------------
				// ----- CLRF - Clear flash                ---------------------
				// -------------------------------------------------------------
				// Clear the Flash memory.
				serial.write("ACKN");
				for (uint8_t sector = 0; sector < SECTORS_PER_IMG; sector++) {
					uint16_t addr = sector * FLASH_SECTOR_SIZE;
					sectorErase(addr);
					serial.write("SECT");
				}
				serial.write("DONE");
			} else if (strcmp(cmdBuf, "READ") == 0) {
				// -------------------------------------------------------------
				// ----- READ - read Flash memory ------------------------------
				// -------------------------------------------------------------
				// Read 256 values from Flash memory, starting at a given
				// address.
				serial.write("ACKN");			// Confirm command received
				// Get address (two bytes) & relay it back.
				uint16_t address = getWord();
				sendWord(address);
				setFlashRW(FLASH_READ);
				for (uint16_t i = 0; i < 256; i++) {
					uint8_t byteVal = readFlash(address + i);
					serial.sendByte(byteVal);
				}
				FLASH_OE_DISABLE;						// disable output
			} else if (strcmp(cmdBuf, "CHKR") == 0) {
				// -------------------------------------------------------------
				// ----- VRFY - verify Flash memory ----------------------------
				// -------------------------------------------------------------
				uint16_t addrIdx = 0;
				bool error = false;
				serial.write("ACKN");
				while (addrIdx < 0x4000) {
					serial.write("PCKG");
					for (uint8_t i = 0; i < 64; i++) {
						uint8_t byteVal = readFlash(addrIdx);
						serial.sendByte(byteVal);
						addrIdx++;
					}
					// wait for acknowledgement
					error = checkForMessage("ACKN", cmdBuf);
					if (error) {
						break;
					}
				}
				if (error) {
					serial.write("EC01");
				} else {
					serial.write("EODT");
				}
			} else {
				serial.write("ECMD");
			}
			// When done, reset
			cmdRecvd = false;
			clearBuf(cmdBuf, CMD_BUF_LEN);
			serial.clearInputBuffer();
			disableFlashControl();
			resetSystem();
		} else {
			getCommand(cmdBuf); // don't come back until you've got a message
			cmdRecvd = true;
		}
	}
}
