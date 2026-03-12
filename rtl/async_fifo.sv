module async_fifo #(
    parameter int DATA_W = 8,
    parameter int ADDR_W = 4
) (
    input  logic              wr_clk,
    input  logic              wr_rst_n,
    input  logic              rd_clk,
    input  logic              rd_rst_n,

    input  logic              wr_en,
    input  logic              rd_en,
    input  logic [DATA_W-1:0] wdata,
    output logic [DATA_W-1:0] rdata,

    output logic              full,
    output logic              empty
);

    localparam int DEPTH = (1 << ADDR_W);
    localparam int PTR_W = ADDR_W + 1;

    logic [DATA_W-1:0] mem [0:DEPTH-1];

    logic [PTR_W-1:0] wr_ptr_bin,  wr_ptr_bin_next;
    logic [PTR_W-1:0] wr_ptr_gray, wr_ptr_gray_next;

    logic [PTR_W-1:0] rd_ptr_bin,  rd_ptr_bin_next;
    logic [PTR_W-1:0] rd_ptr_gray, rd_ptr_gray_next;

    logic [PTR_W-1:0] rd_ptr_gray_sync_wr;
    logic [PTR_W-1:0] wr_ptr_gray_sync_rd;

    logic wr_fire;
    logic rd_fire;

    logic full_next;
    logic empty_next;

    function automatic logic [PTR_W-1:0] bin2gray(
        input logic [PTR_W-1:0] bin
    );
        bin2gray = (bin >> 1) ^ bin;
    endfunction

    function automatic logic is_full_next(
        input logic [PTR_W-1:0] wr_gray_next,
        input logic [PTR_W-1:0] rd_gray_sync
    );
        logic [PTR_W-1:0] rd_gray_inverted;
        begin
            rd_gray_inverted = rd_gray_sync;
            rd_gray_inverted[PTR_W-1] = ~rd_gray_sync[PTR_W-1];
            rd_gray_inverted[PTR_W-2] = ~rd_gray_sync[PTR_W-2];
            is_full_next = (wr_gray_next == rd_gray_inverted);
        end
    endfunction

    assign wr_fire = wr_en && !full;
    assign rd_fire = rd_en && !empty;

    assign wr_ptr_bin_next  = wr_ptr_bin + wr_fire;
    assign rd_ptr_bin_next  = rd_ptr_bin + rd_fire;

    assign wr_ptr_gray_next = bin2gray(wr_ptr_bin_next);
    assign rd_ptr_gray_next = bin2gray(rd_ptr_bin_next);

    assign full_next  = is_full_next(wr_ptr_gray_next, rd_ptr_gray_sync_wr);
    assign empty_next = (rd_ptr_gray_next == wr_ptr_gray_sync_rd);

    genvar i;
    generate
        for (i = 0; i < PTR_W; i++) begin : g_rdptr_into_wrclk
            sync_2ff #(
                .RESET_VALUE(1'b0)
            ) u_sync_rdptr_bit (
                .clk    (wr_clk),
                .rst_n  (wr_rst_n),
                .d_async(rd_ptr_gray[i]),
                .q_sync (rd_ptr_gray_sync_wr[i])
            );
        end

        for (i = 0; i < PTR_W; i++) begin : g_wrptr_into_rdclk
            sync_2ff #(
                .RESET_VALUE(1'b0)
            ) u_sync_wrptr_bit (
                .clk    (rd_clk),
                .rst_n  (rd_rst_n),
                .d_async(wr_ptr_gray[i]),
                .q_sync (wr_ptr_gray_sync_rd[i])
            );
        end
    endgenerate

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= '0;
            wr_ptr_gray <= '0;
            full        <= 1'b0;
        end else begin
            if (wr_fire) begin
                mem[wr_ptr_bin[ADDR_W-1:0]] <= wdata;
            end

            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
            full        <= full_next;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= '0;
            rd_ptr_gray <= '0;
            rdata       <= '0;
            empty       <= 1'b1;
        end else begin
            if (rd_fire) begin
                rdata <= mem[rd_ptr_bin[ADDR_W-1:0]];
            end

            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
            empty       <= empty_next;
        end
    end

endmodule