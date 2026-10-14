
`timescale 1ns / 1ps

module tb_async_fifo;

    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 4;
    localparam DEPTH = (1 << ADDR_WIDTH);

    reg wr_clk = 0;
    reg rd_clk = 0;
    reg rst_n = 1;

    reg wr_en = 0;
    reg rd_en = 0;
    reg [DATA_WIDTH-1:0] wr_data = 0;

    wire [DATA_WIDTH-1:0] rd_data;
    wire full, empty;

    reg [DATA_WIDTH-1:0] expected [0:DEPTH-1];

    integer wr_count = 0;
    integer rd_count = 0;
    integer i;

    // Device Under Test
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .full(full),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .empty(empty)
    );

    // Independent asynchronous clocks
    always #5 wr_clk = ~wr_clk;
    always #7 rd_clk = ~rd_clk;

    // Write one word and record the accepted transaction
    task write_byte(input [DATA_WIDTH-1:0] data);
    begin
        @(negedge wr_clk);
        wr_data = data;
        wr_en = 1;

        // Check before the next rising edge
        #1;
        if (full !== 1'b0)
            $fatal(1, "Unexpected FULL before valid write");

        @(posedge wr_clk);

        expected[wr_count] = data;
        wr_count = wr_count + 1;

        @(negedge wr_clk);
        wr_en = 0;
    end
    endtask

    // Read one word and compare it against the expected value
    task read_byte;
    begin
        @(negedge rd_clk);

        if (empty !== 1'b0)
            $fatal(1, "Unexpected EMPTY before valid read");

        rd_en = 1;

        @(posedge rd_clk);
        #1;

        if (rd_data !== expected[rd_count])
            $fatal(1,
                "DATA MISMATCH: expected=%h received=%h",
                expected[rd_count], rd_data);

        rd_count = rd_count + 1;

        @(negedge rd_clk);
        rd_en = 0;
    end
    endtask

    initial begin
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);

        // TEST 1: Reset
        #1 rst_n = 0;
        repeat (4) @(negedge wr_clk);
        rst_n = 1;

        repeat (3) @(negedge wr_clk);

        if (empty !== 1'b1)
            $fatal(1, "Reset failed: EMPTY not asserted");

        if (full !== 1'b0)
            $fatal(1, "Reset failed: FULL asserted");

        $display("PASS: Reset behaviour");

        // TEST 2: Fill FIFO
        for (i = 0; i < DEPTH; i = i + 1)
            write_byte(8'h40 + i);

        repeat (2) @(negedge wr_clk);

        if (full !== 1'b1)
            $fatal(1, "FIFO failed to assert FULL");

        $display("PASS: FIFO FULL detection");

        // TEST 3: Attempt overflow
        @(negedge wr_clk);
        wr_data = 8'hFF;
        wr_en = 1;

        #1;
        if (full !== 1'b1)
            $fatal(1, "FIFO not FULL before overflow attempt");

        @(posedge wr_clk);
        #1;

        if (full !== 1'b1)
            $fatal(1, "FULL flag unexpectedly deasserted");

        @(negedge wr_clk);
        wr_en = 0;

        $display("PASS: Overflow write blocked");

        // Allow write pointer synchronization
        repeat (4) @(negedge rd_clk);

        // TEST 4: Read and verify all stored words
        for (i = 0; i < DEPTH; i = i + 1)
            read_byte();

        if (rd_count != DEPTH)
            $fatal(1, "Incorrect number of reads");

        $display("PASS: All %0d data words verified", rd_count);

        // Allow read pointer synchronization
        repeat (4) @(negedge rd_clk);

        if (empty !== 1'b1)
            $fatal(1, "FIFO failed to assert EMPTY");

        $display("PASS: FIFO EMPTY detection");

        // TEST 5: Underflow
        $display("Starting underflow test at %0t", $time);

        @(negedge rd_clk);

        if (empty !== 1'b1)
            $fatal(1, "FIFO not EMPTY before underflow attempt");

        rd_en = 1;

        @(posedge rd_clk);
        #1;

        if (empty !== 1'b1)
            $fatal(1, "EMPTY flag unexpectedly deasserted");

        @(negedge rd_clk);
        rd_en = 0;

        $display("PASS: Underflow read blocked");

        // Final summary
        $display("----------------------------------");
        $display("ASYNC FIFO VERIFICATION SUMMARY");
        $display("FIFO depth      : %0d", DEPTH);
        $display("Accepted writes : %0d", wr_count);
        $display("Accepted reads  : %0d", rd_count);
        $display("ALL TESTS PASSED");
        $display("----------------------------------");

        $finish;
    end

endmodule
