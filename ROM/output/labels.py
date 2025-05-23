#!/usr/bin/env python3

''' This script opens the Swift-compatible label file output by the Beebasm
	assembler, converts it to Json and then writes out a sorted list of
	labels as a new file.
'''

import json

# Read the file
with open('output/labels.swift', 'r') as file:
	data = file.read()

# Tidy it up
data = data.replace('[', '')
data = data.replace(']', '')
data = data.replace("'", '"')  # Change single quotes to double quotes
data = data.replace('L}', '}') # Get rid of Ls at the end of numbers
data = data.replace('L,', ',')

# Convert to Json
json_data = json.loads(data)

# Sort by the value field
sorted_data = (sorted(json_data.items(), key=lambda x:x[1]))

# Output sorted dict as a file.
try:
	with open('output/labels.txt', 'w', encoding='utf-8') as fh:
		for k,v in sorted_data:
			hexVal = hex(v).upper()
			if v < 0x10000:
				fh.write(hexVal[2:] + '    ' + k + "\n")
except IOError as e:
	print('Cannot open file')
