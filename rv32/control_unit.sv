import riscv_pkg::*;

module control_unit (
    input logic [XLEN-1:0] i_instr,
    output logic o_pc_src,
    output logic o_wb_en,
    output logic o_mem_wr,
    output logic [2:0] o_alu_op,
    output logic o_alu_src,
    output logic [1:0] o_imm_sel,
    output logic o_reg_write
);
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = i_instr[6:0];
    assign funct3 = i_instr[14:12];
    assign funct7 = i_instr[31:25];

    always_comb begin

    end


endmodule
