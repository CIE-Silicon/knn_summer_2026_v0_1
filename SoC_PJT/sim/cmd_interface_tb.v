`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Module Name: TB
// Description: Combined SoC testbench.
//   - Host command flow from TB #1 (invalid cmd, default dataset, range batch)
//   - RTS/CTS flow-control monitoring and stall tests from TB #2
//////////////////////////////////////////////////////////////////////////////////

module cmd_interface_tb();

    // =====================================================================
    // Clock and Reset
    // =====================================================================
    reg clk = 0;
    reg reset_0 = 1;
    always #5 clk = ~clk; // 100 MHz

    // =====================================================================
    // System Signals
    // =====================================================================
    wire fio0, fio1, fio2, fio3, CS, SCK, trap;
    wire [3:0] gpio_io_o_0;

    // =====================================================================
    // UART Signals
    // =====================================================================
    reg  uart_rx_to_dut = 1'b1;
    wire uart_tx_from_dut;

    wire [7:0] recv_data;
    wire data_valid_rcv;

    // =====================================================================
    // UART16550 Modem/Flow-Control
    // =====================================================================
    reg  uart_ctsn = 1'b0;   // active-low: 0 = TB tells DUT it can transmit
    wire uart_rtsn;           // active-low: 0 = DUT ready to receive

    reg  uart_dcdn = 1'b1;
    reg  uart_dsrn = 1'b1;
    reg  uart_ri   = 1'b1;

    wire uart_dtrn, uart_out1n, uart_out2n;
    wire uart_baudoutn, uart_ddis, uart_rxrdyn, uart_txrdyn;

    // =====================================================================
    // Baud rate timing
    // =====================================================================
    localparam TB_CLKS_PER_BIT = 864; // 115200 baud at 100MHz

    specparam tdevice_PU = 100000;

    // =====================================================================
    // Shared flags
    // =====================================================================
    reg firmware_ready       = 0; // set on 0xFF (bootrom / firmware idle)
    reg first_label_received = 0; // set on first byte after bootrom done

    // =====================================================================
    // DUT
    // =====================================================================
    design_1_wrapper dut(
        .clk_in1_0(clk),
        .resetn_0(reset_0),
        .qspi_flash_io0_io(fio0),
        .qspi_flash_io1_io(fio1),
        .qspi_flash_io2_io(fio2),
        .qspi_flash_io3_io(fio3),
        .qspi_flash_sck_io(SCK),
        .qspi_flash_ss_io(CS),
        .trap_0(trap),
        .led_4bits_tri_io(gpio_io_o_0),
        .usb_uart_rxd(uart_rx_to_dut),
        .usb_uart_txd(uart_tx_from_dut),
        .usb_uart_ctsn(uart_ctsn),
        .usb_uart_rtsn(uart_rtsn),
        .usb_uart_dcdn(uart_dcdn),
        .usb_uart_dsrn(uart_dsrn),
        .usb_uart_dtrn(uart_dtrn),
        .usb_uart_ri(uart_ri),
        .usb_uart_ddis(uart_ddis),
        .usb_uart_out1n(uart_out1n),
        .usb_uart_out2n(uart_out2n),
        .usb_uart_baudoutn(uart_baudoutn),
        .usb_uart_rxrdyn(uart_rxrdyn),
        .usb_uart_txrdyn(uart_txrdyn)
    );

    // =====================================================================
    // SPI Flash
    // =====================================================================
    s25fl128s flash_memory(
        .SI(fio0),
        .SO(fio1),
        .SCK(SCK),
        .CSNeg(CS),
        .RSTNeg(reset_0),
        .WPNeg(fio2),
        .HOLDNeg(fio3)
    );

    // =====================================================================
    // UART RX Monitor (SoC -> Host)
    // =====================================================================
    uart_rx rcv(
        .clk(clk),
        .resetn(reset_0),
        .rx(uart_tx_from_dut),
        .data_out(recv_data),
        .data_valid(data_valid_rcv)
    );

    // =====================================================================
    // Reset Sequence
    // =====================================================================
    initial begin
        reset_0 = 0;
        #tdevice_PU;
        #10;
        reset_0 = 1;
    end

    // =====================================================================
    // Track firmware_ready / first_label_received from RX stream
    // =====================================================================
    always @(posedge clk) begin
        if (data_valid_rcv) begin
            $display("[%0t] UART RX: %02x", $time, recv_data);

            if (recv_data == 8'hFF) begin
                firmware_ready <= 1'b1;
                $display("[%0t] TB: firmware ready (0xFF received)", $time);
            end

            if (!first_label_received) begin
                first_label_received <= 1'b1;
            end
        end
    end

    // =====================================================================
    // UART TX Task (Host -> DUT) - checks RTS before each byte
    // =====================================================================
    task uart_send_byte;
        input [7:0] data;
        integer i;
        begin
            if (uart_rtsn !== 1'b0) begin
                $display("[%0t] TB: RTS deasserted, pausing before 0x%02x...",
                         $time, data);
                wait (uart_rtsn == 1'b0);
                $display("[%0t] TB: RTS reasserted, resuming", $time);
            end

            $display("[%0t] TB sending byte: 0x%02x", $time, data);

            uart_rx_to_dut = 1'b0;
            repeat(TB_CLKS_PER_BIT) @(posedge clk);

            for (i = 0; i < 8; i = i + 1) begin
                uart_rx_to_dut = data[i];
                repeat(TB_CLKS_PER_BIT) @(posedge clk);
            end

            uart_rx_to_dut = 1'b1;
            repeat(TB_CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    // =====================================================================
    // Host command sequence (from TB #1), using RTS-aware uart_send_byte
    // =====================================================================
    initial begin
        $display("[%0t] TB COMBINED VERSION", $time);
        uart_rx_to_dut = 1'b1;

        wait(reset_0 == 1);
        wait(firmware_ready == 1);
        #100000;

        //----------------------------------------------------
        // Invalid command
        //----------------------------------------------------
        $display("[%0t] HOST -> Sending Invalid Command 0x20", $time);
        uart_send_byte(8'h20);

        wait(firmware_ready == 1);
        #100000;

        //----------------------------------------------------
        // Default Dataset
        //----------------------------------------------------
        firmware_ready = 0;
        $display("[%0t] HOST -> Sending Default Dataset", $time);
        uart_send_byte(8'h10);

        wait(firmware_ready == 1);
        #100000;

        //----------------------------------------------------
        // Range Mode : Batch2 -> Batch4
        //----------------------------------------------------
        firmware_ready = 0;
        $display("[%0t] HOST -> Sending Range Batch 2 -> Batch 4", $time);
        uart_send_byte(8'hAD);
        uart_send_byte(8'h02);
        uart_send_byte(8'h04);

        wait(firmware_ready == 1);
        #100000;

        $display("---------------------------------------");
        $display("Simulation Complete");
        $display("---------------------------------------");

        #100000;
        $finish;
    end

    // =====================================================================
    // Test: Deassert CTS when first post-bootrom byte is being transmitted
    // (from TB #2) - verifies DUT TX stalls correctly under CTS backpressure
    // =====================================================================
    initial begin
        uart_ctsn = 1'b0; // start asserted

        @(posedge reset_0);

        // Wait for bootrom 0xff
        begin : wait_bootrom_t2
            forever begin
                @(posedge data_valid_rcv);
                if (recv_data == 8'hff) disable wait_bootrom_t2;
            end
        end

        // Wait for first byte after bootrom done
        @(posedge data_valid_rcv);
        $display("[%0t] TB: First post-bootrom byte received: 0x%02x", $time, recv_data);

        $display("[%0t] TB: ===== CTS STALL TEST =====", $time);
        $display("[%0t] TB: deasserting CTS", $time);
        uart_ctsn = 1'b1;

        // Hold deasserted for ~5 byte periods
        repeat(TB_CLKS_PER_BIT * 500) @(posedge clk);

        $display("[%0t] TB: reasserting CTS", $time);
        uart_ctsn = 1'b0;

        repeat(TB_CLKS_PER_BIT * 50) @(posedge clk);
        $display("[%0t] TB: ===== CTS STALL TEST COMPLETE =====", $time);
    end

    // =====================================================================
    // RTS Monitor
    // =====================================================================
    always @(uart_rtsn) begin
        $display("[%0t] UART RTS_n -> %b (%s)", $time, uart_rtsn,
                 uart_rtsn ? "NOT ready to receive"
                           : "ready to receive");
    end

    // =====================================================================
    // CTS Monitor
    // =====================================================================
    always @(uart_ctsn) begin
        $display("[%0t] UART CTS_n -> %b (%s)", $time, uart_ctsn,
                 uart_ctsn ? "host NOT ready - DUT TX should stall"
                           : "host ready - DUT TX can resume");
    end

endmodule