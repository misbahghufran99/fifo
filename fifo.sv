
// a 2D "packed" array indicates that both dimensions are declared before the variable name, 
// resulting in a contiguous block of bits in memory, 
// while a 2D "unpacked" array has at least one dimension declared after the variable name

module fifo #(parameter DEPTH=128, parameter WIDTH=32) (
    input  logic                i_clk  ,         // Clock
    input  logic                arst_n ,         // active low rst
    input  logic                wr_en  ,         // Write enable
    input  logic                rd_en  ,         // Read enable
    input  logic [WIDTH-1:0]    wr_data,         // Write data
    output logic [WIDTH-1:0]    rd_data,         // Read data
    output logic                o_full ,         // FIFO o_full flag
    output logic                o_empty          // FIFO o_empty flag
);


    // FIFO memory and pointers
    logic   [DEPTH-1:0] [WIDTH-1:0]            fifo_mem          ;  // FIFO memory array packed array
    logic   [$clog2(DEPTH):0      ]            rd_ptr            ;  // Read pointer
    logic   [$clog2(DEPTH):0      ]            count             ;  // Counter to track entries in FIFO
    logic   [$clog2(DEPTH):0      ]            wr_ptr            ;  // Write pointer




    // Write pointer logic
    always @(posedge i_clk or negedge arst_n) begin
        if (!arst_n) begin
            wr_ptr   <= 0                   ;
        end else if (wr_en && !o_full) begin
            wr_ptr   <= (wr_ptr + 1) % DEPTH;
        end
    end



    // Write operation
    always @(posedge i_clk or negedge arst_n) begin
        if (!arst_n) begin
            fifo_mem         <= 0      ;
        end else if (wr_en && !o_full) begin
            fifo_mem[wr_ptr] <= wr_data;
        end
    end



    // Read pointer logic
    always @(posedge i_clk or negedge arst_n) begin
        if (!arst_n) begin
            rd_ptr  <= 0                   ;
        end else if (rd_en && !o_empty) begin
            rd_ptr  <= (rd_ptr + 1) % DEPTH;
        end
    end



    // Read operation
    always @(posedge i_clk or negedge arst_n) begin
        if (!arst_n) begin
            rd_data <= 0                   ;
        end else if (rd_en && !o_empty) begin
            rd_data <= fifo_mem[rd_ptr]    ;
        end
    end



    // Count logic
    always @(posedge i_clk or negedge arst_n) begin
        if (!arst_n) begin
            count <= 0;
        end else begin
            case ({wr_en && !o_full, rd_en && !o_empty})
                2'b10:   count   <= count + 1;  // Write without read
                2'b01:   count   <= count - 1;  // Read without write
                default: count   <= count    ;  // No operation or simultaneous read/write
            endcase
        end
    end



    // o_full and o_empty flags
    assign o_full  = (count == DEPTH);
    assign o_empty = (count == 0)    ;

endmodule
