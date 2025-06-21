// this module is intended to model a baude generator for UART

module baud_gen(
    input wire clk, //this is the system clock, typically 50 MHz
    input wire rst, //reset signal to reset the internal counter to 0
    input wire [15:0] dvsr, 
    output reg tick //tick signal that will be set high when the internal counter reaches the divisor value
);

    reg [15:0] internal_counter; //to count upto dvsr, and when it reaches dvsr, tick is set to 1
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            internal_counter <= 0;
            tick <= 0;
        end else begin
            if (internal_counter < dvsr - 1) begin
                internal_counter <= internal_counter + 1;
                tick <= 0; //keep tick low until we reach the divisor value
            end else begin
                internal_counter <= 0; //reset counter
                tick <= 1; //set tick high when we reach the divisor value
            end
        end
    end
endmodule

//Write these in markdown for README.md
// End of baude_gen.v
// This module generates a tick signal at a specified baud rate based on the input clock frequency and divisor value.
// The tick signal can be used to synchronize UART communication by indicating when a new bit is ready to be transmitted or received.
// The divisor value: dvsr = clk_freq_cpu (50M Hz in our case) / baude_rate (9600 in our case)
// For example, for a 50 MHz clock and a baud rate of 9600, the divisor value would be 5208 (rounded).
// The module uses a simple counter to count up to the divisor value and generates a tick signal when the count reaches that value.