/* so.s - ESP32 (ESP32-WROOM-32E module and ESP-32S board)
 * bare-metal LED blink on GPIO2.
 *
 * Thanks to the guys who wrote
 * http://cholla.mmto.org/esp32/bootrom/lightning.html
 * and http://cholla.mmto.org/esp8266/xtensa.html.
 * Most of the explanations were taken from there.
 */

.section                .text

// Addresses below 0x4000_0000 are serviced using the data bus.  Addresses in
// the range 0x4000_0000 ~ 0x4FFF_FFFF are serviced using the instruction bus.
//
// The data bus and instruction bus are both little-endian: for example, byte
// addresses 0x0, 0x1, 0x2, 0x3 access the least significant, second least
// significant, second most significant, and the most significant bytes of the
// 32-bit word stored at the 0x0 address, respectively.
// See: https://en.wikipedia.org/wiki/Endianness
// See (page 66, "3.3.1 Address Mapping"):
// https://documentation.espressif.com/esp32_technical_reference_manual_en.pdf
//
// .literal_position directive has logical meaning during compilation. See Makefile.
// See: https://sourceware.org/binutils/docs-2.15/as/Literal-Position-Directive.html
.literal_position
// All docs for registers were taken from "ESP32 Technical Reference Manual Version 5.6".

// These registers are located in the physical memory of the ESP32 and are
// sensitive to the data stored in them. If the data in these registers
// changes, the physical behavior of the corresponding GPIO also changes.

// Register 6.8. GPIO_ENABLE_W1TS_REG (0x0024)
// GPIO_ENABLE_W1TS_REG: GPIO0-31 output enable set register. For every bit
// that is 1 in the value written here, the corresponding bit in GPIO_ENABLE
// will be set. (WO)
gpio_enable:            .word 0x3FF44024

// Register 6.2. GPIO_OUT_W1TS_REG (0x0008)
// GPIO_OUT_W1TS_REG GPIO0-31 output set register. For every bit that is 1 in
// the value written here, the corresponding bit in GPIO_OUT_REG will be set.
// (WO)
gpio_out_set:           .word 0x3FF44008

// Register 6.3. GPIO_OUT_W1TC_REG (0x000c)
// GPIO_OUT_W1TC_REG GPIO0-31 output clear register. For every bit that is 1 in
// the value written here, the corresponding bit in GPIO_OUT_REG will be
// cleared. (WO)
gpio_out_clr:           .word 0x3FF4400C

// This masks GPIO2 bit in registers above (**second** index from end).
// See (a diagram explains it better than words):
// https://documentation.espressif.com/esp32_technical_reference_manual_en.pdf#Regfloat.6.3
gpio2_mask:             .word 0b00000100

// Register 9.30.  RTC_CNTL_WDTCONFIG0_REG (0x008C)
// Configuration register for RWDT.
rtc_wdt_conf:           .word 0x3FF4808C

// Register 10.10. TIMG0_WDTCONFIG0_REG (0x0048)
// Configuration register for MWDT.
timg0_wdt_conf:         .word 0x3FF5F048

// Register 10.10. TIMG1_WDTCONFIG0_REG (0x0048)
// Configuration register for MWDT.
timg1_wdt_conf:         .word 0x3FF60048

// Just a counter to slow down CPU and make a delay between LED activity.
delay_count:            .word 8000000

.global                 call_start_cpu0

// There are 16 tegisters named a0 through a15.
//   a0 is special - it holds the call return address.
//   a1 is used by gcc as a stack pointer.
//   a2 gets used to pass a single argument (and to return a function value).

// 1. Think of the load instructions as "flowing" from right to left. In other words,
//    the first register is the destination, the remaining registers and/or stuff are
//    operands.
// 2. Store instructions are just the opposite, the first register is the
//    source and will be stored at some address generated from the operands.
// 3. Instructions like "add", "and", "xor" flow like the load. The first register is
//    the destination and the operands are on the right.

call_start_cpu0:
        // Disable RTC Watchdog Timer (RWDT).
        // See:
        // https://documentation.espressif.com/esp32_technical_reference_manual_en.pdf#chapter.11
        l32r            a2, rtc_wdt_conf
        movi            a3, 0
        memw
        s32i            a3, a2, 0
        memw

        // Disable 0. Main System Watchdog Timer (MWDT).
        // See:
        // https://documentation.espressif.com/esp32_technical_reference_manual_en.pdf#chapter.11
        l32r            a2, timg0_wdt_conf
        movi            a3, 0
        memw
        s32i            a3, a2, 0
        memw

        // Disable 1. Main System Watchdog Timer (MWDT).
        // See:
        // https://documentation.espressif.com/esp32_technical_reference_manual_en.pdf#chapter.11
        l32r            a2, timg1_wdt_conf
        movi            a3, 0
        memw
        s32i            a3, a2, 0
        memw

        // Enable GPIO2 as output. The l32r instruction fetches a 32 bit
        // constant that is stored (dumped) someplace nearby (hence the actual
        // address where the constant is dumped is of little real interest).
        // This two instructions load data FROM constants TO registers in CPU.

        // The Xtensa uses an instruction known as L32R to load constant values
        // from memory that don't fit into the Xtensa's MOVI immediate load
        // instruction, which has a 12-bit signed immediate field.
        // See: https://stackoverflow.com/a/26610227/17798036
        l32r            a2, gpio_enable
        l32r            a3, gpio2_mask
        // memw is "memory wait". It is basically a CPU pipeline sync. It waits
        // until all data loads and stores finish.
        memw
        // s32i(Ax, Ay, imm): [Ay + imm] = Ax ; Store a 32 bit word.
        // imm is an offset used for pointer arithmetic: Ay[imm] = Ax.
        // This instruction writes data FROM register (a3) TO data bus (a2[0]).
        //
        // This is needed to enable GPIO2, writing in GPIO_ENABLE_W1TS_REG the
        // corresponding value (third less significant bit of the mask loaded in a3
        // CPU register represents GPIO2).
        s32i            a3, a2, 0
        memw
blink_loop:
        /* Set GPIO2 HIGH */
        l32r            a2, gpio_out_set
        l32r            a3, gpio2_mask
        memw
        s32i            a3, a2, 0
        memw
        excw

        /* Delay */
        l32r            a4, delay_count
        memw
delay1:
        // a4 = a4 - 1
        addi            a4, a4, -1
        memw
        // branch (i.e. jump to delay1) if not equal zero
        bnez            a4, delay1

        /* Set GPIO2 LOW */
        l32r            a2, gpio_out_clr
        l32r            a3, gpio2_mask
        memw
        s32i            a3, a2, 0
        memw

        /* Delay */
        l32r            a4, delay_count
        memw
delay2:
        addi            a4, a4, -1
        memw
        bnez            a4, delay2

        memw
        excw

        // Jump unconditionally; aka. blink_loop()
        j               blink_loop
