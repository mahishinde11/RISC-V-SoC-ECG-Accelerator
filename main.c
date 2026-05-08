#include "soc.h"

// Helper to print a number to UART
void uart_print_int(uint32_t n) {
    char buf[12];
    int i = 0;
    if (n == 0) buf[i++] = '0';
    while (n > 0 && i < 11) {
        buf[i++] = (n % 10) + '0';
        n /= 10;
    }
    while (i > 0) uart_putc(buf[--i]);
}

int main() {
    // Initial configuration
    STATUS_LEDS = 0xAA;
    ECG_THRESHOLD = 0x000009C4; // Target 2,500 for a calibrated 250Hz signal
    
    uart_print("\r\n--- ECG Waveform Streamer ---\r\n");
    uart_print("Connect a Serial Plotter to see the waves!\r\n");
    uart_print("Format: [RAW] [MA_FILT] [BPM]\r\n");

    uint32_t wait_cnt = 0;
    while (1) {
        // Read the Raw Register (which contains the New Data Ready bit)
        uint32_t raw_status = ECG_DATA_RAW;
        
        // Wait for a fresh sample from the STM32
        if (raw_status & ECG_NEW_DATA_READY) {
            wait_cnt = 0;
            uint16_t raw_val = raw_status & ECG_RAW_DATA_MASK;
            uint32_t filtered = ECG_DATA_FILT;
            uint32_t bpm      = ECG_BPM;
            
            // Format: RAW FILT BPM\n
            uart_print_int(raw_val);
            uart_putc(' '); 
            uart_print_int(filtered); // Printing full value for threshold tuning
            uart_putc(' ');
            uart_print_int(bpm);
            uart_print("\r\n");

            // Toggle LED to show active streaming
            static int toggle = 0;
            if (++toggle > 50) {
                STATUS_LEDS = ~STATUS_LEDS;
                toggle = 0;
            }
        } else {
            // Heartbeat/Timeout check
            if (++wait_cnt > 3000000) { 
                uint32_t status = ECG_DATA_RAW;
                uart_print("Waiting... Pin JA-1 is ");
                if (status & (1U << 31)) {
                    uart_print("HIGH (Idle)\r\n");
                } else {
                    uart_print("LOW (Active/Disconnected)\r\n");
                }
                wait_cnt = 0;
            }
        }
    }

    return 0;
}
