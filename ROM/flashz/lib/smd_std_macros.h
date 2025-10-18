/* Standard Defines/Macros */

#ifndef __MS_STD_MACROS__
#define __MS_STD_MACROS__

// Ensure we have io/sfr/pindefs loaded
#ifndef   _AVR_IO_H_
#include  <avr/io.h>
#endif

#ifndef ON
#	define ON 1
#endif
#ifndef OFF
	#define OFF 0
#endif
#ifndef LOW
	#define LOW  0
#endif
#ifndef HIGH
	#define HIGH 1 
#endif
#ifndef EVEN
	#define EVEN 0
#endif
#ifndef ODD
	#define ODD  1
#endif

/* Following macros are always included in avr/sfr_defs.h, called from avr/io.h

 bit_is_set(sfr, bit)
 bit_is_clear(sfr, bit)
 loop_until_bit_is_set(sfr, bit)
 loop_until_bit_is_clear(sfr, bit)

*/

/* Bit-handling macros */
#define BV(bit)              (1 << bit)					// replicates old _BV() macro
#define SETBIT(sfr, bit)     (_SFR_BYTE(sfr) |= BV(bit))	// old sbi()
#define CLEARBIT(sfr, bit)   (_SFR_BYTE(sfr) &= ~BV(bit))	// old cbi()
#define TOGGLEBIT(sfr, bit)  (_SFR_BYTE(sfr) ^= BV(bit))

#endif
