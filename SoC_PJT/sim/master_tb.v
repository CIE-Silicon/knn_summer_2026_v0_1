`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/14/2025 01:13:49 AM
// Design Name:
// Module Name: master_tb
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module master_tb;

    reg clk = 0;
    reg reset_0 = 1;

    always #5 clk = ~clk;

    wire uart_tx;
    wire uart_rx;
    wire fio0;
    wire fio1;
    wire fio2;
    wire fio3;
    wire CS;
    wire SCK;
    wire trap;
    wire [3:0] gpio_io_o_0;
    wire [7:0] recv_data;
    wire data_valid_rcv;

    specparam tdevice_PU = 100000; // tPU

    design_1_wrapper dut (
            .usb_uart_rxd(uart_rx),
            .usb_uart_txd(uart_tx),
            .clk_in1_0(clk),
            .resetn_0(reset_0),
            .qspi_flash_io0_io(fio0),
            .qspi_flash_io1_io(fio1),
            .qspi_flash_io2_io(fio2),
            .qspi_flash_io3_io(fio3),
            .qspi_flash_sck_io(SCK),
            .qspi_flash_ss_io(CS),
            .trap_0(trap),
            .led_4bits_tri_io(gpio_io_o_0)
    );

    s25fl128s flash_memory (
            .SI(fio0),
            .SO(fio1),
            .SCK(SCK),
            .CSNeg(CS),
            .RSTNeg(reset_0),
            .WPNeg(fio2),
            .HOLDNeg(fio3)
    );

    uart_rx rcv (
            .clk(clk),
            .resetn(reset_0),
            .rx(uart_tx),
            .data_out(recv_data),
            .data_valid(data_valid_rcv)
    );

    initial begin
        reset_0 = 0;
        #tdevice_PU
        #10
        reset_0 = 1;
    end

    always @(posedge clk) begin
        if (data_valid_rcv) begin
            /* if (recv_data < 8'd32 || recv_data >= 127)
                     $display("UART RX: %d ", recv_data);
                 else
                     $display("UART RX: %c", recv_data); */
            $display("UART RX: %x", recv_data);
        end
    end

endmodule
