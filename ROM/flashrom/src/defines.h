/* --- Macros for flashz --- */

#ifndef __DEFINES_H__
#define __DEFINES_H__

#include <avr/io.h>

#define SERIAL_BAUDRATE 38400UL

#define DATA_PORT  PORTD				// Port for data bus
#define ADDRL_PORT PORTC				// Low address byte port
#define ADDRH_PORT PORTF				// High address byte port
#define ADDRH_MASK 0b00111111			// Not using all of port so need a mask

#define CTRL_PORT  PORTA				// Port for control signals
// NB: Pins 0 and 1 of PORTA are used for the serial port
#define CTRL_PORT_MASK 0b11111100
#define CPU_RDY        PIN2_bm			// Connects to CPU's RDY pin
#define CPU_BE         PIN3_bm			// Connects to CPU's BE pin
#define CLK_CTRL       PIN4_bm			// Connects to clock circuit
#define CPU_RWB        PIN5_bm			// Connects to CPU's RWB pin
#define FL_WE          PIN6_bm 			// Connects to flash /WE pin
#define SYS_RES        PIN7_bm			// Connects to system RESET line

#define FL_MEMBANK_PORT PORTE			// For controlling flash memory banks
#define FA14 PIN0_bm					// Three pins connect to the flash's
#define FA15 PIN1_bm					// A14, A15 and A16 inputs
#define FA16 PIN2_bm
#define FL_MEMBANK_MASK 0b00000111		// Only using three pins in port

#define FL_EN_PORT PORTB				// These outputs connect to the system
#define A14 PIN0_bm						// address bus A14 & A15 lines & are
#define A15 PIN1_bm						// used to select the flash via decoding

// Handy macros
#define FLASH_CE_ENABLE  FL_EN_PORT.OUTSET = A14 | A15
#define FLASH_CE_DISABLE FL_EN_PORT.OUTCLR = A14 | A15
#define FLASH_OE_ENABLE  CTRL_PORT.OUTSET = CPU_RWB
#define FLASH_OE_DISABLE CTRL_PORT.OUTCLR = CPU_RWB
#define FLASH_WE_ENABLE  CTRL_PORT.OUTCLR = FL_WE
#define FLASH_WE_DISABLE CTRL_PORT.OUTSET = FL_WE
#define DATA_PORT_OUTPUT DATA_PORT.DIR = 0xFF
#define DATA_PORT_INPUT DATA_PORT.DIR = 0

#define NEWLINE 10
#define CR 13

#define CHUNKSIZE 64 				// Size of each chunk when sending data
#define CMD_BUF_LEN 5 				// Num chars in command message plus null
#define MAX_MSG_TRIES 4 			// How many attempts to get a message
#define SECTORS_PER_IMG 4 			// number of flash sectors in a ROM image

#define MSG_ACKNOWLEDGE "ACKN"
#define MSG_END_OF_DATA "FEOD"
#define MSG_FILE_SIZE   "SIZE"
#define MSG_WRITE_FLASH "WFLS"

// ERROR CODES

#define ERR_COMMAND   "ECMD"	// no recognised command received
#define ERR_NO_ACKN   "EACK"	// expected 'ACKN' message not received
#define ERR_BYTE_READ "EBTR"
#define ERR_NO_WFLS   "EWFL"	// expected 'WFLS' message not received
#define ERR_NO_SIZE   "ESIZ"	// expected 'SIZE' message not received

#endif
