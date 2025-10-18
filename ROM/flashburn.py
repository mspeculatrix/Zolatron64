#!/usr/bin/env python3

"""
Script to upload a new ROM image to the flash chip on the Zolatron's CPU board.

Normally, this script is invoked from the ./_build shell script in the ROM
directory, so you need to CD to this directory first.
"""

import os
import string
import sys
import time
from pathlib import Path

import serial

MAX_HANDSHAKES: int = 4
VERSION: str = '1.6'
SERIAL_PORT: str = '/dev/ttyUSB0'  # configure for your machine
BAUDRATE: int = 38400  # fast enough
CHUNKSIZE: int = 64  # num bytes per chunk when sending data

ser = serial.Serial(
	SERIAL_PORT,
	BAUDRATE,
	bytesize=serial.EIGHTBITS,
	parity=serial.PARITY_EVEN,
	stopbits=serial.STOPBITS_ONE,
	timeout=1,
)

################################################################################
###   FUNCTIONS                                                              ###
################################################################################


def clearSerial() -> None:
	"""
	Empty out the serial buffers, just to be sure.
	"""
	ser.reset_input_buffer()
	ser.reset_output_buffer()
	while ser.in_waiting > 0:
		_ = ser.read(1)


def getTestData(
	numBytes: int, checkBuf: list[bytes] | None = None
) -> tuple[list[bytes], bool]:
	"""
	Get numBytes bytes from the serial port. If desired, check these against a
	buffer (a list of bytes) for any discrepancies.
	"""
	mismatch = False
	dataItems: list[bytes] = []
	for i in range(0, numBytes):
		testByte = ser.read(1)  # blocks until byte is read
		if checkBuf is not None and checkBuf[i] != testByte:
			mismatch = True
		dataItems.append(testByte)
	return dataItems, mismatch


def hexStr(value, length=2) -> str:
	"""
	Format a numeric value as a hex string.
	"""
	fmt = '{0:0' + str(length) + 'X}'
	return fmt.format(value)


def printBuf(buffer: list[bytes], num: int, verbose: bool) -> None:
	"""
	Take a list of bytes and print as a string of space-separated hex values.
	"""
	items = []
	for i in range(0, num):
		items.append(hexStr(buffer[i][0]))
	output(' '.join(items), verbose)


def readFile(filedir: str, filename: str) -> tuple[list[bytes], int, str | None]:
	"""
	Read the contents of a binary file into a list of bytes and return that,
	along with the number of bytes read.
	"""
	fpath: Path = Path(filedir) / filename
	buffer: list[bytes] = []
	size = 0
	error: str | None = None
	if os.path.isfile(fpath):
		try:
			with open(fpath, 'rb') as fh:
				while True:
					fileByte: bytes = fh.read(1)
					if not fileByte:
						break
					buffer.append(fileByte)
					size += 1
		except IOError:
			# print('Cannot open file:', filepath, ' : ', e)
			error = 'Cannot open file:' + filename
	return buffer, size, error


def readWord() -> int:
	"""
	Get 2 bytes from the serial port and convert to a 16-bit integer. Expects
	byte order to be MSB-first.
	"""
	value: int = 0
	hi: bytes = ser.read(1)
	lo: bytes = ser.read(1)
	# print(f'{hi} {lo}', funcs.ui.DATALINE)
	if hi and lo:
		value = (ord(hi) << 8) + ord(lo)
	return value


def sendCommandWithAck(cmd: str, ack: str, verbose: bool) -> bool:
	error: bool = False
	clearSerial()
	output(f'Sending command: {cmd}', verbose)
	ser.write(cmd.encode('ascii'))
	done: bool = False
	attempts: int = 0
	while not done:
		attempts += 1
		msg_in: bytes = ser.read(4)
		if msg_in == ack.encode('ascii'):
			output(f'- received: {ack}', verbose)
			done = True
		elif attempts == MAX_HANDSHAKES:
			output(f'- got: {msg_in}', verbose)
			error = True
			done = True
		else:
			output(f'- got: {msg_in}', verbose)
			time.sleep(0.01)  # 10ms
	return error


def sendSizeInfo(file_size: int, verbose: bool) -> bool:
	error: bool = False
	output('Sending SIZE', verbose)
	ser.write(b'SIZE')
	msg_in: bytes = ser.read(4)
	if msg_in == b'SIZE':
		output('- received: SIZE', verbose)
		sendWord(file_size)
		rec_file_sz: int = readWord()
		output(f'- received filesize: 0x{hexStr(rec_file_sz, 4)}', verbose)
		if file_size == rec_file_sz:
			output('- sizes match!', verbose)
		else:
			output('- size mismatch', verbose)
			error = True
	else:
		output('- failed to receive SIZE message', verbose)
		output(f'- got {msg_in}', verbose)
		error = True
	return error


