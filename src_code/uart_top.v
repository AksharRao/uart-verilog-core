module uart_top #(
    parameter DBIT_WIDTH = 8,
    parameter SB_TICK = 16,
    parameter FIFO_DEPTH_BITS = 2
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        rd_uart,
    input  wire        wr_uart,
    input  wire [7:0]  w_data,
    output wire [7:0]  r_data,
    output wire        tx_full,
    output wire        rx_empty,
    input  wire [10:0] dvsr,
    output wire        tx,
    input  wire        rx
);

    wire        tick;
    wire        rx_done_tick;
    wire        tx_done_tick;
    wire        tx_fifo_not_empty;
    wire [7:0]  tx_fifo_out;
    wire [7:0]  rx_data_out;
    wire        tx_empty;

    // Baud rate generator instance
    baud_gen baud_gen_unit (
        .clk(clk),
        .rst(rst),
        .dvsr(dvsr),
        .tick(tick)
    );

    // UART receiver and transmitter instances
    uart_rx #(
        .DBIT_WIDTH(DBIT_WIDTH),
        .SB_TICK(SB_TICK)
    ) uart_rx_unit (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .s_tick(tick),
        .rx_done_tick(rx_done_tick),
        .data_out(rx_data_out)
    );

    // UART transmitter instance
    uart_tx #(
        .DBIT_WIDTH(DBIT_WIDTH),
        .SB_TICK(SB_TICK)
    ) uart_tx_unit (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_fifo_not_empty),
        .s_tick(tick),
        .data_in(tx_fifo_out),
        .tx_done_tick(tx_done_tick),
        .tx(tx)
    );

    // FIFO instance for transmit buffer
    fifo #(
        .DEPTH(2**FIFO_DEPTH_BITS),
        .WIDTH(DBIT_WIDTH)
    ) fifo_tx (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_uart),
        .rd_en(tx_done_tick),
        .buf_in(w_data),
        .buf_out(tx_fifo_out),
        .buf_full(tx_full),
        .buf_empty(tx_empty),
        .fifo_count()
    );

    // FIFO instance for receive buffer
    fifo #(
        .DEPTH(2**FIFO_DEPTH_BITS), 
        .WIDTH(DBIT_WIDTH)
    ) fifo_rx (
        .clk(clk),
        .rst(rst),
        .wr_en(rx_done_tick),
        .rd_en(rd_uart),
        .buf_in(rx_data_out),
        .buf_out(r_data),
        .buf_full(),
        .buf_empty(rx_empty),
        .fifo_count()
    );

    assign tx_fifo_not_empty = ~tx_empty;

endmodule