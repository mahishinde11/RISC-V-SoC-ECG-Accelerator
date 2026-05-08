/* start.S - Startup code for RISC-V SoC */

.section .text.boot
.global _start

_start:
    /* Initialize Stack Pointer to top of DMEM (0x10004000) */
    la sp, _stack_ptr
    
    /* Clear BSS (optional but good practice) */
    /* (Skipped for simplicity in this minimal SoC) */

    /* Call main() */
    call main

    /* Loop forever if main returns */
_exit:
    j _exit
