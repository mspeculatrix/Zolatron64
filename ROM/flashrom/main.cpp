
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
#include "lib/defines.h"
#include "lib/smd_avr_serial4809.h"
#include "lib/functions.h"
#include "lib/flash_functions.h"

/*******************************************************************************
*****   GLOBALS                                                            *****
*******************************************************************************/

uint16_t dataSize = 0;
uint8_t dataChunk[CHUNKSIZE];

SMD_AVR_Serial4809 serial = SMD_AVR_Serial4809(SERIAL_BAUDRATE);

/*******************************************************************************
*****   MAIN                                                               *****
*******************************************************************************/
int main(void) {

	//--------------------------------------------------------------------------
	//-----   SETUP                                                        -----
	//--------------------------------------------------------------------------

	// Set up pins
	disableFlashControl();

	serial.begin();

	char cmdBuf[CMD_BUF_LEN]; 		// For receiving commands from remote PC
	bool cmdRecvd = false;			// Do we have one yet?

	/***************************************************************************
	******   MAIN LOOP													   *****
	***************************************************************************/

	while (1) {
		if (cmdRecvd) {
			serial.clearInputBuffer();
			enableFlashControl();
			if (strcmp(cmdBuf, "BURN") == 0) {
				// -------------------------------------------------------------
				// ----- BURN - Download data & write to Flash -----------------
				// -------------------------------------------------------------
				serial.write("ACKN");
				dataSize = 0; // reset
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
						serial.write("*ERR");
					}
					// RECEIVE DATA
					if (!error) {
						uint16_t byteIdx = 0; // for writing to Flash
						uint16_t fileIdx = 0;
						uint8_t chunkIdx = 0;
						// uint8_t inByte = 0;
						DATA_PORT_OUTPUT;

						while (byteIdx < dataSize) {
							bool gotChunk = false;
							while (!gotChunk) {
								if (serial.inWaiting()) {
									dataChunk[chunkIdx] = serial.getByte();
									chunkIdx++;
									fileIdx++;
									if (chunkIdx == CHUNKSIZE || fileIdx == dataSize) {
										gotChunk = true;
									}
								}
							}
							// chunkIdx contains how many bytes we have.
							// It may be less than the chunksize if it's the
							// last chunk.

							// check if we're at a sector boundary
							// - if so, clear sector
							if (byteIdx % FLASH_SECTOR_SIZE == 0) {
								sectorErase(byteIdx);
							}

							// write bytes
							for (uint8_t i = 0; i < chunkIdx; i++) {
								flashByteWrite(byteIdx, dataChunk[i]);
								byteIdx++;
							}
							chunkIdx = 0;
							if (byteIdx == dataSize) {
								serial.write("EODT"); // all bytes received
							} else {
								serial.write("ACKN"); // prompt sending of next chunk
							}
						}
						// CHECK DATA
						// Send back the first 16 bytes.
						// Read each one from RAM and send it across serial.
						serial.write("VRFY");
						DATA_PORT_INPUT;
						for (uint16_t addr = 0; addr < 16; addr++) {
							uint8_t testVal = readFlash(addr);
							serial.sendByte(testVal);
						}
					}
				} else {
					serial.write("SERR");
				}
			} else if (strcmp(cmdBuf, "CLRF") == 0) {
				// -------------------------------------------------------------
				// ----- CLRF - Clear flash                ---------------------
				// -------------------------------------------------------------
				// Clear the Flash memory.
				serial.write("ACKN");
				for (uint8_t sector = 0; sector < 4; sector++) {
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
				// Read Flash memory & send bytes
				for (uint16_t i = 0; i < 256; i++) {
					uint8_t byteVal = readFlash(address + i);
					serial.sendByte(byteVal);
				}
			} else {
				serial.write("*ERR");
			}
			// When done, reset
			cmdRecvd = false;
			clearBuf(cmdBuf, CMD_BUF_LEN);
			serial.clearInputBuffer();
			disableFlashControl();

		} else {
			getCommand(cmdBuf); // don't come back until you've got a message
			cmdRecvd = true;
		}
	}
}
