// picorv32_apb_bridge.v
// Connects PicoRV32 native memory interface to IMEM, DMEM, and APB Bus

`include "soc_defines.vh"

module picorv32_apb_bridge (
    input clk,
    input rst_n,

    // PicoRV32 Native Memory Interface
    input  mem_valid,
    input  mem_instr,
    output mem_ready,
    input  [31:0] mem_addr,
    input  [31:0] mem_wdata,
    input  [ 3:0] mem_wstrb,
    output [31:0] mem_rdata,

    // APB Master Interface
    output reg        apb_psel,
    output reg        apb_penable,
    output reg [31:0] apb_paddr,
    output reg        apb_pwrite,
    output reg [31:0] apb_pwdata,
    input             apb_pready,
    input      [31:0] apb_prdata,
    input             apb_pslverr,

    // Instruction Memory Interface (Read-Only)
    output [11:0] imem_addr,
    input  [31:0] imem_rdata,

    // Data Memory Interface
    output [11:0] dmem_addr,
    output [31:0] dmem_wdata,
    output [ 3:0] dmem_we,
    input  [31:0] dmem_rdata
);

    // Address Decoding
    wire is_imem   = (mem_addr >= `IMEM_BASE)  && (mem_addr < `IMEM_BASE + `IMEM_SIZE);
    wire is_dmem   = (mem_addr >= `DMEM_BASE)  && (mem_addr < `DMEM_BASE + `DMEM_SIZE);
    wire is_periph = (mem_addr >= `PERIPH_BASE) && (mem_addr < 32'h5000_0000);

    // Memory Mapping - Word Addresses
    assign imem_addr = mem_addr[13:2];
    assign dmem_addr = mem_addr[13:2];
    assign dmem_wdata = mem_wdata;
    assign dmem_we    = (is_dmem && mem_valid) ? mem_wstrb : 4'b0000;

    // APB State Machine
    parameter APB_IDLE   = 2'b00;
    parameter APB_SETUP  = 2'b01;
    parameter APB_ACCESS = 2'b10;
    reg [1:0] apb_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            apb_state   <= APB_IDLE;
            apb_psel    <= 1'b0;
            apb_penable <= 1'b0;
            apb_paddr   <= 32'h0;
            apb_pwrite  <= 1'b0;
            apb_pwdata  <= 32'h0;
        end else begin
            case (apb_state)
                APB_IDLE: begin
                    if (is_periph && mem_valid) begin
                        apb_state   <= APB_SETUP;
                        apb_psel    <= 1'b1;
                        apb_paddr   <= mem_addr;
                        apb_pwrite  <= (|mem_wstrb);
                        apb_pwdata  <= mem_wdata;
                    end
                end
                APB_SETUP: begin
                    apb_state   <= APB_ACCESS;
                    apb_penable <= 1'b1;
                end
                APB_ACCESS: begin
                    if (apb_pready) begin
                        apb_state   <= APB_IDLE;
                        apb_psel    <= 1'b0;
                        apb_penable <= 1'b0;
                    end
                end
                default: apb_state <= APB_IDLE;
            endcase
        end
    end

    // Memory Ready Logic
    // Local memory (IMEM/DMEM) is ready in 1 cycle
    // APB is ready when pready is high during access phase
    reg mem_ready_local;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) mem_ready_local <= 1'b0;
        else mem_ready_local <= mem_valid && (is_imem || is_dmem) && !mem_ready_local;
    end

    assign mem_ready = mem_ready_local || (apb_state == APB_ACCESS && apb_pready);

    // Read Data Multiplexer
    assign mem_rdata = (is_imem)   ? imem_rdata :
                       (is_dmem)   ? dmem_rdata :
                       (is_periph) ? apb_prdata :
                                     32'h0;

endmodule
