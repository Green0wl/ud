so.o: so.s
	xtensa-esp32-elf-as --text-section-literals -o so.o so.s

so.elf: so.o esp32.ld
	xtensa-esp32-elf-ld -T esp32.ld -o so.elf so.o

so.bin: so.elf
	esptool.py --chip esp32 elf2image \
		--flash_mode dio --flash_freq 40m --flash_size 4MB \
		-o so.bin so.elf

all: so.bin

flash: all
	esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 115200 \
			write_flash 0x1000 so.bin

clean:
	if test -e "so.bin"; then rm so.bin; fi
	if test -e "so.elf"; then rm so.elf; fi
	if test -e "so.o";   then rm so.o;   fi
