# Makefile for ATmega4809-based projects.

MCU   = atmega4809		# Microcontroller
F_CPU = 20000000UL  	# Clock speed

LIBCOMMON = $(HOME)/avrlib/avr-common
LIBCPP = $(HOME)/avrlib/avr-c++

TARGET = flashrom

CPPSOURCES = $(wildcard *.cpp)
CPPSOURCES += $(wildcard lib/*.cpp)

CPPHEADERS = $(CPPSOURCES:.cpp=.h)
CPPSOURCES += $(wildcard lib/*.h)

# PROGRAMMER_TYPE = serialupdi
# PROGRAMMER_ARGS = -P usb -B 125kHz
PROGRAMMER_TYPE = serialupdi
PROGRAMMER_ARGS = -P /dev/ttyUSB0 -b 115200

CXX = avr-g++
OBJCOPY = avr-objcopy
OBJDUMP = avr-objdump
AVRSIZE = avr-size
AVRDUDE = avrdude

OBJECTS = $(CPPSOURCES:.cpp=.o)
CPPFLAGS = -Os -DF_CPU=$(F_CPU) -I.     # Optimise, CPU
CPPFLAGS += -I$(LIBCOMMON) -I$(LIBCPP)  # My libraries
CPPFLAGS += -Wall # C++ standard, most warnings
CPPFLAGS += -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
CPPFLAGS += -ffunction-sections -fdata-sections # Places each function/data object in its own section

LDFLAGS = -DF_CPU=$(F_CPU) -Os -Wl,-Map,$(TARGET).map
LDFLAGS += -Wl,--gc-sections    # Can result in smaller code

DEBUGFLAGS = -g -DDEBUG

TARGET_ARCH = -mmcu=$(MCU)

%.o: %.cpp $(CPPHEADERS) Makefile
	$(CXX) $(CPPFLAGS) $(TARGET_ARCH) -c -o $@ $<;

$(TARGET).elf: $(OBJECTS) # invokes the objects comiled above
	$(CXX) $(LDFLAGS) $(TARGET_ARCH) $^ $(LDLIBS) -o $@

%.hex: %.elf  # invokes .elf target above
	 $(OBJCOPY) -j .text -j .data -j .rodata -O ihex $< $@

%.eeprom: %.elf
	$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O ihex $< $@

%.lst: %.elf
	$(OBJDUMP) -S $< > $@

.PHONY: all disassemble disasm eeprom size clean flash fuse_enable_reset

all: $(TARGET).hex # invokes .hex targets

debug: CPPFLAGS += $(DEBUGFLAGS)
debug: $(TARGET).hex

disassemble: $(TARGET).lst

disasm: disassemble

size:  $(TARGET).elf
	$(AVRSIZE) -C --mcu=$(MCU) $(TARGET).elf

clean:
	rm -f *.elf *.hex *.obj *.o *.d *.eep *.lst *.lss *.sym *.map *~ *.eeprom lib/*.o

flash: $(TARGET).hex
	$(AVRDUDE) -c $(PROGRAMMER_TYPE) -p $(MCU) $(PROGRAMMER_ARGS) -U flash:w:$<

flash_eeprom: $(TARGET).eeprom
	$(AVRDUDE) -c $(PROGRAMMER_TYPE) -p $(MCU) $(PROGRAMMER_ARGS) -U eeprom:w:$<

avrdude_terminal:
	$(AVRDUDE) -c $(PROGRAMMER_TYPE) -p $(MCU) $(PROGRAMMER_ARGS) -nt

avr-reset:
	$(AVRDUDE) -c $(PROGRAMMER_TYPE) -p $(MCU) $(PROGRAMMER_ARGS)

# FUSE SETTINGS

fuse_enable_reset:
    # avrdude -p atmega4809 -c serialupdi -P /dev/ttyS0 -U fuse5:w:0xc8:m
	$(AVRDUDE) -c $(PROGRAMMER_TYPE) -p $(MCU) \
	           $(PROGRAMMER_ARGS) -U fuse5:w:0xc8:m

fuse_fast_clock:
    # avrdude -p atmega4809 -c serialupdi -P /dev/ttyS0 -U fuse2:w:0x02:m
	$(AVRDUDE) -c $(PROGRAMMER_TYPE) -p $(MCU) \
	           $(PROGRAMMER_ARGS) -U fuse2:w:0x02:m

info:
    # avrdude -p atmega4809 -c serialupdi -P /dev/ttyS0 -v
	$(AVRDUDE) -c $(PROGRAMMER_TYPE) -p $(MCU) \
	           $(PROGRAMMER_ARGS) -v
