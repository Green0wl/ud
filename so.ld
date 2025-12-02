ENTRY(call_start_cpu0)

MEMORY
{
    iram (RWX) : ORIGIN = 0x40080000, LENGTH = 0x20000
    dram (RW)  : ORIGIN = 0x3FFB0000, LENGTH = 0x30000
}

SECTIONS
{
    .text : ALIGN(4) {
        *(.text)
        *(.text.*)
        *(.literal)
        *(.literal.*)
    } > iram

    .rodata : ALIGN(4)
    {
        *(.rodata)
        *(.rodata.*)
    } > dram

    .data : ALIGN(4)
    {
        *(.data)
        *(.data.*)
    } > dram

    .bss : ALIGN(4)
    {
        *(.bss)
        *(.bss.*)
    } > dram
}
