/* link.ld - Linker script for RISC-V SoC */

MEMORY
{
    /* 16KB Instruction Memory */
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
    /* 16KB Data Memory */
    RAM (rwa) : ORIGIN = 0x10000000, LENGTH = 16K
}

SECTIONS
{
    /* Code segment starts at 0x0000_0000 */
    .text :
    {
        KEEP(*(.text.boot))   /* Startup code must be first */
        *(.text)
        *(.text.*)
    } > ROM

    /* Read-only data (strings, constants) */
    .rodata :
    {
        *(.rodata)
        *(.rodata.*)
    } > ROM

    /* Initialized data (copied to RAM by hardware or startup code)
       Note: In this simple SoC, BRAM initialization handles this. */
    .data :
    {
        _sdata = .;
        *(.data)
        *(.data.*)
        _edata = .;
    } > RAM AT > ROM

    /* Uninitialized data (zeroed by startup) */
    .bss :
    {
        _sbss = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        _ebss = .;
    } > RAM

    /* Set stack pointer to the top of RAM */
    _stack_ptr = ORIGIN(RAM) + LENGTH(RAM);
}
