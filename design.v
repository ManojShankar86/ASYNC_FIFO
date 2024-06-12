// Code your design here
module async_fifo #(parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 4)
(
    input  wire                 wr_clk,     // Write clock
    input  wire                 rd_clk,     // Read clock
    input  wire                 rst_n,      // Active low reset
    input  wire [DATA_WIDTH-1:0] wr_data,    // Write data
    input  wire                 wr_en,      // Write enable
    input  wire                 rd_en,      // Read enable
    output reg  [DATA_WIDTH-1:0] rd_data,    // Read data
    output wire                 empty,      // FIFO empty flag
    output wire                 full        // FIFO full flag
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    // FIFO memory
    reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];

    // Write and read pointers
    reg [ADDR_WIDTH:0] wr_ptr = 0;
    reg [ADDR_WIDTH:0] rd_ptr = 0;
    reg [ADDR_WIDTH:0] wr_ptr_gray = 0;
    reg [ADDR_WIDTH:0] rd_ptr_gray = 0;

    // Synchronized pointers
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1 = 0, wr_ptr_gray_sync2 = 0;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1 = 0, rd_ptr_gray_sync2 = 0;

    // Full and empty signals
    assign full  = (wr_ptr_gray == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
    assign empty = (wr_ptr_gray_sync2 == rd_ptr_gray);

    // Write operation
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            fifo_mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);  // Binary to Gray code
        end
    end

    // Read operation
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            rd_data <= 0;
        end else if (rd_en && !empty) begin
            rd_data <= fifo_mem[rd_ptr[ADDR_WIDTH-1:0]];
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);  // Binary to Gray code
        end
    end

    // Synchronize write pointer into read clock domain
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // Synchronize read pointer into write clock domain
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

endmodule