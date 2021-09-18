#!/usr/bin/env bash
CODE_VERSION="03"
echo "Assembling..."
beebasm -i z64-${CODE_VERSION}.asm

echo "Writing to EEPROM..."
minipro -p AT28C256 -w z64-ROM-${CODE_VERSION}.bin

exit 0
