`timescale 1ns/1ps

module async_fifo_reset_safe #(
    parameter int DATA_W = 8,
    parameter int ADDR_W = 4
) (
    input  logic              wr_clk,
    input  logic              wr_arst_n,
    input  logic              rd_clk,
    input  logic              rd_arst_n,

    input  logic              wr_en,
    input  logic              rd_en,
    input  logic [DATA_W-1:0] wdata,
    output logic [DATA_W-1:0] rdata,

    output logic              full,
    output logic              empty,

    output logic              wr_srst_n,
    output logic              rd_srst_n
);

    logic wr_srst_n_int;
    logic rd_srst_n_int;

    reset_sync u_reset_sync_wr (
        .clk    (wr_clk),
        .arst_n (wr_arst_n),
        .srst_n (wr_srst_n_int)
    );

    reset_sync u_reset_sync_rd (
        .clk    (rd_clk),
        .arst_n (rd_arst_n),
        .srst_n (rd_srst_n_int)
    );

    async_fifo #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W)
    ) u_fifo (
        .wr_clk   (wr_clk),
        .wr_rst_n (wr_srst_n_int),
        .rd_clk   (rd_clk),
        .rd_rst_n (rd_srst_n_int),
        .wr_en    (wr_en),
        .rd_en    (rd_en),
        .wdata    (wdata),
        .rdata    (rdata),
        .full     (full),
        .empty    (empty)
    );

    assign wr_srst_n = wr_srst_n_int;
    assign rd_srst_n = rd_srst_n_int;

endmodule