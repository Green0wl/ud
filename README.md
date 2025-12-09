## Description:
The objective of the project is to provide a rudimentary version of the functionality that instigates the periodic blinking of the built-in LED on the ESP32 (chip: ESP32-WROOM-32; board: ESP-32S). The programming of the 32-bit Xtensa LX6 processor is achieved through the utilisation of assembly (RISC-V 32-bit) language.

The provided code has the theoretical capacity to function on any microcontroller from the ESP32 family that is equipped with an LED connected to GPIO2. In the case of ESP32 microcontrollers devoid of an onboard LED on GPIO2, it has been theorised that the utilisation of a regular LED accompanied by a resistor of the appropriate resistance should yield results that are analogous.

The project is divided into three constituent parts, which are described in the `Makefile`, `so.ld`, and `so.s` files. The purpose of these files is to automate the build process, to specify the format and layout of the final executable binary, and to describe the functionality in Assembly, respectively.

It is assumed that the connected ESP32 is recognized by the system as `/dev/ttyUSB0`. This address is used in the following sections and automated scripts.

Should further elucidation be required, direct reference to the code is advised, as it is comprehensively documented.

## Command line installation of dependencies (Ubuntu):
```shell
~$ sudo apt-get install git wget flex bison gperf python3 python3-venv cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0 build-essential
~$ mkdir -p ~/esp
~$ cd ~/esp

# First, find out what the latest version tag is. At the time this documentation was created, v5.5.1 was the latest version.
~/esp$ git clone -b v5.5.1 -recursive https://github.com/espressif/esp-idf.git

~/esp$ cd ./esp-idf
~/esp/esp-idf$ ./install.sh esp32
~/esp/esp-idf$ . ./export.sh

# Optional: check whether tooling has been installed.
~/esp/esp-idf$ idf.py --help
```

## Flashing:
It is to be assumed that the dependency installation section was completed in strict accordance with the instructions provided. This section provides a comprehensive, step-by-step guide to the process of reflashing the ESP32 with the aforementioned specifications, with the objective of achieving LED blinking.
```shell
# Clone the project:
~$ cd ~/Downloads/
~/Downloads$ git clone https://github.com/Green0wl/esp32-asm-blink.git

# Prepare environment variables:
~/Downloads$ cd ~/esp/esp-idf/
~/esp/esp-idf$ . ./export.sh

# Compile and flash (plug ESP32 now):
~/esp/esp-idf$ cd ~/Downloads/esp32-asm-blink/
~/Downloads/esp32-asm-blink$ make flash
# Approximately two seconds later, the ESP-32S should begin to blink.
```

## Erasing:
These commands will clear the ESP32 flash memory of instructions that cause the LED to flash:
```shell
~$ cd ~/esp/esp-idf/
~/esp/esp-idf$ . ./export.sh
~/esp/esp-idf$ esptool.py --chip esp32 --port /dev/ttyUSB0 erase_flash
```
