module sync_2ff #(
    parameter bit RESET_VALUE = 1'b0
) (
    input  logic clk,
    input  logic rst_n,
    input  logic d_async,
    output logic q_sync
);

    logic stage1;
    logic stage2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1 <= RESET_VALUE;
            stage2 <= RESET_VALUE;
        end else begin
            stage1 <= d_async;
            stage2 <= stage1;
        end
    end

    assign q_sync = stage2;

endmodule