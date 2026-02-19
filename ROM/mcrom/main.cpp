/* * McROM - Fixed ATmega4809 ROM Emulation for 6502 Bus
 * * Major Fixes:
 * 1. Removed slow, latency-inducing interrupt logic in favor of a fast polling loop.
 * 2. Removed the illegal busy-wait from the ISR (and the ISR itself).
 * 3. Corrected pgm_read_byte pointer arithmetic to use byte offsets.
 * 4. Corrected logic for checking active-low control signals.
 * * NOTE: The 6502 bus timing is extremely tight. If this still fails, you may
 * need to look into customizing the clock setup or using other MCU features
 * like event systems, but this polling loop is the fastest software-only solution.
 */

#ifndef __AVR_ATmega4809__
#define __AVR_ATmega4809__
#endif

#ifndef F_CPU
#define F_CPU 20000000UL // 20 MHz unsigned long
#endif

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <avr/pgmspace.h>

 // --- CONTROL PIN DEFINITIONS (Assuming Active-Low for CE and OE) ---

#define RST_PORT PORTA
#define RST_CTRL PIN4CTRL
#define RST PIN4_bm

#define CTRL_PORT PORTE
#define CE PIN3_bm // Chip Enable (Active Low: /CE)
#define OE PIN2_bm // Output Enable (Active Low: /OE)

#define DATA_PORT PORTD
#define ADDR_PORTL PORTA
#define ADDR_PORTH PORTF

/*******************************************************************************
***** GLOBALS                                                            *****
*******************************************************************************/

// Assume _rom_data_start is defined in the linker script or other assembly file.
// We must treat the ROM data as a flat array of bytes (uint8_t).
extern const uint8_t _rom_data_start;
const uint8_t* rom_base_ptr = (const uint8_t*)&_rom_data_start;

// --- INTERRUPT LOGIC REMOVED ---
// The interrupt (ISR) and the 'readRequest' flag are removed to optimize for speed.

/*******************************************************************************
***** MAIN                                                               *****
*******************************************************************************/
int main(void) {

	//--------------------------------------------------------------------------
	//-----   SETUP                                                        -----
	//--------------------------------------------------------------------------

	CCP = CCP_IOREG_gc;     // Unlock protected registers
	CLKCTRL.MCLKCTRLB = 0;  // No prescaling, full main clock frequency

	// Configure non-existent pins with pullups (as in original code)
	PORTB.PIN0CTRL = PORT_PULLUPEN_bm;
	PORTB.PIN1CTRL = PORT_PULLUPEN_bm;
	PORTB.PIN2CTRL = PORT_PULLUPEN_bm;
	PORTB.PIN3CTRL = PORT_PULLUPEN_bm;
	PORTB.PIN4CTRL = PORT_PULLUPEN_bm;
	PORTB.PIN5CTRL = PORT_PULLUPEN_bm;
	PORTC.PIN6CTRL = PORT_PULLUPEN_bm;
	PORTC.PIN7CTRL = PORT_PULLUPEN_bm;

	// Set control pins as inputs with pullups (to ensure high state when not driven low)
	RST_PORT.DIRCLR = RST;
	RST_PORT.RST_CTRL = PORT_PULLUPEN_bm; // Set pullup for RST pin (assuming RST_CTRL is PIN4CTRL)

	CTRL_PORT.DIRCLR = CE | OE;
	CTRL_PORT.PIN2CTRL = PORT_PULLUPEN_bm; // Pullup for OE
	CTRL_PORT.PIN3CTRL = PORT_PULLUPEN_bm; // Pullup for CE

	// Address and Data ports are always inputs initially (tristate)
	DATA_PORT.DIR = 0;
	ADDR_PORTL.DIR = 0;
	ADDR_PORTH.DIR = 0;

	// Reset sequence for 6502 (Active Low)
	RST_PORT.OUTCLR = RST;          // Assert RST (low)
	RST_PORT.DIRSET = RST;          // Set it as an output (actively drive low)
	_delay_ms(50);                  // Wait a 'mo (50ms is plenty)
	RST_PORT.OUTSET = RST;          // De-assert RST (high)
	RST_PORT.DIRCLR = RST;          // Set pin back to input (let 6502 drive it or use pullup)

	/***************************************************************************
	****** MAIN LOOP (FAST POLLING)                                      *****
	***************************************************************************/

	while (1) {
		// A read cycle is active when BOTH /CE and /OE are LOW.
		// PINX_bm is the bitmask (e.g., 0x04 for PIN2).
		// CTRL_PORT.IN & PINX_bm returns a non-zero value if the pin is HIGH.
		// Therefore, (CTRL_PORT.IN & CE) is non-zero when /CE is HIGH (inactive).
		// We wait for both to be active (LOW).

		// Wait until both /CE and /OE are active (LOW). This is the fastest wait loop.
		while ((CTRL_PORT.IN & CE) || (CTRL_PORT.IN & OE)) {
			// Do nothing. This loop consumes ~4 cycles (200ns) per check.
		};

		// --- CYCLE START ---
		// Both /CE and /OE are low. Immediate action required!

		// 1. Read the address on the address pins
		// Read high byte, then low byte.
		// Using explicit casting for clarity and correctness.
		uint16_t address = ((uint16_t)ADDR_PORTH.IN << 8) | ADDR_PORTL.IN;

		// 2. Find the appropriate value
		// Use the corrected byte-pointer arithmetic.
		uint8_t value = pgm_read_byte(rom_base_ptr + address);

		// 3. Drive the bus
		DATA_PORT.OUT = value;

		// 4. Set data port as output (enable driving the bus)
		DATA_PORT.DIR = 0xFF;

		// 5. Wait for the cycle to end (either /CE or /OE goes inactive/HIGH)
		// Wait until EITHER /CE OR /OE goes HIGH (inactive).
		while (!((CTRL_PORT.IN & CE) || (CTRL_PORT.IN & OE))) {
			// Do nothing. Data is currently being driven.
		};

		// 6. Tristate the bus
		DATA_PORT.DIR = 0;

		// --- CYCLE END ---
	}
}
