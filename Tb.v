`timescale 1ns/1ps

module tb_async_fifo;

    // Parameters
    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 4;
    localparam DEPTH = 1 << ADDR_WIDTH;

    // Signals
    reg wr_clk;
    reg rd_clk;
    reg rst_n;
    reg [DATA_WIDTH-1:0] wr_data;
    reg wr_en;
    reg rd_en;
    wire [DATA_WIDTH-1:0] rd_data;
    wire empty;
    wire full;

    // Instantiate the asynchronous FIFO
    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) uut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst_n(rst_n),
        .wr_data(wr_data),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .empty(empty),
        .full(full)
    );

    // Clock generation
    initial begin
        wr_clk = 0;
        forever #5 wr_clk = ~wr_clk; // 100MHz write clock
    end

    initial begin
        rd_clk = 0;
        forever #7 rd_clk = ~rd_clk; // 71.4MHz read clock (slightly different to test async behavior)
    end

    // Reset sequence
    initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
    end

    // Test sequence
    initial begin
        // Initial values
        wr_data = 0;
        wr_en = 0;
        rd_en = 0;

        // Wait for reset deassertion
        @(posedge rst_n);

        // Write some data into the FIFO
        write_fifo(8'hAA);
        write_fifo(8'hBB);
        write_fifo(8'hCC);
        write_fifo(8'hDD);

        // Read some data from the FIFO
        read_fifo();
        read_fifo();
        read_fifo();
        read_fifo();

        // Write and read data concurrently
        fork
            begin
                write_fifo(8'h11);
                write_fifo(8'h22);
                write_fifo(8'h33);
                write_fifo(8'h44);
            end
            begin
                #30; // Wait some time before reading
                read_fifo();
                read_fifo();
                read_fifo();
                read_fifo();
            end
        join

        // End of simulation
        #100;
        $finish;
    end

    // Task to write data into the FIFO
    task write_fifo(input [DATA_WIDTH-1:0] data);
        begin
            @(posedge wr_clk);
            wr_data = data;
            wr_en = 1;
           @(posedge wr_clk);
            wr_en = 0;
        end
    endtask

    // Task to read data from the FIFO
    task read_fifo;
        begin
            @(posedge rd_clk);
            rd_en = 1;
            @(posedge rd_clk);
             rd_en = 0;
        end
    endtask

    // Monitor FIFO status and data
    initial begin
        $monitor("Time: %0t | wr_en: %b | rd_en: %b | wr_data: %h | rd_data: %h | empty: %b | full: %b",
                 $time, wr_en, rd_en, wr_data, rd_data, empty, full);
    end
  initial begin
    $dumpfile("a.vcd");
    $dumpvars;
  end

endmodule
