# The principles and syntax of Makefile are not explained here. Please refer to
# other sources to understand how Makefile works.

# When using '--text-section-literals' to place literals inline in the section
# being assembled, the .literal_position directive can be used to mark a
# potential location for a literal pool.
#
# The assembler will automatically place text section literal pools before
# ENTRY instructions, so the .literal_position directive is only needed to
# specify some other location for a literal pool.
#
# Literal pools are placed by default in separate literal sections; however
# when using the '--text-section-literals' option, the literal pools for
# PC-relative mode L32R instructions are placed in the current section.
#
# The .text section is explicitly placed at the beginning of SRAM0 by the
# Linker Script. L32R instructions are restricted in that all literals must be
# placed before use. Therefore, literals are inlined into the .text section
# before they are used.
# See: https://stackoverflow.com/a/26610227/17798036
#
# For more info, see:
# https://sourceware.org/binutils/docs/as/Literal-Position-Directive.html
# https://sourceware.org/binutils/docs/as/Xtensa-Options.html
so.o: so.s
	xtensa-esp32-elf-as --text-section-literals -o so.o so.s

# -T is used to specify a linker script used. A Linker script's principal use
# is specifying the format and layout of the final executable binary.
#
# ".elf" is Executable and Linkable Format.
# See: https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
so.elf: so.o so.ld
	xtensa-esp32-elf-ld -T so.ld -o so.elf so.o

# The elf2image command converts an ELF file (from compiler/linker output) into
# the binary executable images which can be flashed and then booted into.
# See:
# https://docs.espressif.com/projects/esptool/en/latest/esp32/esptool/basic-commands.html
#
# Flash mode specifies how many GPIOs are used for SPI flash communication. SPI
# flash memory is a type of non-volatile memory that uses a serial peripheral
# interface (SPI) to communicate with a host processor.
# See (not all devices support all modes):
# https://docs.espressif.com/projects/esptool/en/latest/esp32/esptool/flash-modes.html
#
# '--flash_size' specifies how big flash region is.
so.bin: so.elf
	esptool.py --chip esp32 elf2image \
		--flash_mode dio --flash_freq 40m --flash_size 4MB \
		-o so.bin so.elf

all: so.bin

# The next arguments to write_flash are one or more pairs of offset (address)
# and file name.
#
# The first 0x1000 bytes of flash are reserved on ESP32 for Secure Boot. 2nd
# stage bootloader is located at the 0x1000 address in flash memory, directly
# after Secure Boot bytes. This application does not have any bootloader, so
# so.bin is flashed in the place of the bootloader to be directly executed.
#
# See:
# https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/partition-tables.html
flash: all
	esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 115200 \
			write_flash 0x1000 so.bin

clean_flash:
	make clean
	esptool.py --chip esp32 --port /dev/ttyUSB0 erase_flash
	make flash

clean:
	if test -e "so.bin"; then rm so.bin; fi
	if test -e "so.elf"; then rm so.elf; fi
	if test -e "so.o";   then rm so.o;   fi
