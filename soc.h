#ifndef SOC_H
#define SOC_H

#include <stdint.h>

/* ========================================================================
   Memory Map (from soc_defines.vh)
   ======================================================================== */
#define UART_BASE       0x40000000
#define CTRL_BASE       0x40002000
#define ECG_BASE        0x40003000

/* ========================================================================
   UART Registers
   ======================================================================== */
#define UART_TX_DATA    (*(volatile uint32_t*)(UART_BASE + 0x00))
#define UART_RX_DATA    (*(volatile uint32_t*)(UART_BASE + 0x04))
#define UART_STATUS     (*(volatile uint32_t*)(UART_BASE + 0x08))
#define UART_CONTROL    (*(volatile uint32_t*)(UART_BASE + 0x0C))

#define UART_STATUS_TX_READY (1 << 0)

/* ========================================================================
   Control Registers (GPIO/LEDs)
   ======================================================================== */
#define STATUS_LEDS     (*(volatile uint32_t*)(CTRL_BASE + 0x00))

/* ========================================================================
   ECG Accelerator Registers
   ======================================================================== */
#define ECG_DATA_RAW    (*(volatile uint32_t*)(ECG_BASE + 0x00))
#define ECG_DATA_FILT   (*(volatile uint32_t*)(ECG_BASE + 0x04))
#define ECG_BPM         (*(volatile uint32_t*)(ECG_BASE + 0x08))
#define ECG_THRESHOLD   (*(volatile uint32_t*)(ECG_BASE + 0x0C))

#define ECG_RAW_DATA_MASK  0x0FFF
#define ECG_NEW_DATA_READY (1 << 15)

/* ========================================================================
   Helper Functions
   ======================================================================== */

static inline void uart_putc(char c) {
    while (!(UART_STATUS & UART_STATUS_TX_READY)); // Wait for TX ready
    UART_TX_DATA = c;
}

static inline void uart_print(const char* s) {
    while (*s) uart_putc(*s++);
}

static inline void delay(volatile uint32_t count) {
    while (count--) { __asm__("nop"); }
}

#endif /* SOC_H */
