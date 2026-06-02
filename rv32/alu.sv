`timescale 1ps/1ps
import riscv_pkg::*;

module alu (
    input logic [XLEN-1:0] i_a,
    input logic [XLEN-1:0] i_b,
    input alu_op_e i_op,
    output logic [XLEN-1:0] o_result,
    output logic o_zero,
    output logic o_invalid_op,
    output logic o_overflow,
    output logic o_carry,
    output logic o_borrow
);
    localparam int SHAMT_WIDTH = $clog2(XLEN);

    logic [SHAMT_WIDTH-1:0] shamt;
    logic [XLEN:0] add_ext;
    logic [XLEN:0] sub_ext;

    assign shamt = i_b[SHAMT_WIDTH-1:0];
    assign add_ext = {1'b0, i_a} + {1'b0, i_b};   // XLEN+1 = 33 bits, no truncation
    assign sub_ext = {1'b0, i_a} - {1'b0, i_b};   // borrow = sub_ext[XLEN]

    logic add_overflow, sub_overflow;
    assign add_overflow = (~i_a[XLEN-1] & ~i_b[XLEN-1] &  add_ext[XLEN-1]) | ( i_a[XLEN-1] &  i_b[XLEN-1] & ~add_ext[XLEN-1]);
    assign sub_overflow = ( i_a[XLEN-1] & ~i_b[XLEN-1] & ~sub_ext[XLEN-1]) | (~i_a[XLEN-1] &  i_b[XLEN-1] &  sub_ext[XLEN-1]);

    logic slt_result, sltu_result;
    assign slt_result = sub_ext[XLEN-1] ^ sub_overflow;
    assign sltu_result = sub_ext[XLEN];

    logic [XLEN-1:0] result_r;

    always_comb begin
        result_r = '0;
        o_carry = 1'b0;
        o_overflow = 1'b0;
        o_borrow = 1'b0;
        o_invalid_op = 1'b0;

        case (i_op)
            ALU_ADD: begin
                result_r = add_ext[XLEN-1:0];
                o_carry = add_ext[XLEN];
                o_overflow = add_overflow;
            end
            ALU_SUB: begin
                result_r = sub_ext[XLEN-1:0];
                o_carry = sub_ext[XLEN];
                o_overflow = sub_overflow;
            end
            ALU_SLL: result_r = i_a << shamt;
            ALU_SRL: result_r = i_a >> shamt;
            ALU_SRA: result_r = $signed(i_a) >> shamt;
            ALU_AND: result_r = i_a & i_b;
            ALU_OR: result_r = i_a | i_b;
            ALU_XOR: result_r = i_a ^ i_b;
            ALU_SLT: result_r = {{XLEN-1{1'b0}}, slt_result};
            ALU_SLTU: result_r = {{XLEN-1{1'b0}}, sltu_result};
            ALU_PASS_B: result_r = i_b;
            default: o_invalid_op = 1'b1;
        endcase
    end

    assign o_result = result_r;
    assign o_zero = ~|result_r; // all bits 0

endmodule
