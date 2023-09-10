/*  Experimental code for messing about with the
	Microchip 23LCV512 SPI SRAM chip.

	For the Teensy 3.2

*/
#define RTC_CS 21
#define SRAM_CS 22
#define SD_CS 23
#define POCI 12
#define PICO 11
#define SCLK 13

#include "SPI.h"
#include "SPI_SRAM.h"

uint8_t page_buf[32];
uint8_t sequ_buf[256];

void printBuf(uint8_t *buffer, uint16_t bufSize)
{
	for (uint16_t i = 0; i < bufSize; i++)
	{
		if (i % 32 == 0)
		{
			Serial.println();
		}
		else
		{
			Serial.print(" ");
		}
		Serial.printf("%02x", buffer[i]);
	}
	Serial.println();
}

void fillBuf(uint8_t *buffer, uint16_t bufSize, char chr)
{
	for (uint16_t i = 0; i < bufSize; i++)
	{
		buffer[i] = chr;
	}
}

void setup()
{
	pinMode(POCI, INPUT_PULLUP);
	pinMode(PICO, OUTPUT);
	pinMode(SCLK, OUTPUT);
	pinMode(SRAM_CS, OUTPUT);

	digitalWrite(PICO, HIGH);
	digitalWrite(SCLK, LOW);
	digitalWrite(SRAM_CS, HIGH);
	digitalWrite(SD_CS, HIGH);
	digitalWrite(RTC_CS, HIGH);

	Serial.begin(9600);
	delay(1000);
	Serial.println("Running...");

	/** ***** PAGE MODE ***** **/
	// setWRMode(CS, PAGE_MODE);
	// Serial.print("Reading page: ");
	// readPage(CS, 32, page_buf);
	// printBuf(page_buf, sizeof(page_buf));
	// Serial.println("Filling buffer: 0xAA");
	// fillBuf(page_buf, sizeof(page_buf), 0xAA);
	// Serial.println("Writing buffer to RAM");
	// writePage(CS, 32, page_buf);
	// Serial.println("Zeroing out buffer");
	// fillBuf(page_buf, sizeof(page_buf), 0x00);
	// Serial.print("Buffer now: ");
	// printBuf(page_buf, sizeof(page_buf));
	// Serial.println("Reading memory back into buffer");
	// readPage(CS, 32, page_buf);
	// Serial.print("Buffer now: ");
	// printBuf(page_buf, sizeof(page_buf));

	/** ***** SEQUENTIAL MODE ***** **/
	setWRMode(SRAM_CS, SEQU_MODE);
	Serial.print("Reading bytes: ");
	readBytes(SRAM_CS, 0, sequ_buf, sizeof(sequ_buf));
	printBuf(sequ_buf, sizeof(sequ_buf));
	Serial.println("Filling buffer: 0xCC");
	fillBuf(sequ_buf, sizeof(sequ_buf), 0xCC);
	Serial.print("Buffer now: ");
	printBuf(sequ_buf, sizeof(sequ_buf));
	Serial.println("Writing buffer to RAM");
	writeBytes(SRAM_CS, 0, sequ_buf, sizeof(sequ_buf));
	Serial.println("Zeroing out buffer");
	fillBuf(sequ_buf, sizeof(sequ_buf), 0x00);
	Serial.print("Buffer now: ");
	printBuf(sequ_buf, sizeof(sequ_buf));
	Serial.println("Reading memory back into buffer");
	readBytes(SRAM_CS, 0, sequ_buf, sizeof(sequ_buf));
	Serial.print("Buffer now: ");
	printBuf(sequ_buf, sizeof(sequ_buf));
}

void loop()
{
}
