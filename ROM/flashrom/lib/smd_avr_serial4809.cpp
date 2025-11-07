#include "smd_avr_serial4809.h"

using namespace smd_avr_serial;

// -------------------------------------------------------------------------
// -----  EXPERIMENTAL                                                 -----
// -------------------------------------------------------------------------

namespace smd_avr_serial {
	uint8_t recvbuf[SER_RECV_BUF_SZ];
	uint8_t recvbuf_write_idx = 0;
	uint8_t recvbuf_read_idx = 0;
}

// Interrupt service routine - invoked when data is received on USART0.
ISR(USART0_RXC_vect) { // RX Complete
	// get incoming byte & add to buffer
	recvbuf[recvbuf_write_idx] = USART0.RXDATAL;
	recvbuf_write_idx++;
	if (recvbuf_write_idx == SER_RECV_BUF_SZ) {
		recvbuf_write_idx = 0;
	}
}


// -------------------------------------------------------------------------
// -----  CONSTRUCTORS                                                 -----
// -------------------------------------------------------------------------
SMD_AVR_Serial4809::SMD_AVR_Serial4809()  // instantiate with default baudrate,
{                                  // 8 data bits, 1 stop bit
	_init(19200, SER_DATA_BITS8, SER_STOP_BITS1, SER_PARITY_NONE);
}

SMD_AVR_Serial4809::SMD_AVR_Serial4809(uint32_t baudrate)    // instantiate with definable
{                                           // baudrate, 8 data bits, 1 stop bit
	_init(baudrate, SER_DATA_BITS8, SER_STOP_BITS1, SER_PARITY_NONE);
}

SMD_AVR_Serial4809::SMD_AVR_Serial4809(uint32_t baudrate, uint8_t dataBits, uint8_t stopBits) {
	_init(baudrate, dataBits, stopBits, SER_PARITY_NONE);
}

// This is the main constructor, called by all the others.
void SMD_AVR_Serial4809::_init(uint32_t baudrate, uint8_t dataBits, uint8_t stopBits, uint8_t parity) {
	_baud = baudrate;
	_dataBits = dataBits;
	_stopBits = stopBits;
	_parity = parity;
	_started = false;
	_useCR = false;
	_sendNullTerminator = false;
}

// -------------------------------------------------------------------------
// -----  METHODS                                                      -----
// -------------------------------------------------------------------------
uint8_t SMD_AVR_Serial4809::begin() {
	uint8_t error = 0;
	cli();
	uint16_t baud_setting = (64 * F_CPU + ((16UL * _baud) / 2)) / (16UL * _baud);
	USART0.BAUD = baud_setting;
	// Set the frame format with USART0.CTRLC
	// From left to right:
	// 00  = Asynchronous mode CMODE
	// 00  = No parity         PMODE (01 = even)
	// 0   = 1 stop bit        SBMODE
	// 011 = 8 bits            CHSIZE
	uint8_t ctrlc = 0;
	ctrlc |= (_parity << 4);
	ctrlc |= (_stopBits << 3);
	ctrlc |= (_dataBits);
	USART0.CTRLC = ctrlc; 				// or could use USART_CHSIZE_8BIT_gc
	PORTA.DIRSET = PIN0_bm;					// Set TX pin as output
	PORTA.DIRCLR = PIN1_bm;  				// Make sure RX pin is input
	USART0.CTRLB = USART_RXEN_bm | USART_TXEN_bm; // Enable TX and RX
	USART0.CTRLA = USART_RXCIE_bm;			// Enable RX complete interrupt

	if (error == 0) _started = true;
	clearInputBuffer();
	sei();
	return error;
}

bool SMD_AVR_Serial4809::started(void) {
	return _started;
}

void SMD_AVR_Serial4809::clearInputBuffer() {
	recvbuf_read_idx = 0;
	recvbuf_write_idx = 0;
}

// -------------------------------------------------------------------------
// -----  RECEIVING                                                    -----
// -------------------------------------------------------------------------
uint8_t SMD_AVR_Serial4809::getByte() {
	// This doesn't test if there are unread bytes in the buffer.
	// Always preceed by a test of inWaiting()
	uint8_t byteVal = recvbuf[recvbuf_read_idx];
	recvbuf_read_idx++;
	if (recvbuf_read_idx == SER_RECV_BUF_SZ) recvbuf_read_idx = 0;
	// OR
	// recvbuf_read_idx = recvbuf_read_idx % SER_RECV_BUF_SZ;
	return byteVal;
}

bool SMD_AVR_Serial4809::inWaiting() {
	// return bit_is_set(UCSR0A, RXC0);
	return recvbuf_write_idx != recvbuf_read_idx;
}

bool SMD_AVR_Serial4809::readByte(uint8_t* byteVal) {
	bool byteRead = false;
	if (inWaiting()) {
		byteRead = true;
		*byteVal = recvbuf[recvbuf_read_idx];
		recvbuf_read_idx++;
		if (recvbuf_read_idx == SER_RECV_BUF_SZ) recvbuf_read_idx = 0;
		// OR
		// recvbuf_read_idx = recvbuf_read_idx % SER_RECV_BUF_SZ;
	}
	return byteRead;
}

// UNTESTED:
// Assumes all the bytes are in the RX buffer. It doesn't wait around.
// Returns number of bytes actually read.
uint8_t SMD_AVR_Serial4809::readBytes(uint8_t* buf, uint8_t numToRead) {
	uint8_t counter = 0;
	uint8_t inByte = 0;
	while (readByte(&inByte) && counter < numToRead) {
		buf[counter] = inByte;
		counter++;
	}
	return counter;
}

