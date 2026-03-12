`timescale 1ns/1ps

module async_fifo_tb;

    localparam int DATA_W = 8;
    localparam int ADDR_W = 4;
    localparam int DEPTH  = (1 << ADDR_W);

    logic              wr_clk;
    logic              wr_rst_n;
    logic              rd_clk;
    logic              rd_rst_n;
    logic              wr_en;
    logic              rd_en;
    logic [DATA_W-1:0] wdata;
    logic [DATA_W-1:0] rdata;
    logic              full;
    logic              empty;

    logic [DATA_W-1:0] exp_q[$];
    logic [DATA_W-1:0] exp_data;
    int error_count;

    async_fifo #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W)
    ) dut (
        .wr_clk   (wr_clk),
        .wr_rst_n (wr_rst_n),
        .rd_clk   (rd_clk),
        .rd_rst_n (rd_rst_n),
        .wr_en    (wr_en),
        .rd_en    (rd_en),
        .wdata    (wdata),
        .rdata    (rdata),
        .full     (full),
        .empty    (empty)
    );

    initial wr_clk = 1'b0;
    initial rd_clk = 1'b0;

    always #5  wr_clk = ~wr_clk;   // 100 MHz
    always #7  rd_clk = ~rd_clk;   // ~71.4 MHz

    task automatic apply_reset();
        begin
            wr_rst_n = 1'b0;
            rd_rst_n = 1'b0;
            wr_en    = 1'b0;
            rd_en    = 1'b0;
            wdata    = '0;

            repeat (4) @(posedge wr_clk);
            repeat (3) @(posedge rd_clk);

            wr_rst_n = 1'b1;
            repeat (2) @(posedge wr_clk);

            rd_rst_n = 1'b1;
            repeat (2) @(posedge rd_clk);
        end
    endtask

    task automatic push_word(input logic [DATA_W-1:0] data_in);
        begin
            while (full) @(posedge wr_clk);

            @(posedge wr_clk);
            wr_en <= 1'b1;
            wdata <= data_in;

            @(posedge wr_clk);
            wr_en <= 1'b0;
            wdata <= '0;

            exp_q.push_back(data_in);
            $display("[%0t] WRITE  data=0x%0h  qsize=%0d", $time, data_in, exp_q.size());
        end
    endtask

    task automatic pop_and_check();
        begin
            while (empty) @(posedge rd_clk);

            exp_data = exp_q.pop_front();

            @(posedge rd_clk);
            rd_en <= 1'b1;

            @(posedge rd_clk);
            #1;
            rd_en <= 1'b0;

            if (rdata !== exp_data) begin
                $error("[%0t] READ MISMATCH exp=0x%0h got=0x%0h", $time, exp_data, rdata);
                error_count++;
            end else begin
                $display("[%0t] READ   data=0x%0h  qsize=%0d", $time, rdata, exp_q.size());
            end
        end
    endtask

    task automatic fill_fifo_to_full();
        int i;
        begin
            $display("\n--- fill_fifo_to_full ---");
            for (i = 0; i < DEPTH; i++) begin
                push_word(i[DATA_W-1:0]);
            end

            repeat (4) @(posedge wr_clk);

            if (!full) begin
                $error("[%0t] Expected FULL=1 after filling FIFO", $time);
                error_count++;
            end
        end
    endtask

    task automatic drain_fifo_to_empty();
        int i;
        begin
            $display("\n--- drain_fifo_to_empty ---");
            for (i = 0; i < DEPTH; i++) begin
                pop_and_check();
            end

            repeat (4) @(posedge rd_clk);

            if (!empty) begin
                $error("[%0t] Expected EMPTY=1 after draining FIFO", $time);
                error_count++;
            end
        end
    endtask

    task automatic basic_write_then_read();
        int i;
        begin
            $display("\n--- basic_write_then_read ---");
            for (i = 0; i < 8; i++) begin
                push_word(8'hA0 + i);
            end

            for (i = 0; i < 8; i++) begin
                pop_and_check();
            end
        end
    endtask

    task automatic interleaved_write_read();
        int i;
        begin
            $display("\n--- interleaved_write_read ---");
            for (i = 0; i < 12; i++) begin
                push_word(8'h30 + i);

                if ((i % 2) == 1) begin
                    pop_and_check();
                end
            end

            while (exp_q.size() > 0) begin
                pop_and_check();
            end
        end
    endtask

    initial begin
        error_count = 0;
        exp_q.delete();

        apply_reset();

        if (empty !== 1'b1) begin
            $error("[%0t] FIFO should be empty after reset", $time);
            error_count++;
        end

        basic_write_then_read();
        fill_fifo_to_full();
        drain_fifo_to_empty();
        interleaved_write_read();

        repeat (10) @(posedge wr_clk);
        repeat (10) @(posedge rd_clk);

        if (exp_q.size() != 0) begin
            $error("[%0t] Expected scoreboard queue empty at end, size=%0d", $time, exp_q.size());
            error_count++;
        end

        if (error_count == 0) begin
            $display("\n====================================");
            $display("TEST PASSED");
            $display("====================================\n");
        end else begin
            $display("\n====================================");
            $display("TEST FAILED  errors=%0d", error_count);
            $display("====================================\n");
        end

        $finish;
    end

endmodule
