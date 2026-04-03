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
    logic              wr_arst_n;
    logic              rd_arst_n;
    logic              wr_srst_n;
    logic              rd_srst_n;

    logic              wr_en;
    logic              rd_en;
    logic [DATA_W-1:0] wdata;
    logic [DATA_W-1:0] rdata;

    logic              full;
    logic              empty;

    logic [DATA_W-1:0] exp_q[$];
    logic [DATA_W-1:0] got_data;
    logic [DATA_W-1:0] exp_data;

    integer   errors;
    integer   i;
    bit       ok;
    bit       run_advanced_resets;

    time wr_half_period;
    time rd_half_period;

    async_fifo_reset_safe #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W)
    ) dut (
        .wr_clk    (wr_clk),
        .wr_arst_n (wr_arst_n),
        .rd_clk    (rd_clk),
        .rd_arst_n (rd_arst_n),
        .wr_en     (wr_en),
        .rd_en     (rd_en),
        .wdata     (wdata),
        .rdata     (rdata),
        .full      (full),
        .empty     (empty),
        .wr_srst_n (wr_srst_n),
        .rd_srst_n (rd_srst_n)
    );

    // Clocks

    initial begin
        wr_half_period = 5;
        wr_clk         = 1'b0;
        forever #(wr_half_period) wr_clk = ~wr_clk;
    end

    initial begin
        rd_half_period = 7;
        rd_clk         = 1'b0;
        forever #(rd_half_period) rd_clk = ~rd_clk;
    end

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
        input logic  actual,
        input logic  expected
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
        input string             check_name,
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

    task automatic wait_until_wr(
        input string check_name,
        ref   logic  sig,
        input logic  expected
    );
        int timeout;
        begin
            timeout = 0;
            while (sig !== expected) begin
                @(posedge wr_clk);
                timeout++;
                if (timeout > MAX_WAIT_CYCLES) begin
                    $display("[ERROR] %s : timed out waiting for %0b at t=%0t",
                             check_name, expected, $time);
                    errors++;
                    return;
                end
            end
        end
    endtask

    task automatic wait_until_rd(
        input string check_name,
        ref   logic  sig,
        input logic  expected
    );
        int timeout;
        begin
            timeout = 0;
            while (sig !== expected) begin
                @(posedge rd_clk);
                timeout++;
                if (timeout > MAX_WAIT_CYCLES) begin
                    $display("[ERROR] %s : timed out waiting for %0b at t=%0t",
                             check_name, expected, $time);
                    errors++;
                    return;
                end
            end
        end
    endtask

    task automatic set_default_clocks;
        begin
            wr_half_period = 5;   // 10 ns
            rd_half_period = 7;   // 14 ns
            wait_wr_cycles(2);
            wait_rd_cycles(2);
        end
    endtask

    task automatic set_fast_write_slow_read;
        begin
            wr_half_period = 3;   // 6 ns
            rd_half_period = 11;  // 22 ns
            wait_wr_cycles(2);
            wait_rd_cycles(2);
        end
    endtask

    task automatic set_fast_read_slow_write;
        begin
            wr_half_period = 11;  // 22 ns
            rd_half_period = 3;   // 6 ns
            wait_wr_cycles(2);
            wait_rd_cycles(2);
        end
    endtask

    task automatic scoreboard_clear;
        begin
            exp_q.delete();
        end
    endtask

    task automatic scoreboard_push(input logic [DATA_W-1:0] data);
        begin
            exp_q.push_back(data);
        end
    endtask

    task automatic scoreboard_pop_front(
        output logic [DATA_W-1:0] data,
        output bit                valid
    );
        begin
            valid = 1'b0;
            data  = '0;

            if (exp_q.size() > 0) begin
                data  = exp_q[0];
                exp_q.pop_front();
                valid = 1'b1;
            end
        end
    endtask

    // Reset

    task automatic apply_reset;
        begin
            scoreboard_clear();

            wr_en     = 1'b0;
            rd_en     = 1'b0;
            wdata     = '0;
            wr_arst_n = 1'b0;
            rd_arst_n = 1'b0;

            wait_wr_cycles(4);
            wait_rd_cycles(3);

            @(negedge wr_clk);
            wr_arst_n = 1'b1;

            wait_wr_cycles(2);

            @(negedge rd_clk);
            rd_arst_n = 1'b1;

            wait_until_wr("apply_reset wr_srst_n release", wr_srst_n, 1'b1);
            wait_until_rd("apply_reset rd_srst_n release", rd_srst_n, 1'b1);

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

    task automatic check_reset_sync_release;
        begin
            scoreboard_clear();
            wr_en     = 1'b0;
            rd_en     = 1'b0;
            wdata     = '0;
            wr_arst_n = 1'b0;
            rd_arst_n = 1'b0;

            #1;
            expect_bit("TC02 wr_srst immediate assert", wr_srst_n, 1'b0);
            expect_bit("TC02 rd_srst immediate assert", rd_srst_n, 1'b0);

            @(negedge wr_clk);
            wr_arst_n = 1'b1;
            #1;
            expect_bit("TC02 wr_srst stays low before wr_clk release", wr_srst_n, 1'b0);
            wait_until_wr("TC02 wr_srst synchronous release", wr_srst_n, 1'b1);

            @(negedge rd_clk);
            rd_arst_n = 1'b1;
            #1;
            expect_bit("TC02 rd_srst stays low before rd_clk release", rd_srst_n, 1'b0);
            wait_until_rd("TC02 rd_srst synchronous release", rd_srst_n, 1'b1);

            wait_wr_cycles(SYNC_WR_CYCLES);
            wait_rd_cycles(SYNC_RD_CYCLES);
            check_reset_state();
        end
    endtask

    // Transaction tasks

    task automatic fifo_write(
        input  logic [DATA_W-1:0] data,
        output bit                accepted
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
        output bit                valid
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
                scoreboard_push(data);
        end
    endtask

    task automatic read_and_compare(input string check_name);
        bit have_expected;
        begin
            scoreboard_pop_front(exp_data, have_expected);
            if (!have_expected) begin
                $display("[ERROR] %s : scoreboard empty before DUT read at t=%0t", check_name, $time);
                errors++;
                return;
            end

            fifo_read(got_data, ok);

            if (!ok) begin
                $display("[ERROR] %s : DUT read did not complete at t=%0t", check_name, $time);
                errors++;
                return;
            end

            expect_data(check_name, got_data, exp_data);
        end
    endtask

    // Testcase tasks

    task automatic tc01_reset_default_state;
        begin
            phase("TC01 Reset Default State");
            set_default_clocks();
            apply_reset();
            check_reset_state();
        end
    endtask

    task automatic tc02_reset_synchronizer_deassertion;
        begin
            phase("TC02 Reset Synchronizer Deassertion");
            set_default_clocks();
            check_reset_sync_release();
        end
    endtask

    task automatic tc03_single_write_single_read;
        begin
            phase("TC03 Single Write Single Read");
            set_default_clocks();
            apply_reset();

            write_and_scoreboard(8'hA5);
            wait_until_rd("TC03 empty deassert", empty, 1'b0);

            read_and_compare("TC03 readback 0xA5");
            wait_until_rd("TC03 empty reassert", empty, 1'b1);
        end
    endtask

    task automatic tc04_multiple_write_multiple_read;
        begin
            phase("TC04 Multiple Write Multiple Read");
            set_default_clocks();
            apply_reset();

            write_and_scoreboard(8'h11);
            write_and_scoreboard(8'h22);
            write_and_scoreboard(8'h33);
            write_and_scoreboard(8'h44);

            read_and_compare("TC04 read 11");
            read_and_compare("TC04 read 22");
            read_and_compare("TC04 read 33");
            read_and_compare("TC04 read 44");

            wait_until_rd("TC04 empty after drain", empty, 1'b1);
        end
    endtask

    task automatic tc05_fill_until_full;
        begin
            phase("TC05 Fill Until Full");
            set_default_clocks();
            apply_reset();

            for (i = 0; i < DEPTH; i = i + 1)
                write_and_scoreboard(8'h30 + DATA_W'(i));

            wait_until_wr("TC05 full assert", full, 1'b1);
        end
    endtask

    task automatic tc06_drain_until_empty;
        begin
            phase("TC06 Drain Until Empty");
            set_default_clocks();
            apply_reset();

            for (i = 0; i < 6; i = i + 1)
                write_and_scoreboard(8'h40 + DATA_W'(i));

            for (i = 0; i < 6; i = i + 1)
                read_and_compare($sformatf("TC06 drain read %0d", i));

            wait_until_rd("TC06 empty assert", empty, 1'b1);
        end
    endtask

    task automatic tc07_concurrent_read_write;
        begin
            phase("TC07 Concurrent Read Write");
            set_default_clocks();
            apply_reset();

            for (i = 0; i < 4; i = i + 1)
                write_and_scoreboard(8'h60 + DATA_W'(i));

            // Interleave writes and reads while clocks remain asynchronous.
            // This gives overlapping multi-clock activity without introducing
            // class-based synchronization objects into the TB.
            for (i = 0; i < 8; i = i + 1) begin
                write_and_scoreboard(8'h80 + DATA_W'(i));
                read_and_compare($sformatf("TC07 interleaved read %0d", i));
            end

            for (i = 0; i < 4; i = i + 1)
                read_and_compare($sformatf("TC07 final drain %0d", i));

            wait_until_rd("TC07 final empty", empty, 1'b1);
        end
    endtask

    task automatic tc08_underflow_attempt;
        begin
            phase("TC08 Underflow Attempt");
            set_default_clocks();
            apply_reset();

            attempt_read_when_empty();
            wait_rd_cycles(SYNC_RD_CYCLES);
            expect_bit("TC08 empty remains asserted", empty, 1'b1);

`ifdef CHECK_INTERNALS
            if (dut.rd_ptr_bin !== '0) begin
                $display("[ERROR] TC08 rd_ptr_bin changed during underflow attempt: %0h", dut.rd_ptr_bin);
                errors++;
            end
`endif
        end
    endtask

    task automatic tc09_overflow_attempt;
        begin
            phase("TC09 Overflow Attempt");
            set_default_clocks();
            apply_reset();

            for (i = 0; i < DEPTH; i = i + 1)
                write_and_scoreboard(8'h90 + DATA_W'(i));

            wait_until_wr("TC09 full assert", full, 1'b1);
            attempt_write_when_full(8'hEE);
            wait_wr_cycles(SYNC_WR_CYCLES);
            expect_bit("TC09 full remains asserted", full, 1'b1);

            for (i = 0; i < DEPTH; i = i + 1)
                read_and_compare($sformatf("TC09 drain preserved data %0d", i));

            wait_until_rd("TC09 empty after legal drain", empty, 1'b1);
        end
    endtask

    task automatic tc10_pointer_wraparound;
        begin
            phase("TC10 Pointer Wraparound");
            set_default_clocks();
            apply_reset();

            for (i = 0; i < (DEPTH/2 + 2); i = i + 1)
                write_and_scoreboard(8'hA0 + DATA_W'(i));

            for (i = 0; i < (DEPTH/2); i = i + 1)
                read_and_compare($sformatf("TC10 first drain %0d", i));

            for (i = 0; i < (DEPTH + 2); i = i + 1)
                write_and_scoreboard(8'hB0 + DATA_W'(i));

            for (i = 0; i < (DEPTH/2 + 4); i = i + 1)
                read_and_compare($sformatf("TC10 second drain %0d", i));

            while (exp_q.size() > 0)
                read_and_compare("TC10 final drain");

            wait_until_rd("TC10 final empty", empty, 1'b1);
        end
    endtask

    task automatic tc11_empty_flag_deassertion_latency;
        begin
            phase("TC11 Empty Flag Deassertion Latency");
            set_default_clocks();
            apply_reset();

            write_and_scoreboard(8'h5A);
            wait_rd_cycles(1);
            expect_bit("TC11 empty not deasserted immediately", empty, 1'b1);
            wait_until_rd("TC11 empty deasserts after sync", empty, 1'b0);

            read_and_compare("TC11 readback");
            wait_until_rd("TC11 empty reasserts", empty, 1'b1);
        end
    endtask

    task automatic tc12_full_flag_deassertion_latency;
        begin
            phase("TC12 Full Flag Deassertion Latency");
            set_default_clocks();
            apply_reset();

            for (i = 0; i < DEPTH; i = i + 1)
                write_and_scoreboard(8'hC0 + DATA_W'(i));

            wait_until_wr("TC12 full assert", full, 1'b1);
            read_and_compare("TC12 one read from full");
            wait_wr_cycles(1);
            expect_bit("TC12 full not deasserted immediately", full, 1'b1);
            wait_until_wr("TC12 full deasserts after sync", full, 1'b0);

            while (exp_q.size() > 0)
                read_and_compare("TC12 remaining drain");

            wait_until_rd("TC12 final empty", empty, 1'b1);
        end
    endtask

    task automatic tc13_fast_write_slow_read;
        begin
            phase("TC13 Fast Write Slow Read");
            set_fast_write_slow_read();
            apply_reset();

            // Producer pressure: two writes for each read.
            for (i = 0; i < 10; i = i + 1) begin
                write_and_scoreboard(8'hD0 + DATA_W'((2*i)+0));
                write_and_scoreboard(8'hD0 + DATA_W'((2*i)+1));
                read_and_compare($sformatf("TC13 read %0d", i));
            end

            while (exp_q.size() > 0)
                read_and_compare("TC13 final drain");

            wait_until_rd("TC13 final empty", empty, 1'b1);
            set_default_clocks();
        end
    endtask

    task automatic tc14_fast_read_slow_write;
        begin
            phase("TC14 Fast Read Slow Write");
            set_fast_read_slow_write();
            apply_reset();

            for (i = 0; i < 8; i = i + 1) begin
                attempt_read_when_empty();
                expect_bit($sformatf("TC14 empty before write %0d", i), empty, 1'b1);
                write_and_scoreboard(8'hE0 + DATA_W'(i));
                wait_until_rd($sformatf("TC14 empty deassert %0d", i), empty, 1'b0);
                read_and_compare($sformatf("TC14 read %0d", i));
                wait_until_rd($sformatf("TC14 empty reassert %0d", i), empty, 1'b1);
            end

            set_default_clocks();
        end
    endtask

    task automatic tc15_midstream_global_reset_recovery;
        begin
            phase("TC15 Mid-Stream Global Reset Recovery");
            set_default_clocks();
            apply_reset();

            write_and_scoreboard(8'h21);
            write_and_scoreboard(8'h22);
            write_and_scoreboard(8'h23);
            wait_until_rd("TC15 data visible before reset", empty, 1'b0);

            @(negedge wr_clk);
            wr_arst_n = 1'b0;
            @(negedge rd_clk);
            rd_arst_n = 1'b0;
            scoreboard_clear();

            #1;
            expect_bit("TC15 wr_srst asserted", wr_srst_n, 1'b0);
            expect_bit("TC15 rd_srst asserted", rd_srst_n, 1'b0);

            @(negedge wr_clk);
            wr_arst_n = 1'b1;
            @(negedge rd_clk);
            rd_arst_n = 1'b1;

            wait_until_wr("TC15 wr_srst release", wr_srst_n, 1'b1);
            wait_until_rd("TC15 rd_srst release", rd_srst_n, 1'b1);
            wait_wr_cycles(SYNC_WR_CYCLES);
            wait_rd_cycles(SYNC_RD_CYCLES);
            check_reset_state();

            write_and_scoreboard(8'h55);
            read_and_compare("TC15 post-reset readback");
            wait_until_rd("TC15 empty after post-reset traffic", empty, 1'b1);
        end
    endtask

    task automatic tc16_idle_stability;
        logic empty_before_idle;
        logic full_before_idle;
        begin
            phase("TC16 Idle Stability");
            set_default_clocks();
            apply_reset();

            write_and_scoreboard(8'h66);
            wait_until_rd("TC16 data visible", empty, 1'b0);

            empty_before_idle = empty;
            full_before_idle  = full;

            wait_wr_cycles(8);
            wait_rd_cycles(8);

            expect_bit("TC16 empty stable during idle", empty, empty_before_idle);
            expect_bit("TC16 full stable during idle",  full,  full_before_idle);

            read_and_compare("TC16 read after idle");
            wait_until_rd("TC16 empty after idle drain", empty, 1'b1);
        end
    endtask

    task automatic tc17_data_pattern_sweep;
        logic [DATA_W-1:0] patterns [0:7];
        begin
            phase("TC17 Data Pattern Sweep");
            set_default_clocks();
            apply_reset();

            patterns[0] = 8'h00;
            patterns[1] = 8'hFF;
            patterns[2] = 8'h55;
            patterns[3] = 8'hAA;
            patterns[4] = 8'h01;
            patterns[5] = 8'h80;
            patterns[6] = 8'h7F;
            patterns[7] = 8'hFE;

            for (i = 0; i < 8; i = i + 1)
                write_and_scoreboard(patterns[i]);

            for (i = 0; i < 8; i = i + 1)
                read_and_compare($sformatf("TC17 pattern read %0d", i));

            wait_until_rd("TC17 final empty", empty, 1'b1);
        end
    endtask

    task automatic tc18_long_burst_stress;
        integer round;
        integer idx;
        begin
            phase("TC18 Long Burst Stress");
            set_default_clocks();
            apply_reset();

            // Long directed burst with repeated fill/drain movement so the TB
            // never deadlocks on full while still exercising extended traffic.
            for (round = 0; round < 3; round = round + 1) begin
                for (idx = 0; idx < (DEPTH - 2); idx = idx + 1)
                    write_and_scoreboard(DATA_W'(((round * 8'h20) + idx) ^ 8'h5C));

                for (idx = 0; idx < (DEPTH/2); idx = idx + 1)
                    read_and_compare($sformatf("TC18 round %0d read %0d", round, idx));
            end

            while (exp_q.size() > 0)
                read_and_compare("TC18 final drain");

            wait_until_rd("TC18 final empty", empty, 1'b1);
        end
    endtask

    task automatic tc19_write_domain_only_reset;
        begin
            phase("TC19 Write-Domain-Only Reset (Advanced)");
            set_default_clocks();
            apply_reset();

            write_and_scoreboard(8'h71);
            write_and_scoreboard(8'h72);
            wait_until_rd("TC19 visible before wr reset", empty, 1'b0);

            @(negedge wr_clk);
            wr_arst_n = 1'b0;
            #1;
            expect_bit("TC19 wr_srst immediate assert", wr_srst_n, 1'b0);

            wait_wr_cycles(2);
            @(negedge wr_clk);
            wr_arst_n = 1'b1;
            wait_until_wr("TC19 wr_srst release", wr_srst_n, 1'b1);

            // Optional / design-contract dependent: we only verify that the design
            // returns to a known state and accepts new post-reset traffic.
            scoreboard_clear();
            wait_wr_cycles(SYNC_WR_CYCLES);
            wait_rd_cycles(SYNC_RD_CYCLES);
            write_and_scoreboard(8'h73);
            read_and_compare("TC19 post-reset recovery read");
            wait_until_rd("TC19 final empty", empty, 1'b1);
        end
    endtask

    task automatic tc20_read_domain_only_reset;
        begin
            phase("TC20 Read-Domain-Only Reset (Advanced)");
            set_default_clocks();
            apply_reset();

            write_and_scoreboard(8'h81);
            write_and_scoreboard(8'h82);
            wait_until_rd("TC20 visible before rd reset", empty, 1'b0);

            @(negedge rd_clk);
            rd_arst_n = 1'b0;
            #1;
            expect_bit("TC20 rd_srst immediate assert", rd_srst_n, 1'b0);

            wait_rd_cycles(2);
            @(negedge rd_clk);
            rd_arst_n = 1'b1;
            wait_until_rd("TC20 rd_srst release", rd_srst_n, 1'b1);

            scoreboard_clear();
            wait_wr_cycles(SYNC_WR_CYCLES);
            wait_rd_cycles(SYNC_RD_CYCLES);
            write_and_scoreboard(8'h83);
            read_and_compare("TC20 post-reset recovery read");
            wait_until_rd("TC20 final empty", empty, 1'b1);
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
        errors              = 0;
        got_data            = '0;
        exp_data            = '0;
        run_advanced_resets = 1'b0;

        if ($test$plusargs("RUN_ADVANCED_RESETS"))
            run_advanced_resets = 1'b1;

        phase("Starting async_fifo_integrated_tb");

        tc01_reset_default_state();
        tc02_reset_synchronizer_deassertion();
        tc03_single_write_single_read();
        tc04_multiple_write_multiple_read();
        tc05_fill_until_full();
        tc06_drain_until_empty();
        tc07_concurrent_read_write();
        tc08_underflow_attempt();
        tc09_overflow_attempt();
        tc10_pointer_wraparound();
        tc11_empty_flag_deassertion_latency();
        tc12_full_flag_deassertion_latency();
        tc13_fast_write_slow_read();
        tc14_fast_read_slow_write();
        tc15_midstream_global_reset_recovery();
        tc16_idle_stability();
        tc17_data_pattern_sweep();
        tc18_long_burst_stress();

        if (run_advanced_resets) begin
            tc19_write_domain_only_reset();
            tc20_read_domain_only_reset();
        end
        else begin
            phase("TC19/TC20 skipped by default");
            $display("Use +RUN_ADVANCED_RESETS only if per-domain reset behavior is part of the design contract.");
        end

        phase("Final result");
        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED with %0d error(s)", errors);

        #20;
        $finish;
    end

endmodule
