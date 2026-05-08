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
# WORKING 
<img width="1170" height="742" alt="image" src="https://github.com/user-attachments/assets/187ba4ab-55f8-4357-9c89-e36d3fdc730a" />


1. The proposed system is a hardware-software co-designed RISC-V SoC integrated with an ECG accelerator for real-time ECG signal processing.


2. The ECG signal is acquired using the AD8232 sensor and converted into digital form using an ADC.


3. The digitized ECG data is fed into the FPGA, where the ECG accelerator processes the signal using a pipelined architecture.


4. A bandpass filter (5–15 Hz) is applied to remove noise and baseline drift from the ECG signal.


5. The filtered signal is processed through a derivative block to emphasize slope information required for QRS complex detection.


6. A squaring unit enhances the prominent peaks of the ECG waveform for accurate feature extraction.


7. A moving window integrator is used to extract waveform characteristics and smooth the processed signal.


8. An adaptive threshold mechanism detects R-peaks while minimizing false detections using a refractory period technique.


9. Heart rate is calculated using the RR interval between consecutive detected R-peaks.


10. All signal-processing computations are implemented using fixed-point arithmetic to achieve hardware efficiency and reduced resource utilization.


11. The RISC-V processor manages system initialization, configuration, control operations, and data handling.


12. Processed ECG data and computed heart-rate values are stored in memory and transmitted to external devices through a UART communication interface.


The overall architecture provides real-time performance, low latency, and efficient hardware utilization, making it suitable for continuous ECG monitoring applications.

<img width="973" height="604" alt="image" src="https://github.com/user-attachments/assets/f67fa6a1-7c07-4d3f-a98b-4d33e4e0090d" />
 
From this plot, sharp peaks are visible in the waveform, which correspond to R-peak detections. These 
peaks occur at regular intervals, validating correct heart activity tracking and RR interval measurement. 
The system successfully: 
1. Detected QRS complexes accurately  

2. Produced distinct R-peaks for heart rate calculation  

3. Maintained stable signal processing without distortion  

4. Transmitted data reliably via UART at both 9600 and 115200 baud rates  

5. Achieved real-time performance with low latency 

<img width="1280" height="654" alt="image" src="https://github.com/user-attachments/assets/2e31fd7d-4f0f-420e-a8dd-f18e734cf6ca" />

The system was tested using real-time ECG data, and the outputs were visualized through the serial 
plotter, as shown in the provided figures. 
From the plot above, multiple signal stages are observed: 
1. The blue waveform represents the filtered ECG signal, showing smooth variations after noise removal.  

2.The orange waveform corresponds to the processed signal after squaring and integration, clearly highlighting the QRS complex with a prominent rise and fall pattern.  

3. The third signal remains near zero, indicating stable baseline or controlled output behavior.

# CONCLUSION
The project successfully implements a RISC-V based SoC integrated with an ECG hardware accelerator 
for real-time signal processing. The observed results confirm that the hardware implementation of the 
Pan–Tompkins algorithm effectively enhances ECG signals and accurately detects QRS complexes and R-peaks. 
 
The FPGA-based design provides significant advantages such as parallel processing, deterministic 
timing, and reduced computational load on the processor. The UART interface enables reliable 
communication of processed data to external systems, as verified through serial plotter outputs. 
 
The system maintained stable and accurate data transmission under the tested conditions. Overall, the 
design demonstrates an efficient, low-latency, and resource-optimized solution suitable for real-time 
and portable ECG monitoring applications. 
