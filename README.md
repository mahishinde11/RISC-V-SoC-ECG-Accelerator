# RISC-V-SoC-ECG-Accelerator
This project presents a RISC-V based System-on-Chip (SoC) integrated with a dedicated ECG hardware  accelerator for real-time ECG processing. The accelerator implements the Pan–Tompkins algorithm, including  bandpass filtering (5–15 Hz), derivative filtering, squaring, moving window integration, and adaptive R-peak  detection.
The proposed system contributes by: 
1. Implementing the complete Pan–Tompkins QRS detection pipeline in hardware. 
2. Using fixed-point arithmetic for FPGA efficiency. 
3. Integrating UART communication for real-time monitoring. 
4. Computing heart rate directly in hardware using RR interval measurement. 
5. Ensuring resource-efficient FPGA implementation. 
The integration of ECG processing and serial communication into a unified hardware architecture distinguishes the proposed design from previous standalone implementations.

HARDWARE OVERVIEW: 
AD8232 Sensor 
ADC 
FPGA Board : Digilent BASYS 3 
RISC-V CORE: 
1. Program Counter 
2. 32 × 32-bit Register File 
3. Arithmetic Logic Unit (ALU) 
4. Instruction Decoder 

MEMORY SUBSYSTEM: 
1. 16 KB Instruction Memory 
2. 16 KB Data Memory 
 
SOFTWARE OVERVIEW: 
The software running on the RISC-V processor performs: System initialization & peripheral configuration 

Ecg accelerator control: Implements Pan–Tompkins stages: Bandpass Filter, Derivative Unit, Squaring Unit,  Moving Window Integrator, Adaptive Threshold Detector 
 
UART Peripheral:Transmitter (TX), Receiver (RX), Baud Rate Generator (9600 / 115200 bps), Reading processed results & UART communication 
