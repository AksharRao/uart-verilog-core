`timescale 1ns/1ps

module tb_uart_top();
    // Testbench parameters
    parameter CLK_PERIOD = 20;  // 50 MHz clock
    parameter BAUD_DIVISOR = 5208; // 9600 baud @ 50MHz
    
    // DUT signals
    reg clk;
    reg rst;
    reg rd_uart;
    reg wr_uart;
    reg [7:0] w_data;
    wire [7:0] r_data;
    wire tx_full;
    wire rx_empty;
    reg [15:0] dvsr;
    wire tx;
    reg rx;
    
    // Test variables
    reg [7:0] test_data [0:3];
    integer i;
    
    // Instantiate DUT
    uart_top #(
        .DBIT_WIDTH(8),
        .SB_TICK(16),
        .FIFO_DEPTH_BITS(2)  // 4-entry FIFO
    ) dut (
        .clk(clk),
        .rst(rst),
        .rd_uart(rd_uart),
        .wr_uart(wr_uart),
        .w_data(w_data),
        .r_data(r_data),
        .tx_full(tx_full),
        .rx_empty(rx_empty),
        .dvsr(dvsr),
        .tx(tx),
        .rx(rx)
    );
    
    // Clock generation
    always begin
        clk = 1'b1;
        #(CLK_PERIOD/2);
        clk = 1'b0;
        #(CLK_PERIOD/2);
    end
    
    // Initialize test data
    initial begin
        test_data[0] = 8'hA5;
        test_data[1] = 8'h3C;
        test_data[2] = 8'h99;
        test_data[3] = 8'h7E;
    end
    
    // Main test sequence
    initial begin
        // Initialize
        rst = 1'b1;
        wr_uart = 1'b0;
        rd_uart = 1'b0;
        w_data = 8'h00;
        dvsr = BAUD_DIVISOR;
        rx = 1'b1;  // Idle state
        
        // Reset sequence
        #100;
        rst = 1'b0;
        #100;
        
        // Test 1: Basic TX/RX loopback
        $display("Test 1: Basic loopback test");
        for (i = 0; i < 4; i = i + 1) begin
            // Write to TX FIFO
            wait(tx_full == 0);
            w_data = test_data[i];
            wr_uart = 1'b1;
            @(posedge clk);
            wr_uart = 1'b0;
            
            // Delay for transmission
            #10000;
            
            // Simulate RX by looping back TX
            rx = tx;
            
            // Wait for RX data
            wait(rx_empty == 0);
            rd_uart = 1'b1;
            @(posedge clk);
            rd_uart = 1'b0;
            
            // Verify data
            if (r_data !== test_data[i]) begin
                $display("ERROR: Expected 0x%h, Received 0x%h", test_data[i], r_data);
            end else begin
                $display("PASS: Data 0x%h correctly received", r_data);
            end
            
            #1000;
        end
        
        // Test 2: FIFO full condition
        $display("\nTest 2: FIFO full condition");
        i = 0;
        while (tx_full == 0) begin
            w_data = test_data[i % 4];
            wr_uart = 1'b1;
            @(posedge clk);
            wr_uart = 1'b0;
            i = i + 1;
            #100;
        end
        $display("FIFO full condition reached after %0d writes", i);
        
        // End simulation
        #10000;
        $display("\nAll tests completed");
        $finish;
    end
    
    // VCD dump for waveform viewing
    initial begin
        $dumpfile("uart_top.vcd");
        $dumpvars(0, tb_uart_top);
    end
endmodule