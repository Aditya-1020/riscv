import riscv_pkg::*;

module imm_ext (
    input logic [XLEN-1:0] i_instr,
    input imm_sel_e i_imm_sel,
    output logic [XLEN-1:0] o_imm
);
    instr_i_t i_fmt;
    instr_s_t s_fmt;
    instr_b_t b_fmt;
    instr_u_t u_fmt;
    instr_j_t j_fmt;

    assign i_fmt = instr_i_t'(i_instr);
    assign s_fmt = instr_s_t'(i_instr);
    assign b_fmt = instr_b_t'(i_instr);
    assign u_fmt = instr_u_t'(i_instr);
    assign j_fmt = instr_j_t'(i_instr);

    always_comb begin
        o_imm = '0;
        unique case (i_imm_sel)
            IMM_I: o_imm = { {20{i_fmt.imm_11_0[11]}}, i_fmt.imm_11_0 };
            IMM_S: o_imm = { {20{s_fmt.imm_11_5[6]}}, s_fmt.imm_11_5, s_fmt.imm_4_0 };
            IMM_B: o_imm = { {19{b_fmt.imm_12}}, b_fmt.imm_12, b_fmt.imm_11, b_fmt.imm_10_5, b_fmt.imm_4_1, 1'b0 };
            IMM_U: o_imm = { u_fmt.imm_31_12, 12'b0 };
            IMM_J: o_imm = { {11{j_fmt.imm_20}}, j_fmt.imm_20, j_fmt.imm_19_12, j_fmt.imm_11, j_fmt.imm_10_1, 1'b0 };
            IMM_ZERO: o_imm = '0;
            default: o_imm = '0;
        endcase
    end

endmodule
