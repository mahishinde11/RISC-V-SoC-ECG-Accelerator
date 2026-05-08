`include "soc_defines.vh"

module ecg_accelerator_apb (

    input  wire clk,
    input  wire rst_n,

    // APB interface
    input  wire        apb_psel,
    input  wire        apb_penable,
    input  wire        apb_pwrite,
    input  wire [31:0] apb_paddr,
    input  wire [31:0] apb_pwdata,
    output reg  [31:0] apb_prdata,
    output wire        apb_pready,
    output wire        apb_pslverr,

    // UART input from STM32
    input  wire        stm32_rx
);

assign apb_pready  = 1'b1;
assign apb_pslverr = 1'b0;

integer i;
integer j;

////////////////////////////////////////////////////////////
//// STM32 UART ADC Interface
////////////////////////////////////////////////////////////

wire [11:0] raw_sample;
wire        sample_valid;

stm32_adc_interface stm32_inst (
    .clk(clk),
    .rst_n(rst_n),
    .uart_rx(stm32_rx),
    .sample_out(raw_sample),
    .valid_out(sample_valid)
);

////////////////////////////////////////////////////////////
//// Decimation (not needed, keep same rate)
////////////////////////////////////////////////////////////

wire decimated_valid = sample_valid;

////////////////////////////////////////////////////////////
//// Digital Low-Pass Smoothing Filter (Noise Suppression)
////////////////////////////////////////////////////////////

reg [11:0] fbuf [0:7];
wire [14:0] fsum = fbuf[0] + fbuf[1] + fbuf[2] + fbuf[3] + 
                   fbuf[4] + fbuf[5] + fbuf[6] + fbuf[7];
wire [11:0] clean_sample = fsum >> 3;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(j=0; j<8; j=j+1) fbuf[j] <= 0;
    end else if(decimated_valid) begin
        fbuf[7] <= fbuf[6]; fbuf[6] <= fbuf[5]; fbuf[5] <= fbuf[4]; fbuf[4] <= fbuf[3];
        fbuf[3] <= fbuf[2]; fbuf[2] <= fbuf[1]; fbuf[1] <= fbuf[0]; fbuf[0] <= raw_sample;
    end
end

////////////////////////////////////////////////////////////
//// Derivative stage
////////////////////////////////////////////////////////////

reg [11:0] d_buf [0:3];
reg signed [15:0] derivative;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        derivative <= 0;
        for(i=0;i<4;i=i+1)
            d_buf[i] <= 0;
    end
    else if(decimated_valid)
    begin
        // shift first
        d_buf[3] <= d_buf[2];
        d_buf[2] <= d_buf[1];
        d_buf[1] <= d_buf[0];
        d_buf[0] <= clean_sample; // Feed clean sample to derivative

        derivative <=
        (
            ($signed({1'b0,clean_sample}) <<< 1) +
            ($signed({1'b0,d_buf[0]})) -
            ($signed({1'b0,d_buf[2]})) -
            ($signed({1'b0,d_buf[3]}) <<< 1)
        ) >>> 3;
    end
end

////////////////////////////////////////////////////////////
//// Squaring stage
////////////////////////////////////////////////////////////

reg [31:0] squared;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        squared <= 0;
    else if(decimated_valid)
        squared <= $unsigned(derivative * derivative);
end

////////////////////////////////////////////////////////////
//// Moving Average Filter
////////////////////////////////////////////////////////////

parameter MAF_WINDOW = 32;

reg [31:0] maf_buf [0:MAF_WINDOW-1];
reg [36:0] maf_sum;
reg [31:0] maf_out;
reg [36:0] maf_next;

always @(*) begin
    maf_next = maf_sum - maf_buf[MAF_WINDOW-1] + squared;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        maf_sum <= 0;
        maf_out <= 0;
        for(i=0;i<MAF_WINDOW;i=i+1)
            maf_buf[i] <= 0;
    end
    else if(decimated_valid)
    begin
        maf_sum <= maf_next;
        maf_out <= maf_next >> 5;

        maf_buf[0] <= squared;
        for(i=1;i<MAF_WINDOW;i=i+1)
            maf_buf[i] <= maf_buf[i-1];
    end
end

////////////////////////////////////////////////////////////
//// Peak Detection + BPM
////////////////////////////////////////////////////////////

reg [31:0] threshold;
reg [31:0] bpm;
reg [31:0] beat_count;

reg [47:0] timer_ticks;
reg [47:0] last_beat_ticks;

reg last_state;
reg decimated_valid_q;
reg [1:0] rx_diag_sync;

localparam [32:0] BPM_DIVIDEND = 33'd6000000000;

reg div_busy;
reg [5:0] div_step;
reg [33:0] div_remainder;
reg [32:0] div_divisor;
reg [32:0] div_quotient;
reg [32:0] div_dividend_sr;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        threshold <= 32'd200000;
        bpm <= 0;
        beat_count <= 0;
        timer_ticks <= 0;
        last_beat_ticks <= 0;
        last_state <= 0;
        decimated_valid_q <= 0;
        rx_diag_sync <= 2'b11;

        div_busy <= 0;
        div_step <= 0;
        div_remainder <= 0;
        div_divisor <= 0;
        div_quotient <= 0;
        div_dividend_sr <= 0;
    end
    else
    begin

        if(apb_psel && apb_penable && apb_pwrite &&
           apb_paddr[7:0]==`ECG_THRESHOLD)
            threshold <= apb_pwdata;

        timer_ticks <= timer_ticks + 1;
        decimated_valid_q <= decimated_valid;
        rx_diag_sync <= {rx_diag_sync[0], stm32_rx};

        /////////////////////////////////////////////////////
        // Divider FSM
        /////////////////////////////////////////////////////

        if(div_busy)
        begin
            if(div_step==0)
            begin
                bpm <= div_quotient[31:0];
                div_busy <= 0;
            end
            else
            begin
                div_step <= div_step - 1;

                if({div_remainder[32:0],div_dividend_sr[32]} >= {1'b0,div_divisor})
                begin
                    div_remainder <= {div_remainder[32:0],div_dividend_sr[32]} - {1'b0,div_divisor};
                    div_quotient  <= {div_quotient[31:0],1'b1};
                end
                else
                begin
                    div_remainder <= {div_remainder[32:0],div_dividend_sr[32]};
                    div_quotient  <= {div_quotient[31:0],1'b0};
                end

                div_dividend_sr <= {div_dividend_sr[31:0],1'b0};
            end
        end

        /////////////////////////////////////////////////////
        // Peak detection
        /////////////////////////////////////////////////////

        if(decimated_valid_q)
        begin
            if(maf_out > threshold && !last_state)
            begin
                beat_count <= beat_count + 1;
                last_state <= 1;

                if(last_beat_ticks!=0)
                begin
                    if(((timer_ticks[32:0]-last_beat_ticks[32:0])!=0) && !div_busy)
                    begin
                        div_busy <= 1;
                        div_step <= 6'd33;
                        div_remainder <= 0;
                        div_quotient <= 0;
                        div_dividend_sr <= BPM_DIVIDEND;
                        div_divisor <= timer_ticks[32:0]-last_beat_ticks[32:0];
                    end
                end

                last_beat_ticks <= timer_ticks;
            end
            else if(maf_out < (threshold>>1))
                last_state <= 0;
        end
    end
end

////////////////////////////////////////////////////////////
//// Data Ready Logic
////////////////////////////////////////////////////////////

reg raw_data_ready;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        raw_data_ready <= 0;
    else
    begin
        if(sample_valid)
            raw_data_ready <= 1;
        else if(apb_psel && apb_penable && !apb_pwrite &&
                apb_paddr[7:0]==`ECG_DATA_RAW)
            raw_data_ready <= 0;
    end
end

////////////////////////////////////////////////////////////
//// APB Read MUX
////////////////////////////////////////////////////////////

always @(*)
begin
    apb_prdata = 0;

    if(apb_psel && apb_penable && !apb_pwrite)
    begin
        case(apb_paddr[7:0])

            `ECG_DATA_RAW:
                apb_prdata = {rx_diag_sync[1], 15'h0, raw_data_ready, 3'h0, clean_sample}; // Output clean wave to UI

            `ECG_DATA_FILT:
                apb_prdata = maf_out;

            `ECG_BPM:
                apb_prdata = bpm;

            `ECG_THRESHOLD:
                apb_prdata = threshold;

            default:
                apb_prdata = 0;
        endcase
    end
end

endmodule