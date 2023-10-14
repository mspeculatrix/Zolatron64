# Z64IODECODE

CUPL code for address decoding logic for the Z64.

Target device: ATF1504AS

This provides address decoding for:

- 7x 1KB spaces with start addresses A000 to B800.
- 8x 32B spaces with start addresses BF00 to BFE0.

It also provides the following signals:

- Clock-qualified /READ_EN
- Clock-qualified /WRITE_EN
- /ROM_ENABLE
- /IO_EN

Used on the SPI interface board.
