/* --- Macros for flashz --- */

#ifndef __DEFINES_H__
#define __DEFINES_H__

#include <avr/io.h>

#define SERIAL_BAUDRATE 38400UL

#define DATA_PORT  PORTD				// Port for data bus
#define ADDRL_PORT PORTC
#define ADDRH_PORT PORTF
#define ADDRH_MASK 0b00111111

#define CTRL_PORT  PORTA				// Port for control signals
// NB: Pins 0 and 1 of PORTA are used for the serial port
#define CTRL_PORT_MASK 0b11111100
#define CPU_RDY        PIN2_bm
#define CPU_BE         PIN3_bm
#define CLK_CTRL       PIN4_bm
#define CPU_RWB        PIN5_bm
#define FL_WE          PIN6_bm
#define SYS_RES        PIN7_bm

#define FLASH_READ 1
#define FLASH_WRITE 0

#define FL_MEMBANK_PORT PORTE
#define FA14 PIN0_bm
#define FA15 PIN1_bm
#define FA16 PIN2_bm
#define FL_MEMBANK_MASK 0b00000111

#define FL_EN_PORT PORTB
#define A14 PIN0_bm
#define A15 PIN1_bm

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
#define CMD_BUF_LEN 4
#define MAX_MSG_TRIES 4

#endif
