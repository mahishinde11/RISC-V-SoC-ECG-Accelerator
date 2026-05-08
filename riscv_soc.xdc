## Xilinx Design Constraints — RISC-V SoC (Basys3, Artix-7 XC7A35T-1CPG236C)
## riscv_soc.xdc
## ============================================================
##  Top-level port  |  Basys3 pin  |  Notes
## ============================================================
##  clk             |  W5          |  100 MHz onboard XTAL oscillator
##  rst_n           |  U18         |  Center pushbutton (active low — press to reset)
##  uart_tx         |  A18         |  USB-UART bridge TX  (connect to PC at 115200)
##  uart_rx         |  B18         |  USB-UART bridge RX
##  status_leds[7]  |  V14         |  LD7  (official Basys3 Master XDC)
##  status_leds[6]  |  U14         |  LD6
##  status_leds[5]  |  U15         |  LD5
##  status_leds[4]  |  W18         |  LD4
##  status_leds[3]  |  V19         |  LD3
##  status_leds[2]  |  U19         |  LD2
##  status_leds[1]  |  E19         |  LD1
##  status_leds[0]  |  U16         |  LD0
## ============================================================

# ── Clock ──────────────────────────────────────────────────────────────────
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

# ── Reset (Centre button, active LOW) ─────────────────────────────────────
set_property PACKAGE_PIN U18 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# ── CPU UART (USB-UART bridge on Basys3) ──────────────────────────────────
set_property PACKAGE_PIN A18 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

set_property PACKAGE_PIN B18 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

# ── Status LEDs (LD0–LD7) — Official Basys3 pin assignments ──────────────
set_property PACKAGE_PIN U16 [get_ports {status_leds[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {status_leds[0]}]

set_property PACKAGE_PIN E19 [get_ports {status_leds[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {status_leds[1]}]

set_property PACKAGE_PIN U19 [get_ports {status_leds[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {status_leds[2]}]

set_property PACKAGE_PIN V19 [get_ports {status_leds[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {status_leds[3]}]

set_property PACKAGE_PIN W18 [get_ports {status_leds[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {status_leds[4]}]

set_property PACKAGE_PIN U15 [get_ports {status_leds[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {status_leds[5]}]

set_property PACKAGE_PIN U14 [get_ports {status_leds[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {status_leds[6]}]

set_property PACKAGE_PIN V14 [get_ports {status_leds[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {status_leds[7]}]

# ── STM32 External ADC Interface (UART RX on JA-1) ────────────────────────
set_property PACKAGE_PIN J1 [get_ports stm32_rx]
set_property IOSTANDARD LVCMOS33 [get_ports stm32_rx]
set_property PULLUP TRUE [get_ports stm32_rx]
# Note: Pins M2, L3, J3, K3 on JXADC have voltage dividers; use JA pins for UART.

# ── Configuration/Bitstream Settings ─────────────────────────────────────
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

