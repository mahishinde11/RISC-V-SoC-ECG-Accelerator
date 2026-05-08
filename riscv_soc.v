// ============================================================================
// RISC-V SoC Top Level
// ============================================================================

`include "soc_defines.vh"

module riscv_soc (
    input  wire clk,
    input  wire rst_n,

    // UART external interface
    output wire uart_tx,
    input  wire uart_rx,

    // Debug LEDs
    output wire [7:0] status_leds, // LED[0] is hardware monitor for JA-1

    // STM32 External ADC interface
    input  wire stm32_rx
);

    // ================= APB Master Signals =================

    wire [31:0] apb_paddr;
    wire        apb_pwrite;
    wire [31:0] apb_pwdata;
    wire        apb_psel;
    wire        apb_penable;
    wire [31:0] apb_prdata;
    wire        apb_pready;
    wire        apb_pslverr;

    // ================= UART Slave Signals =================

    wire        uart_psel;
    wire        uart_penable;
    wire        uart_pwrite;
    wire [31:0] uart_paddr;
    wire [31:0] uart_pwdata;
    wire [31:0] uart_prdata;
    wire        uart_pready;
    wire        uart_pslverr;

    // ================= Control Register Signals =================

    wire        ctrl_psel;
    wire        ctrl_penable;
    wire        ctrl_pwrite;
    wire [31:0] ctrl_paddr;
    wire [31:0] ctrl_pwdata;
    wire [31:0] ctrl_prdata;
    wire        ctrl_pready;
    wire        ctrl_pslverr;

    // ================= Debug Signals =================
    wire [7:0] soc_leds;
    assign status_leds = {soc_leds[7:1], ~stm32_rx}; // LED 0 flickers if data arrives

    // ================= ECG Signals =================

    wire        ecg_psel;
    wire        ecg_penable;
    wire        ecg_pwrite;
    wire [31:0] ecg_paddr;
    wire [31:0] ecg_pwdata;
    wire [31:0] ecg_prdata;
    wire        ecg_pready;
    wire        ecg_pslverr;

    // ================= PicoRV32 Core & APB Bridge =================
    
    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [ 3:0] mem_wstrb;
    wire [31:0] mem_rdata;

    picorv32 #(
        .PROGADDR_RESET(32'h0000_0000),
        .STACKADDR(32'h0000_4000),     // End of IMEM used as initial stack
        .BARREL_SHIFTER(1),
        .COMPRESSED_ISA(0),
        .ENABLE_MUL(0),
        .ENABLE_DIV(0),
        .ENABLE_IRQ(0)
    ) cpu_core (
        .clk(clk),
        .resetn(sys_rst_n),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata)
    );

    wire [11:0] imem_addr;
    wire [31:0] imem_rdata;
    wire [11:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [ 3:0] dmem_we;
    wire [31:0] dmem_rdata;

    // ================= Reset Inversion (Basys3 buttons are active-high) =================
    wire sys_rst_n = ~rst_n;

    picorv32_apb_bridge cpu_bridge (
        .clk(clk),
        .rst_n(sys_rst_n),

        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),

        .apb_psel(apb_psel),
        .apb_penable(apb_penable),
        .apb_paddr(apb_paddr),
        .apb_pwrite(apb_pwrite),
        .apb_pwdata(apb_pwdata),
        .apb_pready(apb_pready),
        .apb_prdata(apb_prdata),
        .apb_pslverr(apb_pslverr),

        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_rdata(dmem_rdata)
    );

    soc_imem imem_inst (
        .clk(clk),
        .addr(imem_addr),
        .rdata(imem_rdata)
    );

    soc_dmem dmem_inst (
        .clk(clk),
        .addr(dmem_addr),
        .wdata(dmem_wdata),
        .we(dmem_we),
        .rdata(dmem_rdata)
    );

    // ================= APB Bus =================

    apb_bus bus (

        .m_apb_paddr(apb_paddr),
        .m_apb_pwrite(apb_pwrite),
        .m_apb_pwdata(apb_pwdata),
        .m_apb_psel(apb_psel),
        .m_apb_penable(apb_penable),
        .m_apb_prdata(apb_prdata),
        .m_apb_pready(apb_pready),
        .m_apb_pslverr(apb_pslverr),

        .uart_psel(uart_psel),
        .uart_penable(uart_penable),
        .uart_pwrite(uart_pwrite),
        .uart_paddr(uart_paddr),
        .uart_pwdata(uart_pwdata),
        .uart_prdata(uart_prdata),
        .uart_pready(uart_pready),
        .uart_pslverr(uart_pslverr),

        .ctrl_psel(ctrl_psel),
        .ctrl_penable(ctrl_penable),
        .ctrl_pwrite(ctrl_pwrite),
        .ctrl_paddr(ctrl_paddr),
        .ctrl_pwdata(ctrl_pwdata),
        .ctrl_prdata(ctrl_prdata),
        .ctrl_pready(ctrl_pready),
        .ctrl_pslverr(ctrl_pslverr),

        .ecg_psel(ecg_psel),
        .ecg_penable(ecg_penable),
        .ecg_pwrite(ecg_pwrite),
        .ecg_paddr(ecg_paddr),
        .ecg_pwdata(ecg_pwdata),
        .ecg_prdata(ecg_prdata),
        .ecg_pready(ecg_pready),
        .ecg_pslverr(ecg_pslverr)
    );

    // ================= UART =================

    uart_apb_slave uart (
        .clk(clk),
        .rst_n(sys_rst_n),

        .apb_psel(uart_psel),
        .apb_penable(uart_penable),
        .apb_pwrite(uart_pwrite),
        .apb_paddr(uart_paddr),
        .apb_pwdata(uart_pwdata),
        .apb_prdata(uart_prdata),
        .apb_pready(uart_pready),
        .apb_pslverr(uart_pslverr),

        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );

    // ================= Control Registers =================

    ctrl_regs_apb_slave ctrl (
        .clk(clk),
        .rst_n(sys_rst_n),

        .apb_psel(ctrl_psel),
        .apb_penable(ctrl_penable),
        .apb_pwrite(ctrl_pwrite),
        .apb_paddr(ctrl_paddr),
        .apb_pwdata(ctrl_pwdata),
        .apb_prdata(ctrl_prdata),
        .apb_pready(ctrl_pready),
        .apb_pslverr(ctrl_pslverr),

        .status_leds(soc_leds)
    );

    // ================= ECG Accelerator =================

    ecg_accelerator_apb ecg (
        .clk(clk),
        .rst_n(sys_rst_n),

        .apb_psel(ecg_psel),
        .apb_penable(ecg_penable),
        .apb_pwrite(ecg_pwrite),
        .apb_paddr(ecg_paddr),
        .apb_pwdata(ecg_pwdata),
        .apb_prdata(ecg_prdata),
        .apb_pready(ecg_pready),
        .apb_pslverr(ecg_pslverr),
 
        .stm32_rx(stm32_rx)
    );

endmodule


// ============================================================================
// APB BUS (Interconnect)
// ============================================================================

module apb_bus (
    // Master interface (from Bridge)
    input  wire [31:0] m_apb_paddr,
    input  wire        m_apb_pwrite,
    input  wire [31:0] m_apb_pwdata,
    input  wire        m_apb_psel,
    input  wire        m_apb_penable,
    output reg  [31:0] m_apb_prdata,
    output wire        m_apb_pready,
    output wire        m_apb_pslverr,

    // UART Slave
    output wire        uart_psel,
    output wire        uart_penable,
    output wire        uart_pwrite,
    output wire [31:0] uart_paddr,
    output wire [31:0] uart_pwdata,
    input  wire [31:0] uart_prdata,
    input  wire        uart_pready,
    input  wire        uart_pslverr,

    // CTRL Slave
    output wire        ctrl_psel,
    output wire        ctrl_penable,
    output wire        ctrl_pwrite,
    output wire [31:0] ctrl_paddr,
    output wire [31:0] ctrl_pwdata,
    input  wire [31:0] ctrl_prdata,
    input  wire        ctrl_pready,
    input  wire        ctrl_pslverr,

    // ECG Slave
    output wire        ecg_psel,
    output wire        ecg_penable,
    output wire        ecg_pwrite,
    output wire [31:0] ecg_paddr,
    output wire [31:0] ecg_pwdata,
    input  wire [31:0] ecg_prdata,
    input  wire        ecg_pready,
    input  wire        ecg_pslverr
);

    // Address decoding
    // UART: 0x4000_0000 to 0x4000_1FFF
    // CTRL: 0x4000_2000 to 0x4000_2FFF
    // ECG:  0x4000_3000 to 0x4000_3FFF

    assign uart_psel = m_apb_psel && (m_apb_paddr[15:12] == 4'h0);
    assign ctrl_psel = m_apb_psel && (m_apb_paddr[15:12] == 4'h2);
    assign ecg_psel  = m_apb_psel && (m_apb_paddr[15:12] == 4'h3);

    // Signals passed to all slaves
    assign uart_penable = m_apb_penable;
    assign ctrl_penable = m_apb_penable;
    assign ecg_penable  = m_apb_penable;

    assign uart_pwrite = m_apb_pwrite;
    assign ctrl_pwrite = m_apb_pwrite;
    assign ecg_pwrite  = m_apb_pwrite;

    assign uart_paddr = m_apb_paddr;
    assign ctrl_paddr = m_apb_paddr;
    assign ecg_paddr  = m_apb_paddr;

    assign uart_pwdata = m_apb_pwdata;
    assign ctrl_pwdata = m_apb_pwdata;
    assign ecg_pwdata  = m_apb_pwdata;

    // Response multiplexing
    always @(*) begin
        case (m_apb_paddr[15:12])
            4'h0:    m_apb_prdata = uart_prdata;
            4'h2:    m_apb_prdata = ctrl_prdata;
            4'h3:    m_apb_prdata = ecg_prdata;
            default: m_apb_prdata = 32'h0;
        endcase
    end

    assign m_apb_pready  = (m_apb_paddr[15:12] == 4'h0) ? uart_pready :
                           (m_apb_paddr[15:12] == 4'h2) ? ctrl_pready :
                           (m_apb_paddr[15:12] == 4'h3) ? ecg_pready  :
                           1'b1;

    assign m_apb_pslverr = (m_apb_paddr[15:12] == 4'h0) ? uart_pslverr :
                           (m_apb_paddr[15:12] == 4'h2) ? ctrl_pslverr :
                           (m_apb_paddr[15:12] == 4'h3) ? ecg_pslverr  :
                           1'b0;

endmodule


// ============================================================================
// UART APB SLAVE
// ============================================================================

module uart_apb_slave (

    input  wire clk,
    input  wire rst_n,

    input  wire apb_psel,
    input  wire apb_penable,
    input  wire apb_pwrite,
    input  wire [31:0] apb_paddr,
    input  wire [31:0] apb_pwdata,

    output reg  [31:0] apb_prdata,
    output wire apb_pready,
    output wire apb_pslverr,

    output reg uart_tx,
    input  wire uart_rx
);

assign apb_pready  = 1'b1;
assign apb_pslverr = 1'b0;

// ================= UART REGISTERS =================

reg [8:0] tx_shift;       // stop + data
reg [3:0] tx_bit_cnt;
reg       tx_busy;

localparam BAUD_DIV = 868;

reg [11:0] tx_baud_cnt;

// ================= UART TX =================

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        uart_tx     <= 1'b1;
        tx_shift    <= 9'h1FF;
        tx_bit_cnt  <= 0;
        tx_baud_cnt <= 0;
        tx_busy     <= 0;

    end else begin

        if (!tx_busy) begin

            if (apb_psel && apb_penable && apb_pwrite && (apb_paddr[7:0] == 8'h00)) begin

                tx_shift    <= {1'b1, apb_pwdata[7:0]}; // stop + data
                tx_busy     <= 1'b1;
                tx_bit_cnt  <= 4'd9;
                tx_baud_cnt <= BAUD_DIV - 1;

                uart_tx <= 1'b0; // start bit

            end

        end else begin

            if (tx_baud_cnt == 0) begin

                if (tx_bit_cnt > 0) begin

                    uart_tx     <= tx_shift[0];
                    tx_shift    <= {1'b1, tx_shift[8:1]};
                    tx_bit_cnt  <= tx_bit_cnt - 1;
                    tx_baud_cnt <= BAUD_DIV - 1;

                end else begin

                    tx_busy <= 0;
                    uart_tx <= 1'b1;

                end

            end else begin

                tx_baud_cnt <= tx_baud_cnt - 1;

            end

        end

    end

end

// ================= READ REGISTER =================

always @(*) begin

    apb_prdata = 32'h0;

    if (apb_psel && !apb_pwrite) begin

        case (apb_paddr[7:0])

            8'h08: apb_prdata = {31'h0, !tx_busy};

            default: apb_prdata = 32'h0;

        endcase

    end

end

endmodule


// ============================================================================
// CONTROL REGISTER SLAVE
// ============================================================================

module ctrl_regs_apb_slave (

    input wire clk,
    input wire rst_n,

    input wire apb_psel,
    input wire apb_penable,
    input wire apb_pwrite,
    input wire [31:0] apb_paddr,
    input wire [31:0] apb_pwdata,

    output reg [31:0] apb_prdata,
    output wire apb_pready,
    output wire apb_pslverr,

    output reg [7:0] status_leds
);

assign apb_pready  = 1'b1;
assign apb_pslverr = 1'b0;

always @(posedge clk or negedge rst_n) begin

    if (!rst_n)
        status_leds <= 8'h00;

    else if (apb_psel && apb_penable && apb_pwrite)

        case (apb_paddr[7:0])

            8'h00: status_leds <= apb_pwdata[7:0];

        endcase

end


always @(*) begin

    apb_prdata = 0;

    if (apb_psel && !apb_pwrite)

        case (apb_paddr[7:0])

            8'h00: apb_prdata = {24'h0, status_leds};

        endcase

end

endmodule