// UART Receiver Module (LSB-first)

module uart_rx #(
    parameter DBIT_WIDTH = 8,    // Data bit width
    parameter SB_TICK = 16       // Stop bit tick count (for 1 stop bit)
)(
    input  wire        clk,      // System clock
    input  wire        rst,      // Reset signal (active high)
    input  wire        rx,       // Serial data input
    input  wire        s_tick,   // Sample tick from baud generator
    output reg         rx_done_tick, // Byte received pulse
    output reg [DBIT_WIDTH-1:0]   data_out      // Received byte
);

    // State encoding
    localparam [1:0] IDLE  = 2'b00,
                     START = 2'b01,
                     DATA  = 2'b10,
                     STOP  = 2'b11;

    reg [1:0] current_state, next_state;
    reg [3:0] s_reg, s_next;             // Sample counter
    reg [$clog2(DBIT_WIDTH):0] bit_count, bit_count_next; // Bit counter (for 8 bits)
    reg [DBIT_WIDTH-1:0] data_reg, data_next;       // Data register

    // Sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) 
        begin
            current_state <= IDLE;
            s_reg        <= 0;
            bit_count    <= 0;
            data_reg     <= 0;
            rx_done_tick <= 1'b0;
            data_out     <= 0;
        end 
        else 
        begin
            current_state <= next_state;
            s_reg        <= s_next;
            bit_count    <= bit_count_next;
            data_reg     <= data_next;
            rx_done_tick <= 1'b0; // Default, pulse for one clock

            // Pulse rx_done_tick and update data_out at end of STOP state
            if (current_state == STOP && s_tick && s_reg == SB_TICK - 1) 
            begin
                rx_done_tick <= 1'b1;
                data_out     <= data_reg;
            end
        end
    end

    always @(*) begin
        // Default assignments
        next_state = current_state;
        s_next = s_reg;
        bit_count_next = bit_count;
        data_next = data_reg;

        case (current_state)
            IDLE: begin
                if (!rx) begin // Start bit detected (active low)
                    next_state = START;
                    s_next = 0;
                end
            end

            START: begin
                if (s_tick) begin
                    if (s_reg == (SB_TICK/2 - 1 )) begin // Middle of start bit
                        next_state = DATA;
                        s_next = 0;
                        bit_count_next = 0;
                    end 
                    else begin
                        s_next = s_reg + 1;
                    end
                end
            end

            DATA: begin
                if (s_tick) begin
                    if (s_reg == SB_TICK- 1) 
                    begin // Middle of data bit
                        s_next = 0;
                        data_next = {rx, data_reg [DBIT_WIDTH-1:1]}; //discarding 8th bit, and appending new rx bit in lsb
                        if (bit_count == DBIT_WIDTH - 1) 
                        begin
                            next_state = STOP;
                        end 
                        else begin
                            bit_count_next = bit_count + 1;
                        end
                    end 
                    else begin
                        s_next = s_reg + 1;
                    end
                end
            end

            STOP: begin
                if (s_tick) begin
                    if (s_reg == SB_TICK - 1) begin
                        next_state = IDLE;
                    end 
                    else begin
                        s_next = s_reg + 1;
                    end
                end
            end

            default: begin
                next_state     = IDLE;
                s_next         = 0;
                bit_count_next = 0;
                data_next      = 0;
            end
        endcase
    end

endmodule
