
`timescale 1ns / 1ps

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                  wr_clk,
    input  wire                  rd_clk,
    input  wire                  rst_n,

    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  full,

    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output wire                  empty
);

    localparam DEPTH = (1 << ADDR_WIDTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    reg [PTR_WIDTH-1:0] wbin, wgray;
    reg [PTR_WIDTH-1:0] rbin, rgray;

    reg [PTR_WIDTH-1:0] rgray_wsync1, rgray_wsync2;
    reg [PTR_WIDTH-1:0] wgray_rsync1, wgray_rsync2;

    reg full_reg, empty_reg;

    wire wr_fire = wr_en && !full_reg;
    wire rd_fire = rd_en && !empty_reg;

    wire [PTR_WIDTH-1:0] wbin_next = wbin + wr_fire;
    wire [PTR_WIDTH-1:0] rbin_next = rbin + rd_fire;

    wire [PTR_WIDTH-1:0] wgray_next =
        (wbin_next >> 1) ^ wbin_next;

    wire [PTR_WIDTH-1:0] rgray_next =
        (rbin_next >> 1) ^ rbin_next;

    wire full_next =
        (wgray_next ==
        {~rgray_wsync2[PTR_WIDTH-1:PTR_WIDTH-2],
          rgray_wsync2[PTR_WIDTH-3:0]});

    wire empty_next = (rgray_next == wgray_rsync2);

    assign full  = full_reg;
    assign empty = empty_reg;

    // Synchronize read pointer into write clock domain.
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rgray_wsync1 <= 0;
            rgray_wsync2 <= 0;
        end else begin
            rgray_wsync1 <= rgray;
            rgray_wsync2 <= rgray_wsync1;
        end
    end

    // Synchronize write pointer into read clock domain.
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wgray_rsync1 <= 0;
            wgray_rsync2 <= 0;
        end else begin
            wgray_rsync1 <= wgray;
            wgray_rsync2 <= wgray_rsync1;
        end
    end

    // Write pointer, memory write and full flag.
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wbin     <= 0;
            wgray    <= 0;
            full_reg <= 0;
        end else begin
            if (wr_fire)
                mem[wbin[ADDR_WIDTH-1:0]] <= wr_data;

            wbin     <= wbin_next;
            wgray    <= wgray_next;
            full_reg <= full_next;
        end
    end

    // Read pointer, output data and empty flag.
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rbin      <= 0;
            rgray     <= 0;
            rd_data   <= 0;
            empty_reg <= 1;
        end else begin
            if (rd_fire)
                rd_data <= mem[rbin[ADDR_WIDTH-1:0]];

            rbin      <= rbin_next;
            rgray     <= rgray_next;
            empty_reg <= empty_next;
        end
    end

endmodule
