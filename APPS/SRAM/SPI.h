// SPI.h
#ifndef __SPI_H__
#define __SPI_H__

void SPI_commStart(uint8_t device)
{
	digitalWrite(SCLK, LOW); // To be sure
	digitalWrite(device, LOW);
}

void SPI_commEnd(uint8_t device)
{
	digitalWrite(device, HIGH);
	digitalWrite(PICO, HIGH); // To be sure
	digitalWrite(SCLK, HIGH); //  "  "  "
}

uint8_t SPI_exchangeByte(uint8_t sendByte)
{
	/*  This function replicates the operation of the data reg of the 65SPI CPLD.
		When a byte is written to the data reg of that device, it
		sends the byte and receives an incoming byte. */
	uint8_t recvByte = 0;
	/* We're going to send MSB first */
	for (int8_t i = 7; i >= 0; i--)
	{
		digitalWrite(PICO, bitRead(sendByte, i));
		digitalWrite(SCLK, HIGH); // Take the clock HIGH
		bitWrite(recvByte, i, digitalRead(POCI));
		digitalWrite(SCLK, LOW); // Take the clock LOW
	}
	return recvByte;
}

uint8_t SPI_getByte()
{
	// Get devices to send a byte. Wrapper to SPI_exchangeByte(). Sends dummy data.
	return SPI_exchangeByte((uint8_t)0xF0);
}

void SPI_sendByte(uint8_t SPI_sendByte)
{
	// Wrapper to SPI_exchangeByte(). For sending without caring about what comes back.
	SPI_exchangeByte(SPI_sendByte);
}

#endif