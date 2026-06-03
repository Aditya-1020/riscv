import riscv_pkg::*;

module decoder (
    input logic [XLEN-1:0] i_instr,
    output opcode_e o_opcode,
    output logic [4:0] o_rs1,
    output logic [4:0] o_rs2,
    output logic [4:0] o_rd,
    output logic [2:0] o_funct3,
    output logic [6:0] o_funct7,
    output imm_sel_e o_imm_sel,
    output alu_op_e o_alu_op
);
    opcode_e opcode_r;

    assign opcode_r= opcode_e'(i_instr[6:0]);
    assign o_rs1 = i_instr[19:15];
    assign o_rs2 = i_instr[24:20];
    assign o_rd = i_instr[11:7];
    assign o_funct3 = i_instr[14:12];
    assign o_funct7 = i_instr[31:25];
    assign o_opcode = opcode_r;

    // immediate
    always_comb begin
        case (opcode_r)
            OPCODE_LOAD, OPCODE_OP_IMM, OPCODE_JALR, OPCODE_MISC_MEM, OPCODE_SYSEM: o_imm_sel = IMM_I;
            OPCODE_STORE: o_imm_sel = IMM_S;
            OPCODE_BRANCH: o_imm_sel = IMM_B;
            OPCODE_LUI, OPCODE_AUIPC: o_imm_sel = IMM_U;
            OPCODE_JAL: o_imm_sel = IMM_J;
            default: o_imm_sel = IMM_ZERO;
        endcase
    end

endmodule
