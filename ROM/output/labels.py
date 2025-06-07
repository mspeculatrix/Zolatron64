#!/usr/bin/env python3

"""
This script opens the Swift-compatible label file output by the Beebasm
assembler, converts it to Json and then writes out sorted lists of
labels as new files.
"""

import json

# Read the swift file created by the assembler
with open('output/_labels.swift', 'r') as file:
	data = file.read()

# Tidy it up
data = data.replace('[', '')
data = data.replace(']', '')
data = data.replace("'", '"')  # Change single quotes to double quotes
data = data.replace('L}', '}')  # Get rid of Ls at the end of numbers
data = data.replace('L,', ',')

# Convert to Json
json_data = json.loads(data)

# Sort by the value field
sorted_data = sorted(json_data.items(), key=lambda x: x[1])

# Output sorted list of tuples as a file.
try:
	with open('output/labels.txt', 'w', encoding='utf-8') as fh:
		for k, v in sorted_data:  # each item is a tuple
			hexVal = hex(v).upper()
			if v < 0x10000:
				fh.write(hexVal[2:] + '    ' + k + '\n')
except IOError as e:
	print('Cannot open file', e)

# Sort by the label field
sorted_data = sorted(json_data.items(), key=lambda x: x[0])

# Now we'll created a new dict with the names of the OS calls as keys and the
# function address as values.
func_addr: dict = {}
for k, v in sorted_data:
	hexVal = hex(v).upper()
	if v < 0x10000:
		if k[0:3] == '_OS':
			func_addr[k[1:]] = hexVal  # remove leading underscore from key

# Create more dicts, also with OS calls as keys.
# One stores the indirection address that you call using JSR as values.
# The other stores the comments.
# We'll find this data in the original source file.
# This list actually has more entries than the one above.
jsr_addr = {}
comments: dict = {}
with open('../LIB/cfg_main.asm', 'r', encoding='utf-8') as fh:
	addrCount: int = 0xFF00
	for ln in fh:  # get one line at a time
		line = ln.strip()  # get ride of any whitespace at ends
		if line[0:2] == 'OS':
			deets = line.split('=')
			value = deets[1].strip()
			# now split on ';' to seperate addr from comment
			entry = value.split(';')
			if entry[0][0:2] == 'OS':  # this is something like 'OSWRCH + 3'
				addrCount += 3
				addStr = '{:#04x}'.format(addrCount)
				address = f'{addStr.upper()[2:6]}'
			else:  # it's an item with an actual address
				addr = entry[0].strip()
				address = addr[1:]
			jsr_addr[deets[0].strip()] = address
			if len(entry) > 1:
				comments[deets[0].strip()] = entry[1].strip()
			else:
				comments[deets[0].strip()] = ' '

addrKeys = sorted(jsr_addr.keys())

try:
	with open('output/os_functions.txt', 'w', encoding='utf-8') as fh:
		formatStr = '{0:15}  {1:>4}    {2:^9}    {3}\n'
		fh.write(formatStr.format('OS FUNCTION', 'JSR', 'FUNC ADDR', 'Comment'))
		fh.write(formatStr.format('-----------', '----', '---------', '-------'))
		for key in addrKeys:
			funcA = ''
			if key in func_addr:
				funcA = func_addr[key][2:]
			fh.write(formatStr.format(key, jsr_addr[key], funcA, comments[key]))
except IOError as e:
	print('Cannot open file', e)

try:
	with open('../DOCUMENTATION/os_functions.md', 'w', encoding='utf-8') as fh:
		fh.write('# ZolOS OS Function Calls\n\n')
		fh.write('JSR addresses are the locations of the jump instructions. ')
		fh.write('To call an OS function, you JSR to this address.\n\n')
		fh.write('FUNC ADDR addresses are the start addressed of the actual ')
		fh.write('function code.\n\n')
		formatStr = '| {0} | {1} | {2} | {3} |\n'
		fh.write(formatStr.format('OS FUNCTION', 'JSR', 'FUNC ADDR', 'Comment'))
		fh.write('|---|:---:|:---:|---|\n')
		for key in addrKeys:
			funcA = ''
			if key in func_addr:
				funcA = func_addr[key][2:]
			fh.write(formatStr.format(key, jsr_addr[key], funcA, comments[key]))

except IOError as e:
	print('Cannot open file', e)
