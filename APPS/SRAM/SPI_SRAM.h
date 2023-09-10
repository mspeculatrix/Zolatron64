/* Microchip 23LCV512 SPI SRAM chip */

#ifndef __SPI_SRAM_H__
#define __SPI_SRAM_H__

#define PAGE_SIZE 32

#define CMD_READ 0x03  // Read data from memory
#define CMD_WRITE 0x02 // Write data to memory
#define CMD_EDIO 0x3B  // Enter dual I/O mode
#define CMD_RSTIO 0xFF // Reset dual I/O access
#define CMD_RDMR 0x05  // Read mode register
#define CMD_WRMR 0x01  // Write mode register

#define BYTE_MODE 0b00000000 // Values to be written to mode reg
#define PAGE_MODE 0b10000000
#define SEQU_MODE 0b01000000

// PROTOTYPES
void setWRMode(uint8_t device, uint8_t mode);
uint8_t readByte(uint8_t device, uint16_t address);
void readBytes(uint8_t device, uint16_t address, uint8_t *buffer, uint16_t numBytes);
void readPage(uint8_t device, uint16_t address, uint8_t *buffer);
void writeByte(uint8_t device, uint16_t address, uint8_t value);
void writeBytes(uint8_t device, uint16_t address, uint8_t *buffer, uint16_t numBytes);
void writePage(uint8_t device, uint16_t address, uint8_t *buffer);
void _startWROp(uint8_t device, uint16_t address, int8_t mode);

void setWRMode(uint8_t device, uint8_t mode)
{
	SPI_commStart(device);
	SPI_sendByte(CMD_WRMR);
	SPI_sendByte(mode);
	SPI_commEnd(device);
}

/*****  READING *****/
uint8_t readByte(uint8_t device, uint16_t address)
{
	uint8_t rdByte = 0;
	_startWROp(device, address, CMD_READ);
	rdByte = SPI_getByte();
	SPI_commEnd(device);
	return rdByte;
}

void readBytes(uint8_t device, uint16_t address, uint8_t *buffer, uint16_t numBytes)
{
	_startWROp(device, address, CMD_READ);
	for (uint16_t i = 0; i < numBytes; i++)
	{
		buffer[i] = SPI_getByte();
	}
	SPI_commEnd(device);
}

void readPage(uint8_t device, uint16_t address, uint8_t *buffer)
{
	_startWROp(device, address, CMD_READ);
	for (uint8_t i = 0; i < PAGE_SIZE; i++)
	{
		buffer[i] = SPI_getByte();
	}
	SPI_commEnd(device);
}

/*****  WRITING *****/
void writeByte(uint8_t device, uint16_t address, uint8_t value)
{
	_startWROp(device, address, CMD_WRITE);
	SPI_sendByte(value);
	SPI_commEnd(device);
}

void writeBytes(uint8_t device, uint16_t address, uint8_t *buffer, uint16_t numBytes)
{
	_startWROp(device, address, CMD_WRITE);
	for (uint16_t i = 0; i < numBytes; i++)
	{
		SPI_sendByte(buffer[i]);
	}
	SPI_commEnd(device);
}

void writePage(uint8_t device, uint16_t address, uint8_t *buffer)
{
	_startWROp(device, address, CMD_WRITE);
	for (uint8_t i = 0; i < PAGE_SIZE; i++)
	{
		SPI_sendByte(buffer[i]);
	}
	SPI_commEnd(device);
}

void _startWROp(uint8_t device, uint16_t address, int8_t mode)
{
	SPI_commStart(device);
	SPI_sendByte(mode);
	SPI_sendByte((uint8_t)address >> 8);
	SPI_sendByte((uint8_t)address & 0x00FF);
}

#endif
