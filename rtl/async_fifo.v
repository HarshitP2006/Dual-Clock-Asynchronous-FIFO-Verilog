module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire                  wr_clk,
    input  wire                  wr_rst,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    output wire                  full,
    output wire                  almost_full,

    input  wire                  rd_clk,
    input  wire                  rd_rst,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] dout,
    output wire                  empty,
    output wire                  almost_empty
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Binary and Gray pointers
    reg [ADDR_WIDTH:0] wr_bin = 0, wr_gray = 0;
    reg [ADDR_WIDTH:0] rd_bin = 0, rd_gray = 0;

    // Pointer sync
    reg [ADDR_WIDTH:0] wr_gray_sync1 = 0, wr_gray_sync2 = 0;
    reg [ADDR_WIDTH:0] rd_gray_sync1 = 0, rd_gray_sync2 = 0;

    // Functions
    function [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] b);
        bin2gray = (b >> 1) ^ b;
    endfunction

    function [ADDR_WIDTH:0] gray2bin(input [ADDR_WIDTH:0] g);
        integer i;
        begin
            gray2bin[ADDR_WIDTH] = g[ADDR_WIDTH];
            for (i = ADDR_WIDTH-1; i >= 0; i = i-1)
                gray2bin[i] = gray2bin[i+1] ^ g[i];
        end
    endfunction

    // ---------------- WRITE SIDE ----------------
    always @(posedge wr_clk) begin
        if (wr_rst) begin
            wr_bin <= 0;
            wr_gray <= 0;
        end else if (wr_en && !full) begin
            mem[wr_bin[ADDR_WIDTH-1:0]] <= din;
            wr_bin  <= wr_bin + 1;
            wr_gray <= bin2gray(wr_bin + 1);
        end
    end

    // Sync read pointer into write clock (with reset)
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            rd_gray_sync1 <= 0;
            rd_gray_sync2 <= 0;
        end else begin
            rd_gray_sync1 <= rd_gray;
            rd_gray_sync2 <= rd_gray_sync1;
        end
    end

    wire [ADDR_WIDTH:0] wr_gray_next = bin2gray(wr_bin + 1);

    assign full = (wr_gray_next ==
                  {~rd_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
                    rd_gray_sync2[ADDR_WIDTH-2:0]});

// -----------------------------------------------------------------------------
// NOTE: almost_full is computed by converting a synchronized Gray pointer back
// to binary and performing arithmetic comparison. This is functionally correct
// for FPGA/student designs but not strictly CDC-safe for ASIC silicon because
// Gray→binary conversion may glitch if a metastable bit propagates.
// FULL flag logic remains CDC-safe since it compares Gray-coded pointers.
// -----------------------------------------------------------------------------
wire [ADDR_WIDTH:0] rd_bin_sync = gray2bin(rd_gray_sync2);
assign almost_full = ((wr_bin - rd_bin_sync) >= (DEPTH-2));


    // ---------------- READ DOMAIN ----------------

    // Read data directly using CURRENT read pointer
    always @(posedge rd_clk) begin
        if (rd_en && !empty)
            dout <= mem[rd_bin[ADDR_WIDTH-1:0]];
    end

    // Update read pointer
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_bin  <= 0;
            rd_gray <= 0;
        end else if (rd_en && !empty) begin
            rd_bin  <= rd_bin + 1;
            rd_gray <= bin2gray(rd_bin + 1);
        end
    end

    // Sync write pointer into read clock (with reset)
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            wr_gray_sync1 <= 0;
            wr_gray_sync2 <= 0;
        end else begin
            wr_gray_sync1 <= wr_gray;
            wr_gray_sync2 <= wr_gray_sync1;
        end
    end

    assign empty = (rd_gray == wr_gray_sync2);

// -----------------------------------------------------------------------------
// NOTE: almost_empty uses Gray→binary conversion of a synchronized pointer.
// Suitable for functional FPGA projects but not ideal for strict CDC-clean
// ASIC implementations. EMPTY flag logic remains CDC-safe.
// -----------------------------------------------------------------------------
wire [ADDR_WIDTH:0] wr_bin_sync = gray2bin(wr_gray_sync2);
assign almost_empty = ((wr_bin_sync - rd_bin) <= 2);

endmodule
