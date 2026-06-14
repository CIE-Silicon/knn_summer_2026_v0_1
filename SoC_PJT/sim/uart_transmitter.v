`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Rohith
//
// Create Date: 10/14/2025 01:13:49 AM
// Design Name:
// Module Name: uart_transmitter
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Simple UART transmitter with a small FIFO buffer.
//
//////////////////////////////////////////////////////////////////////////////////

module uart_transmitter(
    input  wire        clk,
    input  wire        resetn,
    input  wire [7:0]  tx_data,
    input  wire        tx_push,
    output reg         stx_pad_o,
    output reg [2:0]   tstate,
    output reg [4:0]   tf_count
);

parameter CLKS_PER_BIT = 868;
localparam FIFO_DEPTH = 16;
localparam [2:0] IDLE = 3'd0, START_BIT = 3'd1, DATA_BITS = 3'd2, STOP_BIT = 3'd3;

reg [7:0] fifo [0:FIFO_DEPTH-1];
reg [3:0] rd_ptr;
reg [3:0] wr_ptr;
reg [4:0] count;
reg [13:0] clk_count;
reg [2:0] bit_index;
reg [7:0] tx_shift;
reg [4:0] count_next;
reg [3:0] rd_next;
reg [3:0] wr_next;
reg [2:0] state_next;
reg [13:0] clk_next;
reg [2:0] bit_next;
reg [7:0] shift_next;
reg tx_next;

integer i;

initial begin
    stx_pad_o = 1'b1;
    tstate = IDLE;
    tf_count = 5'd0;
    rd_ptr = 4'd0;
    wr_ptr = 4'd0;
    count = 5'd0;
    clk_count = 14'd0;
    bit_index = 3'd0;
    tx_shift = 8'd0;
    for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
        fifo[i] = 8'd0;
    end
end

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        stx_pad_o <= 1'b1;
        tstate <= IDLE;
        tf_count <= 5'd0;
        rd_ptr <= 4'd0;
        wr_ptr <= 4'd0;
        count <= 5'd0;
        clk_count <= 14'd0;
        bit_index <= 3'd0;
        tx_shift <= 8'd0;
    end else begin
        count_next = count;
        rd_next = rd_ptr;
        wr_next = wr_ptr;
        state_next = tstate;
        clk_next = clk_count;
        bit_next = bit_index;
        shift_next = tx_shift;
        tx_next = stx_pad_o;

        if (tx_push && count_next < FIFO_DEPTH) begin
            fifo[wr_next] = tx_data;
            wr_next = wr_next + 1'b1;
            count_next = count_next + 1'b1;
        end

        case (tstate)
            IDLE: begin
                tx_next = 1'b1;
                clk_next = 14'd0;
                bit_next = 3'd0;
                if (count_next > 0) begin
                    shift_next = fifo[rd_next];
                    rd_next = rd_next + 1'b1;
                    count_next = count_next - 1'b1;
                    state_next = START_BIT;
                    tx_next = 1'b0;
                end
            end

            START_BIT: begin
                tx_next = 1'b0;
                if (clk_next < CLKS_PER_BIT - 1) begin
                    clk_next = clk_next + 1'b1;
                end else begin
                    clk_next = 14'd0;
                    bit_next = 3'd0;
                    state_next = DATA_BITS;
                end
            end

            DATA_BITS: begin
                tx_next = shift_next[0];
                if (clk_next < CLKS_PER_BIT - 1) begin
                    clk_next = clk_next + 1'b1;
                end else begin
                    clk_next = 14'd0;
                    shift_next = {1'b0, shift_next[7:1]};
                    if (bit_next == 3'd7) begin
                        state_next = STOP_BIT;
                    end else begin
                        bit_next = bit_next + 1'b1;
                    end
                end
            end

            STOP_BIT: begin
                tx_next = 1'b1;
                if (clk_next < CLKS_PER_BIT - 1) begin
                    clk_next = clk_next + 1'b1;
                end else begin
                    clk_next = 14'd0;
                    state_next = IDLE;
                end
            end
        endcase

        stx_pad_o <= tx_next;
        tstate <= state_next;
        tf_count <= count_next;
        rd_ptr <= rd_next;
        wr_ptr <= wr_next;
        count <= count_next;
        clk_count <= clk_next;
        bit_index <= bit_next;
        tx_shift <= shift_next;
    end
end

endmodule
