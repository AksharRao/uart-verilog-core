module fifo #(
    parameter DEPTH = 64,       // 64-entry FIFO
    parameter WIDTH = 8         // 8-bit data
)(
    input wire clk, rst,
    input wire wr_en,           // Write enable
    input wire rd_en,           // Read enable
    input wire [WIDTH-1:0] buf_in,  // Data input
    output reg buf_full,        // Full flag
    output reg buf_empty,       // Empty flag
    output reg [WIDTH-1:0] buf_out, // Data output
    output reg [$clog2(DEPTH):0] fifo_count  // Items count
);

    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;  // Pointers
    reg [WIDTH-1:0] buf_mem [0:DEPTH-1];     // Memory array

    // ---------------------------
    // Combinational Logic (Flags)
    // ---------------------------
    always @(*) begin
        buf_full  = (fifo_count == DEPTH);
        buf_empty = (fifo_count == 0);
    end

    // ---------------------------
    // Sequential Logic (Pointers)
    // ---------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            // Write pointer
            if (!buf_full && wr_en) begin
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
            end
            
            // Read pointer
            if (!buf_empty && rd_en) begin
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
            end
        end
    end

    // ---------------------------
    // FIFO Counter Logic
    // ---------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_count <= 0;
        end else begin
            case ({wr_en && !buf_full, rd_en && !buf_empty})
                2'b01: fifo_count <= fifo_count - 1;  // Read only
                2'b10: fifo_count <= fifo_count + 1;  // Write only
                2'b11: fifo_count <= fifo_count;      // Read+Write
                default: fifo_count <= fifo_count;    // No op
            endcase
        end
    end

    // ---------------------------
    // Data Path
    // ---------------------------
    // Write operation
    always @(posedge clk) begin
        if (!buf_full && wr_en) begin
            buf_mem[wr_ptr] <= buf_in;
        end
    end

    // Read operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_out <= 0;
        end else if (!buf_empty && rd_en) begin
            buf_out <= buf_mem[rd_ptr];
        end
    end

endmodule