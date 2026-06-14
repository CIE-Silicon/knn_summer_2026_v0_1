`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2025 01:13:49 AM
// Design Name: 
// Module Name: TB
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


module uart_rx_tb(

    );
    
    
    reg clk=0;
    reg reset_0=1;
    always #5 clk=~clk;
    wire uart_tx, uart_rx;
    wire fio0,fio1,fio2,fio3, CS, SCK, trap;
    wire [3:0] gpio_io_o_0;
    wire [7:0]recv_data;
    wire data_valid_rcv;
    wire [2:0] tx_state;
    wire [4:0] tx_count;
    reg [7:0] tx_data = 8'hA5;
    reg tx_push = 1'b0;
    specparam        tdevice_PU                = 3e8;//tPU
    
   design_1_wrapper dut(.usb_uart_rxd(uart_rx),
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
//    .led_4bits_tri(led));
    
   uart_transmitter tx_stim (
       .clk(clk),
       .resetn(reset_0),
       .tx_data(tx_data),
       .tx_push(tx_push),
       .stx_pad_o(uart_rx),
       .tstate(tx_state),
       .tf_count(tx_count)
    );

   s25fl128s flash_memory( 
        // Data Inputs/Outputs
        .SI(fio0)     ,
        .SO(fio1)     ,
        // Controls
        .SCK(SCK)    ,
        .CSNeg(CS)  ,
        .RSTNeg(reset_0) ,
        .WPNeg(fio2)  ,
        .HOLDNeg(fio3)
);


 uart_rx rcv(
            .clk(clk),          // 100 MHz clock
            .resetn(reset_0),       // active-low reset
            .rx(uart_tx),           // UART serial input
            .data_out(recv_data), // received byte
        .data_valid(data_valid_rcv)    // high when a full byte is received
);
  
   initial begin
   reset_0=0;
   #tdevice_PU
   #10
   reset_0=1;
   end
    
   integer i;
   initial begin
    tx_push = 1'b0;
    tx_data = 8'hA5;
    wait (reset_0 === 1'b1);
    // send 10 bytes back-to-back (one-clock push per byte)
    for (i = 0; i < 10; i = i + 1) begin
        tx_data = 8'hA5 + i; // incremental payload
        @(posedge clk);
        // tx push pulse sends the byte
        tx_push = 1'b1;
        @(posedge clk);
        tx_push = 1'b0;
        // one clock gap between pushes; the transmitter FIFO depth handles buffering
    end
   end
   
   always @(posedge clk) begin
    if (data_valid_rcv) begin
        /*if (recv_data < 8'd32 || recv_data >= 127)
            $display("UART RX: %d ", recv_data);
        else
            $display("UART RX: %c", recv_data);*/
                $display("UART RX: %x", recv_data);
            
    end
end

   
    
endmodule