def sendWord(word: int):
	"""
	Take a 16-bit value and send it across serial as 2 bytes, MSB-first.
	"""
	hi_byte: bytes = chr(word >> 8).encode('latin-1')
	lo_byte: bytes = chr(word & 0x00FF).encode('latin-1')
	ser.write(hi_byte)
	ser.write(lo_byte)


def output(msg: str, verbose: bool):
	if verbose:
		print(msg)


################################################################################
###   MAIN                                                                   ###
################################################################################


def main():
	filedir: str = 'files'
	romfile: str = 'ROM.bin'
	verbose: bool = True
	command: str = 'BURN'
	addressStr: str = ''

	# COMMAND LINE FLAGS
	if len(sys.argv) > 1:  # We have some command line args
		sys.argv.pop(0)  # we don't need the prog name, get rid of it
		while len(sys.argv) > 0:  # process other arguments, if any
			nextArg: str = sys.argv.pop(0)
			if nextArg == '-e':
				command = 'CLRF'
			if nextArg == '-f':
				romfile = sys.argv.pop(0)
			if nextArg == '-q':
				verbose = False
			if nextArg == '-r':
				command = 'READ'
				addressStr: str = sys.argv.pop(0)
			if nextArg == '-v':
				verbose = True

	clearSerial()

	output(f'ROM image file: {romfile}', verbose)

	fileBuf: list[bytes] = []
	fault: bool = False

	# file_size, _ = readFile(fileBuf, romfile)
	fileBuf, file_size, error = readFile(filedir, romfile)
	if error is None:
		output(f'- filesize: 0x{hexStr(file_size, 2)}', verbose)
	else:
		fault = True

	# STEP 1: Handshake
	if not fault:
		fault = sendCommandWithAck(command, 'ACKN', verbose)

	if command == 'BURN':
		# STEP 2: Transmit & agree on file size
		if not fault:
			fault = sendSizeInfo(file_size, verbose)

		# STEP 3: Send WFLS command
		if not fault:
			fault = sendCommandWithAck('WFLS', 'WFLS', verbose)

		# STEP 4: Send data
		if not fault:
			output('Sending data...', verbose)
			done: bool = False
			byteIdx: int = 0
			chunkCount: int = 0
			while not done:
				ser.write(fileBuf[byteIdx])
				byteIdx += 1
				if byteIdx % CHUNKSIZE == 0 or byteIdx == len(
					fileBuf
				):  # end of a chunk
					# Wait for a response
					response_ok = False
					while not response_ok:
						msg_in: bytes = ser.read(4)
						if msg_in == b'EODT':  # we've sent all data
							done = True
							response_ok = True
							output('\n- received: EODT', verbose)
						elif msg_in == b'ACKN':  # sent after each chunk by MCU
							response_ok = True
							if verbose:
								print(f'\b\b\b{chunkCount}', end='', flush=True)
								chunkCount += 1
						else:
							output('\n**ERROR', verbose)
							exit(2)
			msg_in: bytes = ser.read(4)
			if msg_in == b'VRFY':
				output('Performing data check...', verbose)
				mismatch: bool = False
				# Expect 16 bytes back from client containing test data
				dataItems, mismatch = getTestData(16, fileBuf)
				printBuf(fileBuf, 16, verbose)
				printBuf(dataItems, 16, verbose)
				if mismatch:
					output('- ERR: data mismatch', verbose)
					# ser.write(b'*ERR\n')
				else:
					output('- data check OK', verbose)
					# ser.write(b'CONF\n')
			output('FINISHED', verbose)
	elif command == 'CLRF':
		if not fault:
			done: bool = False
			while not done:
				msg_in: bytes = ser.read(4)
				if msg_in == b'DONE':
					done = True
					output('Completed', verbose)
				elif msg_in == b'SECT':
					output('- sector erased', verbose)
				else:
					done = True
					output('ERROR', verbose)
	elif command == 'READ':
		"""
		As this option is all about seeing the contents of memory, we'll
		ignore the value of verbose and just print to screen
		"""
		if not fault:
			if len(addressStr) == 4:
				# Test string contains only hex digits
				if all(c in string.hexdigits for c in addressStr):
					address: int = int(addressStr, 16)
					sendWord(address)
					response: int = readWord()
					if response == address:
						for _ in range(0, 16):
							data, _ = getTestData(16)
							for b in data:
								print(format(b[0], '02X'), end=' ')
							print()

					else:
						print("ERROR: addresses don't match!")
				else:
					print('ERROR: invalid address.')
			else:
				print('ERROR: wrong address length: must be 4 hex chars.')


if __name__ == '__main__':
	main()
