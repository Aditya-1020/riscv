import riscv_pkg::*;

module pc (
    input logic i_clk,
    input logic i_rstn,
    input logic pc_src,
    input logic [XLEN-1:0] pc_target,
    output logic [XLEN-1:0] pc
);
    localparam [XLEN-1:0] BOOT_ADDR = 32'h8000_0000;

    logic [XLEN-1:0] pc_r, next_pc;
    assign pc = pc_r;

    always_comb begin
        if (pc_src) begin
            next_pc = pc_target;
        end else begin
            next_pc = pc_r + 32'd4;
        end
    end

    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            pc_r <= BOOT_ADDR;
        end else begin
            pc_r <= next_pc;
        end
    end


endmodule
