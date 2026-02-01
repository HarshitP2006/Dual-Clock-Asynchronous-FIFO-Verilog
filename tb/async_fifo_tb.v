`timescale 1ns/1ps

module async_fifo_tb;

    parameter DATA_WIDTH = 8;
    parameter DEPTH = 16;
    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg wr_clk, wr_rst, wr_en;
    reg rd_clk, rd_rst, rd_en;
    reg  [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;
    wire full, empty, almost_full, almost_empty;

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .wr_clk(wr_clk),
        .wr_rst(wr_rst),
        .wr_en(wr_en),
        .din(din),
        .full(full),
        .almost_full(almost_full),
        .rd_clk(rd_clk),
        .rd_rst(rd_rst),
        .rd_en(rd_en),
        .dout(dout),
        .empty(empty),
        .almost_empty(almost_empty)
    );

    always #5  wr_clk = ~wr_clk;
    always #8  rd_clk = ~rd_clk;

    // Scoreboard memory
    reg [DATA_WIDTH-1:0] queue [0:1023];
    integer head = 0;
    integer tail = 0;

    // Track write pointer
    always @(posedge wr_clk)
        if (wr_en && !full) begin
            queue[tail] = din;
            tail = tail + 1;
        end

    // ---------------- OUTPUT VALID DETECTION ----------------
    // Detect data leaving FIFO by observing rd_gray pointer change
    reg [ADDR_WIDTH:0] rd_gray_prev;

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst)
            rd_gray_prev <= 0;
        else
            rd_gray_prev <= dut.rd_gray;  // tap internal pointer
    end

    wire read_happened = (rd_gray_prev != dut.rd_gray);

    always @(posedge rd_clk) begin
        if (read_happened) begin
            if (dout !== queue[head]) begin
                $display("❌ DATA MISMATCH at time %t", $time);
                $display("Expected: %0d, Got: %0d", queue[head], dout);
                $fatal;
            end
            head = head + 1;
        end
    end

    // ---------------- STIMULUS ----------------
    initial begin
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, async_fifo_tb);

        wr_clk = 0; rd_clk = 0;
        wr_rst = 1; rd_rst = 1;
        wr_en = 0; rd_en = 0;
        din = 0;

        #20;
        wr_rst = 0; rd_rst = 0;

        // Write burst
        repeat (20) begin
            @(posedge wr_clk);
            if (!full) begin
                wr_en = 1;
                din = din + 1;
            end
        end
        wr_en = 0;

        #100;

        // Read burst
        repeat (20) begin
            @(posedge rd_clk);
            if (!empty)
                rd_en = 1;
        end
        rd_en = 0;

        #200;

        if (head != tail) begin
            $display("❌ FIFO count mismatch: head=%0d tail=%0d", head, tail);
            $fatal;
        end

        $display("✅ TEST PASSED — FIFO data integrity verified");
        $finish;
    end

endmodule