uint8_t SMD_AVR_Serial4809::readLine(char* buffer, size_t bufferSize, bool preserveNewline = true) {
	// You must pass a buffer and the size of the buffer. Giving a buffer
	// size larger than the size of the actual buffer will result in a buffer
	// overflow and unpredictable results. The length of the string is
	// always one less than the size of the buffer because of the
	// null termination.
	// This reads input until:
	//		* It encounters a 0 (NULL)
	//		* It encounters a newline which is or is not included in the output depending on third param
	//		* It reaches the length of the buffer.
	// The incoming data is placed into the buffer. The method returns any
	// error encountered.
	uint8_t error = 0;
	if (bufferSize > SER_READLINE_BUFFER_MAX) bufferSize = SER_READLINE_BUFFER_MAX;
	if (bufferSize > 1) {
		bool ended = false;
		size_t index = 0;
		uint8_t inByte = 0;
		do {
			if (readByte(&inByte)) {
				if (inByte == 0) {					// null terminator received
					buffer[index] = inByte;
					ended = true;
				} else if (inByte == SER_NL) {		// linefeed received
					ended = true;
					if (preserveNewline) {
						buffer[index] = SER_NL;
						if (index < bufferSize - 1) {
							buffer[index + 1] = 0;
						} else {
							// sorry, but the newline is toast
							buffer[index] = 0;	// think this duplicates case further down, but hey ho
						}
					} else {
						buffer[index] = 0;	// replace NL with null terminator
					}
				} else if (inByte == SER_CR) {
					// ignore carriage returns
				} else if (index == bufferSize - 2) {
					// we're at the penultimate char. The next one _has_ to be a
					// terminating null, so let's add that and be done with it.
					buffer[index] = inByte;
					buffer[index + 1] = 0;
					ended = true;
				} else {
					buffer[index] = inByte;
					index++;
				}
			}
		} while (!ended);
	} else {
		// minimum buffer size for this method is 2.
		error = SER_ERR_READLINE_BUFFER_TOO_SMALL;
	}
	return error;
}

// -------------------------------------------------------------------------
// -----  TRANSMITTING                                                 -----
// -------------------------------------------------------------------------

/** NB: currently we're not doing anything with the error codes - they're
	not getting set anywhere, we're just returning default values meaning
	success. They are in here for future development. **/

bool SMD_AVR_Serial4809::sendByte(uint8_t byteVal) {
	bool error = false;
	// Wait until data register empty
	while (!(USART0.STATUS & USART_DREIF_bm)) {};
	// Send data
	USART0.TXDATAL = byteVal;
	_delay_ms(DEF_SEND_CHAR_DELAY);
	return error;
}

uint8_t SMD_AVR_Serial4809::write(const char* string) {
	uint8_t error = _writeStr(string, false);
	return error;
}

uint8_t SMD_AVR_Serial4809::write(const double fnum) {
	uint8_t error = _writeDouble(fnum, false);
	return error;
}

uint8_t SMD_AVR_Serial4809::write(const int twoByteInt) {
	uint8_t error = _writeInt16(twoByteInt, false);
	return error;
}

uint8_t SMD_AVR_Serial4809::write(const long longInt) {
	uint8_t error = _writeLongInt(longInt, false);
	return error;
}

uint8_t SMD_AVR_Serial4809::writeChar(const char ch) {
	char sendChar[1 + sizeof(char)];
	sprintf(sendChar, "%c", ch);
	uint8_t error = _writeStr(sendChar, false);
	return error;
}

uint8_t SMD_AVR_Serial4809::writeln(const char* string) {
	return _writeStr(string, true);
}

uint8_t SMD_AVR_Serial4809::writeln(const int twoByteInt) {
	return _writeInt16(twoByteInt, true);
}

uint8_t SMD_AVR_Serial4809::writeln(const long longInt) {
	return _writeLongInt(longInt, true);
}

uint8_t SMD_AVR_Serial4809::writeln(const double fnum) {
	return _writeDouble(fnum, true);
}


uint8_t SMD_AVR_Serial4809::_writeDouble(const double fnum, bool addReturn = false) {
	uint8_t resultCode = 0;
	char numStr[30];
	// see: http://www.atmel.com/webdoc/AVRLibcReferenceManual/group__avr__stdlib_1ga060c998e77fb5fc0d3168b3ce8771d42.html
	dtostrf(fnum, 3, 5, numStr);
	_writeStr(numStr, addReturn);
	return resultCode;
}

uint8_t SMD_AVR_Serial4809::_writeInt16(const int twoByteInt, bool addReturn = false) {
	uint8_t resultCode = 0;
	char numStr[20];
	itoa(twoByteInt, numStr, 10);
	//sprintf(numStr, "%i", twoByteInt);
	_writeStr(numStr, addReturn);
	return resultCode;
}

uint8_t SMD_AVR_Serial4809::_writeLongInt(const long longInt, bool addReturn = false) {
	uint8_t resultCode = 0;
	char numStr[30];
	ltoa(longInt, numStr, 10);
	_writeStr(numStr, addReturn);
	return resultCode;
}

// This is the main function used by the other write() and writeln() methods.
uint8_t SMD_AVR_Serial4809::_writeStr(const char* string, bool addReturn) {
	uint8_t resultCode = 0;
	if (strlen(string) > 0) {
		uint8_t i = 0;
		do {
			sendByte(string[i]);
			i++;
		} while (string[i] != 0);
		if (addReturn) {
			if (_useCR) sendByte(SER_CR);
			sendByte(SER_NL);
		}
		if (_sendNullTerminator) sendByte(SER_NUL);
	} else {
		resultCode = SER_RES_EMPTY_STRING;
	}
	return resultCode;
}