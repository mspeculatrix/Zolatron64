/* McROM */

#ifndef __AVR_ATmega4809__
#define __AVR_ATmega4809__
#endif

#ifndef F_CPU
#define F_CPU 20000000UL // 20 MHz unsigned long
#endif

#include <avr/io.h>
// #include <stdio.h>
// #include <stdlib.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <avr/pgmspace.h>
// #include <string.h>
// #include "lib/defines.h"
// #include "lib/functions.h"

// Pin assignments

#define CTRL_PORT PORTE
#define CTRL_PORT_INT_VEC PORTE_PORT_vect
#define CE PIN3_bm
#define CE_CTR3 PIN3CTRL
#define OE PIN2_bm
#define OE_CTRL PIN2CTRL

#define DATA_PORT PORTD
#define ADDR_PORTL PORTA
#define ADDR_PORTH PORTF

#define BANK_CTRL_PORT PORTE
#define BANK_CTRL_PORT_bm 0b11111000
#define A14 PIN0_bm
#define A15 PIN1_bm
#define A16 PIN2_bm

void setBank(uint8_t bank) {
	BANK_CTRL_PORT.OUT = (BANK_CTRL_PORT.OUT & BANK_CTRL_PORT_bm) | bank;
}

/*******************************************************************************
*****   GLOBALS                                                            *****
*******************************************************************************/

bool readRequest = false; // Flag for setting within ISR
extern const uint16_t _rom_data_start;
const uint16_t* data_ptr = (const uint16_t*)&_rom_data_start;
uint8_t bank = 0;

// Interrupt service routine - invoked when /CE is pulled low
ISR(CTRL_PORT_INT_VEC) {
	if (CTRL_PORT.INTFLAGS & OE) {		// Check if CE triggered
		CTRL_PORT.INTFLAGS = OE;		// Clear interrupt flag for CE
		readRequest = true;				// Set event flag
	}
}


/*******************************************************************************
*****   MAIN                                                               *****
*******************************************************************************/
int main(void) {

	//--------------------------------------------------------------------------
	//-----   SETUP                                                        -----
	//--------------------------------------------------------------------------

	CCP = CCP_IOREG_gc;		// Unlock protected registers
	CLKCTRL.MCLKCTRLB = 0;  // No prescaling, full main clock frequency

	// We're using the 40-pin DIP version of the 4809, so need to configure
	// the non-existent pins, PB0..5, PC6, PC7.
	PORTB.PIN0CTRL = PORT_PULLUPEN_bm;
	PORTB.PIN1CTRL = PORT_PULLUPEN_bm;
	PORTB.PIN2CTRL = PORT_PULLUPEN_bm;
	PORTB.PIN3CTRL = PORT_PULLUPEN_bm;
	PORTB.PIN4CTRL = PORT_PULLUPEN_bm;
	PORTB.PIN5CTRL = PORT_PULLUPEN_bm;
	PORTC.PIN6CTRL = PORT_PULLUPEN_bm;
	PORTC.PIN7CTRL = PORT_PULLUPEN_bm;


	CTRL_PORT.DIRCLR = CE | OE; // Set these pins as inputs
	// The /READ_EN signal on the Zolatron is clock-qualified.
	// This is connected to the ROM's OE pin, so we're going to use that
	// for interrupts.
	// Set OE pin as interrupt-enabled on falling edge, and with pullup.
	CTRL_PORT.OE_CTRL = PORT_PULLUPEN_bm | PORT_ISC_FALLING_gc;

	// Set control pins of bank control port as outputs & low
	BANK_CTRL_PORT.DIRSET = A14 | A15 | A16;
	BANK_CTRL_PORT.OUTCLR = A14 | A15 | A16;
	// Set Data port as input (so it's high-Z)
	DATA_PORT.DIR = 0;
	// Set Address ports as inputs (this won't change)
	ADDR_PORTL.DIR = 0;
	ADDR_PORTH.DIR = 0;

	/***************************************************************************
	******   MAIN LOOP													   *****
	***************************************************************************/

	while (1) {
		if (readRequest) {
			// Read the address on the address pins
			uint16_t address = ADDR_PORTH.IN << 8 | ADDR_PORTL.IN;
			// Find the appropriate value
			uint8_t value = pgm_read_byte(&data_ptr[address]);
			// - set the value - do this before setting the port as an output
			DATA_PORT.OUT = value;
			// - set data port as output
			DATA_PORT.DIR = 0xFF;
			// - Wait for CE to go high
			while (!(CTRL_PORT.IN && CE)) {};
			//   - set data port as input
			DATA_PORT.DIR = 0;
			readRequest = false;
		}
	}
}
