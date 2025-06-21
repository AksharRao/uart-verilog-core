// this UART_tx module is intended to model a UART transmitter.

module uart_tx #(
    parameter DBIT_WIDTH = 8,
    parameter SB_TICK = 16
)
(
    input  wire clk,            // System clock
    input  wire rst,            // Reset signal (active high)
    input  wire tx_start,       // Signal to start transmission
    input  wire s_tick,         // Sample tick from baud generator
    input wire [DBIT_WIDTH-1:0] data_in,   // Data to be transmitted
    output reg  tx_done_tick,   // Transmission done pulse
    output reg tx               // Serial data output
);

localparam [1:0] IDLE  = 2'b00,
                 START = 2'b01,
                 DATA  = 2'b10,
                 STOP  = 2'b11;

reg [1:0] current_state, next_state; // State registers
reg [3:0] s_reg, s_next;             // Sample counter
reg [$clog2(DBIT_WIDTH):0] bit_count, bit_count_next; // Bit counter (for 8 bits)
reg [DBIT_WIDTH-1:0] data_reg, data_next;       // Data register
reg tx_reg; // Register for serial output
reg tx_next; // Next value for serial output

//FSM States and Logic

always@(posedge clk or posedge rst) begin
    if(rst)
    begin
        current_state <= IDLE; // Reset to IDLE state
        s_reg <= 0;          // Reset sample counter
        bit_count <= 0;    // Reset bit counter
        data_reg <= 0;    // Reset data register
        tx_reg <= 1; // Idle state for TX line (logic high)
    end
    else begin
        current_state <= next_state; // Update current state
        s_reg <= s_next;             // Update sample counter
        bit_count <= bit_count_next; // Update bit counter
        data_reg <= data_next;       // Update data register
        tx_reg <= tx_next;           // Update TX line state
    end
end

//FSM Next State Logic
always @(*) begin
    //initially set next state and other variables
    tx_done_tick = 1'b0; // Default, pulse for one clock
    next_state = current_state;
    s_next = s_reg;
    bit_count_next = bit_count;
    data_next = data_reg;
    tx_next = tx_reg;

    case (current_state) 
        IDLE: begin
            tx_next = 1; // TX line is high in IDLE state
            if (tx_start) begin
                next_state = START; // Move to START state on tx_start signal
                s_next = 0; // Reset sample counter
                data_next = data_in; // Load data to be transmitted
            end
        end

            START: begin
                tx_next = 0; // Start bit (logic low)
                if (s_tick) 
                begin
                    if(s_reg == SB_TICK - 1) begin
                        next_state = DATA; // Move to DATA state after START bit
                        bit_count_next = 0; // Reset bit counter
                        s_next = 0; // Reset sample counter
                    end
                else 
                    begin
                        s_next = s_reg + 1; // Increment sample counter
                    end 
                end
            end 

            DATA: begin
                tx_next = data_reg[0]; // Transmit the current bit
                if (s_tick) 
                begin
                    if (s_reg == SB_TICK - 1) 
                    begin   
                        s_next = 0; // Reset sample counter
                        data_next = data_reg >> 1; // Shift data register to the right
                        if (bit_count == DBIT_WIDTH - 1) begin
                            next_state = STOP; // Move to STOP state after all data bits are sent
                            tx_done_tick = 1'b1; // Set done tick for transmission completion
                        end else begin
                            bit_count_next = bit_count + 1; // Increment bit counter
                        end
                    end
                    else begin 
                        s_next = s_reg + 1; // Increment sample counter
                    end
                end
            end

            STOP: begin
                tx_next = 1; // Stop bit (logic high)
                if (s_tick) 
                begin
                    if (s_reg == SB_TICK - 1) 
                    begin
                        next_state = IDLE; // Return to IDLE state after STOP bit
                        s_next = 0; // Reset sample counter
                        tx_done_tick = 1'b1; // Set done tick for transmission completion
                    end 
                    else 
                    begin
                        s_next = s_reg + 1; // Increment sample counter
                    end
                end
            end
    endcase
end

assign tx = tx_reg; // Assign the TX line output

endmodule