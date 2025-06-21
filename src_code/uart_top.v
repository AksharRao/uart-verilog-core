module uart_top #(
    parameter CLK_FREQ = 50_000_000,   // System clock frequency in Hz (50 MHz)
    parameter BAUD_RATE = 9600,        // Desired baud rate
    parameter DBIT_WIDTH = 8,          // Data bit width
    parameter SB_TICK = 16             // Stop bit tick count
)(
    input wire clk,                    // System clock
    input wire rst,                    // Active-high reset
    // UART Interface
    input wire rx,                     // UART receive line
    output wire tx,                    // UART transmit line
    // User Interface
    input wire tx_start,               // Signal to start transmission
    input wire [DBIT_WIDTH-1:0] tx_data, // Data to transmit
    output wire tx_done,               // Transmission complete flag
    output wire rx_done,               // Reception complete flag
    output wire [DBIT_WIDTH-1:0] rx_data // Received data
);

    // Calculate divisor for baud rate generator
    localparam DVSR = CLK_FREQ / BAUD_RATE;
    
    // Internal signals
    wire s_tick;                       // Baud rate tick
    
    // Instantiate baud rate generator
    baud_gen #(
        .DVSR_WIDTH(16)
    ) baud_gen_inst (
        .clk(clk),
        .rst(rst),
        .dvsr(DVSR[15:0]),             // Using lower 16 bits of divisor
        .tick(s_tick)
    );
    
    // Instantiate UART receiver
    uart_rx #(
        .DBIT_WIDTH(DBIT_WIDTH),
        .SB_TICK(SB_TICK)
    ) uart_rx_inst (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .s_tick(s_tick),
        .rx_done_tick(rx_done),
        .data_out(rx_data)
    );
    
    // Instantiate UART transmitter
    uart_tx #(
        .DBIT_WIDTH(DBIT_WIDTH),
        .SB_TICK(SB_TICK)
    ) uart_tx_inst (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .s_tick(s_tick),
        .data_in(tx_data),
        .tx_done_tick(tx_done),
        .tx(tx)
    );

endmodule