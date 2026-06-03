import riscv_pkg::*;

module control_unit (
    input  logic [XLEN-1:0]  i_instr,

    // outputs to datapath
    output logic o_pc_src, // 0=PC+4, 1=branch/jump target

    output logic o_reg_wr_en, // write enable for rd
    output imm_sel_e o_imm_sel, // selects immediate format

    output opa_sel_e o_opa_sel, // A operand: RS1 / PC / ZERO
    output opb_sel_e o_opb_sel, // B operand: RS2 / IMM / 4
    output alu_op_e o_alu_op, // ALU operation

    output logic o_mem_wr_en, // data memory write enable
    output logic [3:0] o_mem_wmask, // byte write mask (SB/SH/SW)
    output logic o_mem_rd_en, // data memory read enable

    output wb_sel_e o_wb_sel, // ALU / MEM / PC+4

    // Branch condition inputs (from ALU flags, evaluated here)
    input  logic i_alu_zero,
    input  logic i_alu_neg,
    input  logic i_alu_overflow,
    input  logic i_alu_carry
);

    function automatic alu_op_e decode_alu_r_type(
        input logic [2:0] funct3_in,
        input logic funct7_b5_in
    );
        case (funct3_in)
            F3_ADD_SUB: decode_alu_r_type = (funct7_b5_in) ? ALU_SUB : ALU_ADD;
            F3_SLL: decode_alu_r_type = ALU_SLL;
            F3_SLT: decode_alu_r_type = ALU_SLT;
            F3_SLTU: decode_alu_r_type = ALU_SLTU;
            F3_XOR: decode_alu_r_type = ALU_XOR;
            F3_SRL_SRA: decode_alu_r_type = (funct7_b5_in) ? ALU_SRA : ALU_SRL;
            F3_OR: decode_alu_r_type = ALU_OR;
            F3_AND: decode_alu_r_type = ALU_AND;
            default: decode_alu_r_type = ALU_ADD;
        endcase
    endfunction

    function automatic alu_op_e decode_alu_i_type(
        input logic [2:0] funct3_in,
        input logic instr_30
    );
        case (funct3_in)
            F3_ADD_SUB: decode_alu_i_type = ALU_ADD; // ADDI
            F3_SLL: decode_alu_i_type = ALU_SLL;
            F3_SLT: decode_alu_i_type = ALU_SLT;
            F3_SLTU: decode_alu_i_type = ALU_SLTU;
            F3_XOR: decode_alu_i_type = ALU_XOR;
            F3_SRL_SRA: decode_alu_i_type = (instr_30) ? ALU_SRA : ALU_SRL;
            F3_OR: decode_alu_i_type = ALU_OR;
            F3_AND: decode_alu_i_type = ALU_AND;
            default: decode_alu_i_type = ALU_ADD;
        endcase
    endfunction
    
    opcode_e opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [4:0] rs1, rs2, rd;
    // imm_sel_e imm_sel;
    logic f7_b5 = funct7[5];
    logic i_type_b30 = i_instr[30];

    decoder u_decoder (
        .i_instr(i_instr),
        .o_opcode(opcode),
        .o_rs1(rs1),
        .o_rs2(rs2),
        .o_rd(rd),
        .o_funct3(funct3),
        .o_funct7(funct7),
        .o_imm_sel(o_imm_sel)
    );

    always_comb begin
        o_reg_wr_en = 1'b0;
        o_mem_wr_en = 1'b0;
        o_mem_rd_en = 1'b0;
        o_pc_src = 1'b0;
        o_alu_op = ALU_ADD;
        o_opa_sel = OPA_RS1;
        o_opb_sel = OPB_RS2;
        o_wb_sel = WB_ALU;
        o_mem_wmask = 4'b0000;

        unique case (opcode)
            OPCODE_OP: begin
                o_reg_wr_en = 1'b1;
                o_opa_sel = OPA_RS1;
                o_opb_sel = OPB_RS2;
                o_wb_sel = WB_ALU;
                o_alu_op = decode_alu_r_type(funct3, f7_b5);
            end

            OPCODE_OP_IMM: begin
                o_reg_wr_en = 1'b1;
                o_opa_sel = OPA_RS1;
                o_opb_sel = OPB_IMM;
                o_wb_sel = WB_ALU;
                o_alu_op = decode_alu_i_type(funct3, i_type_b30);
            end

            OPCODE_LOAD: begin
                o_reg_wr_en = 1'b1;
                o_opa_sel = OPA_RS1;
                o_opb_sel = OPB_IMM;
                o_mem_rd_en = 1'b1;
                o_wb_sel = WB_MEM;
                o_alu_op = ALU_ADD;  // address = rs1 + imm
            end

            OPCODE_STORE: begin
                o_opa_sel = OPA_RS1;
                o_opb_sel = OPB_IMM;
                o_mem_wr_en = 1'b1;
                o_alu_op = ALU_ADD;
                case (funct3)
                    F3_SB: o_mem_wmask = 4'b0001;
                    F3_SH: o_mem_wmask = 4'b0011;
                    F3_SW: o_mem_wmask = 4'b1111;
                    default: o_mem_wmask = 4'b0000;
                endcase
            end

            OPCODE_BRANCH: begin
                o_opa_sel = OPA_RS1;
                o_opb_sel = OPB_RS2;
                o_alu_op = ALU_SUB;
                case (funct3)
                    F3_BEQ: o_pc_src = i_alu_zero;
                    F3_BNE: o_pc_src = !i_alu_zero;
                    F3_BLT: o_pc_src = i_alu_neg;
                    F3_BGE: o_pc_src = !i_alu_neg || i_alu_zero;
                    default: o_pc_src = 1'b0;
                endcase
            end

            OPCODE_LUI: begin
                o_reg_wr_en = 1'b1;
                o_opa_sel = OPA_ZERO;
                o_opb_sel = OPB_IMM;
                o_alu_op = ALU_PASS_B;
                o_wb_sel = WB_ALU;
            end

            OPCODE_AUIPC: begin
                o_reg_wr_en = 1'b1;
                o_opa_sel = OPA_PC;
                o_opb_sel = OPB_IMM;
                o_alu_op = ALU_ADD;
                o_wb_sel = WB_ALU;
            end

            OPCODE_JAL: begin
                o_reg_wr_en = 1'b1;
                o_opa_sel = OPA_PC;
                o_opb_sel = OPB_IMM;
                o_alu_op = ALU_ADD;  // branch target = PC + imm
                o_wb_sel = WB_PC4;
                o_pc_src = 1'b1;
            end

            OPCODE_JALR: begin
                o_reg_wr_en = 1'b1;
                o_opa_sel = OPA_RS1;
                o_opb_sel = OPB_IMM;
                o_alu_op = ALU_ADD;  // branch target = rs1 + imm
                o_wb_sel = WB_PC4;
                o_pc_src = 1'b1;
            end
        endcase
    end


endmodule
