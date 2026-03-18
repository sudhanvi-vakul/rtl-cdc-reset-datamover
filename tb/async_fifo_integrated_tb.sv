`timescale 1ns/1ps

module async_fifo_integrated_tb;

    parameter int DATA_W = 8;
    parameter int ADDR_W = 4;
    localparam int DEPTH = (1 << ADDR_W);

    // Tune only if DUT timing requires it
    localparam int RD_LATENCY      = 0;   
    localparam int SYNC_RD_CYCLES  = 3;  
    localparam int SYNC_WR_CYCLES  = 3;   
    localparam int MAX_WAIT_CYCLES = 100;

    logic              wr_clk;
    logic              rd_clk;
    logic              wr_rst_n;
    logic              rd_rst_n;

    logic              wr_en;
    logic              rd_en;
    logic [DATA_W-1:0] wdata;
    logic [DATA_W-1:0] rdata;

    logic              full;
    logic              empty;

    logic [DATA_W-1:0] exp_q[$];
    logic [DATA_W-1:0] got_data;
    logic [DATA_W-1:0] exp_data;

    integer errors;
    integer i;
    bit ok;

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

    // Clocks

    initial wr_clk = 1'b0;
    always #5 wr_clk = ~wr_clk;   // 10 ns

    initial rd_clk = 1'b0;
    always #7 rd_clk = ~rd_clk;   // 14 ns

    // Helpers

    task automatic wait_wr_cycles(input int n);
        repeat (n) @(posedge wr_clk);
    endtask

    task automatic wait_rd_cycles(input int n);
        repeat (n) @(posedge rd_clk);
    endtask

    task automatic phase(input string name);
        begin
            $display("");
            $display("--------------------------------------------------");
            $display("%s", name);
            $display("--------------------------------------------------");
        end
    endtask

    task automatic expect_bit(
        input string check_name,
        input logic actual,
        input logic expected
    );
        begin
            if (actual !== expected) begin
                $display("[ERROR] %s : expected=%0b got=%0b at t=%0t",
                         check_name, expected, actual, $time);
                errors++;
            end
        end
    endtask

    task automatic expect_data(
        input string check_name,
        input logic [DATA_W-1:0] actual,
        input logic [DATA_W-1:0] expected
    );
        begin
            if (actual !== expected) begin
                $display("[ERROR] %s : expected=0x%0h got=0x%0h at t=%0t",
                         check_name, expected, actual, $time);
                errors++;
            end
        end
    endtask

    // Reset

    task automatic apply_reset;
        begin
            exp_q.delete();

            wr_en    = 1'b0;
            rd_en    = 1'b0;
            wdata    = '0;
            wr_rst_n = 1'b0;
            rd_rst_n = 1'b0;

            wait_wr_cycles(4);
            wait_rd_cycles(3);

            @(negedge wr_clk);
            wr_rst_n = 1'b1;

            wait_wr_cycles(2);

            @(negedge rd_clk);
            rd_rst_n = 1'b1;

            wait_wr_cycles(SYNC_WR_CYCLES);
            wait_rd_cycles(SYNC_RD_CYCLES);
        end
    endtask

    task automatic check_reset_state;
        begin
            expect_bit("reset empty", empty, 1'b1);
            expect_bit("reset full",  full,  1'b0);

`ifdef CHECK_INTERNALS
            if (dut.wr_ptr_bin !== '0) begin
                $display("[ERROR] reset wr_ptr_bin expected 0 got %0h at t=%0t", dut.wr_ptr_bin, $time);
                errors++;
            end
            if (dut.rd_ptr_bin !== '0) begin
                $display("[ERROR] reset rd_ptr_bin expected 0 got %0h at t=%0t", dut.rd_ptr_bin, $time);
                errors++;
            end
`endif
        end
    endtask

    // Transaction tasks

    task automatic fifo_write(
        input  logic [DATA_W-1:0] data,
        output bit accepted
    );
        int timeout;
        begin
            accepted = 1'b0;
            timeout  = 0;

            @(negedge wr_clk);
            while (full === 1'b1) begin
                @(negedge wr_clk);
                timeout++;
                if (timeout > MAX_WAIT_CYCLES) begin
                    $display("[ERROR] Timeout waiting for full to deassert at t=%0t", $time);
                    errors++;
                    return;
                end
            end

            wdata = data;
            wr_en = 1'b1;

            @(posedge wr_clk);    // write is accepted here
            #1;
            accepted = 1'b1;

            @(negedge wr_clk);
            wr_en = 1'b0;
            wdata = '0;
        end
    endtask

    task automatic fifo_read(
        output logic [DATA_W-1:0] data,
        output bit valid
    );
        int timeout;
        begin
            valid   = 1'b0;
            data    = '0;
            timeout = 0;

            @(negedge rd_clk);
            while (empty === 1'b1) begin
                @(negedge rd_clk);
                timeout++;
                if (timeout > MAX_WAIT_CYCLES) begin
                    $display("[ERROR] Timeout waiting for empty to deassert at t=%0t", $time);
                    errors++;
                    return;
                end
            end

            rd_en = 1'b1;

            @(posedge rd_clk);    // read is accepted here

            if (RD_LATENCY == 0) begin
                #1;
                data  = rdata;
                valid = 1'b1;
            end

            @(negedge rd_clk);
            rd_en = 1'b0;

            if (RD_LATENCY > 0) begin
                repeat (RD_LATENCY) @(posedge rd_clk);
                #1;
                data  = rdata;
                valid = 1'b1;
            end
        end
    endtask

    task automatic attempt_write_when_full(input logic [DATA_W-1:0] data);
        begin
            @(negedge wr_clk);
            wdata = data;
            wr_en = 1'b1;

            @(negedge wr_clk);
            wr_en = 1'b0;
            wdata = '0;
        end
    endtask

    task automatic attempt_read_when_empty;
        begin
            @(negedge rd_clk);
            rd_en = 1'b1;

            @(negedge rd_clk);
            rd_en = 1'b0;
        end
    endtask

    task automatic write_and_scoreboard(input logic [DATA_W-1:0] data);
        begin
            fifo_write(data, ok);
            if (ok)
                exp_q.push_back(data);
        end
    endtask

    task automatic read_and_compare(input string check_name);
        begin
            if (exp_q.size() == 0) begin
                $display("[ERROR] %s : scoreboard empty before DUT read at t=%0t", check_name, $time);
                errors++;
                return;
            end

            exp_data = exp_q[0];
            fifo_read(got_data, ok);

            if (!ok) begin
                $display("[ERROR] %s : DUT read did not complete at t=%0t", check_name, $time);
                errors++;
                return;
            end

            exp_q.pop_front();
            expect_data(check_name, got_data, exp_data);
        end
    endtask

    // Monitors

    always @(posedge wr_clk) begin
        if (wr_en && !full)
            $display("[WRITE] t=%0t data=0x%0h full=%0b empty=%0b", $time, wdata, full, empty);
    end

    always @(posedge rd_clk) begin
        if (rd_en && !empty) begin
            #1;
            $display("[READ ] t=%0t data=0x%0h full=%0b empty=%0b", $time, rdata, full, empty);
        end
    end

    // Main test

    initial begin
        errors   = 0;
        got_data = '0;
        exp_data = '0;

        phase("Starting async_fifo_integrated_tb");

        phase("Reset");
        apply_reset();
        check_reset_state();

        phase("First write / first read");
        write_and_scoreboard(8'hA5);
        wait_rd_cycles(SYNC_RD_CYCLES);
        expect_bit("empty after first write", empty, 1'b0);

        read_and_compare("first read data");
        wait_rd_cycles(SYNC_RD_CYCLES);
        expect_bit("empty after first read", empty, 1'b1);

        phase("FIFO ordering");
        write_and_scoreboard(8'hA1);
        write_and_scoreboard(8'hB2);
        write_and_scoreboard(8'hC3);

        read_and_compare("ordering read 0");
        read_and_compare("ordering read 1");
        read_and_compare("ordering read 2");

        wait_rd_cycles(SYNC_RD_CYCLES);
        expect_bit("empty after ordering test", empty, 1'b1);

        phase("Fill to full");
        for (i = 0; i < DEPTH; i = i + 1)
            write_and_scoreboard(8'h30 + DATA_W'(i));

        wait_wr_cycles(SYNC_WR_CYCLES);
        expect_bit("full after fill", full, 1'b1);

        phase("Overflow attempt");
        attempt_write_when_full(8'hEE);
        wait_wr_cycles(SYNC_WR_CYCLES);
        expect_bit("full after overflow attempt", full, 1'b1);

        phase("Drain to empty");
        while (exp_q.size() > 0)
            read_and_compare("drain read");

        wait_rd_cycles(SYNC_RD_CYCLES);
        expect_bit("empty after drain", empty, 1'b1);

        phase("Underflow attempt");
        attempt_read_when_empty();
        wait_rd_cycles(SYNC_RD_CYCLES);
        expect_bit("empty after underflow attempt", empty, 1'b1);

        phase("Final result");
        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED with %0d error(s)", errors);

        #20;
        $finish;
    end

endmodule