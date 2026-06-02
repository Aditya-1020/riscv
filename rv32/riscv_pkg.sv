// File: rv32im_pkg.sv
package riscv_pkg;

  // Architectural Constants
  localparam int XLEN = 32;
  localparam int REG_ADDR_WIDTH = 5;
  localparam int REG_COUNT = 32;

  // regfile
  localparam int NR_READ_PORTS = 2;
  localparam int NR_WRITE_PORTS = 1;


  // Base Opcodes (Bits [6:0])
  typedef enum logic [6:0] {
    OPCODE_LOAD     = 7'b0000011, // I-Type: lb, lh, lw, lbu, lhu
    OPCODE_LOAD_FP  = 7'b0000111, // (Not used in RV32IM, here for completeness)
    OPCODE_MISC_MEM = 7'b0001111, // I-Type: fence, fence.i
    OPCODE_OP_IMM   = 7'b0010011, // I-Type: addi, slti, xori, ori, andi, slli, srli, srai
    OPCODE_AUIPC    = 7'b0010111, // U-Type: auipc
    OPCODE_STORE    = 7'b0100011, // S-Type: sb, sh, sw
    OPCODE_STORE_FP = 7'b0100111, // (Not used in RV32IM)
    OPCODE_AMO      = 7'b0101111, // (A-Extension, not used here)
    OPCODE_OP       = 7'b0110011, // R-Type: add, sub, sll, slt, xor, srl, sra, or, and (Plus M-Ext)
    OPCODE_LUI      = 7'b0110111, // U-Type: lui
    OPCODE_BRANCH   = 7'b1100011, // B-Type: beq, bne, blt, bge, bltu, bgeu
    OPCODE_JALR     = 7'b1100111, // I-Type: jalr
    OPCODE_JAL      = 7'b1101111, // J-Type: jal
    OPCODE_SYSTEM   = 7'b1110011  // I-Type: ecall, ebreak, CSRRx
  } opcode_e;

  // Funct3 Codes (Bits [14:12])
  
  // Branch
  localparam logic [2:0] F3_BEQ  = 3'b000;
  localparam logic [2:0] F3_BNE  = 3'b001;
  localparam logic [2:0] F3_BLT  = 3'b100;
  localparam logic [2:0] F3_BGE  = 3'b101;
  localparam logic [2:0] F3_BLTU = 3'b110;
  localparam logic [2:0] F3_BGEU = 3'b111;

  // Load 
  localparam logic [2:0] F3_LB  = 3'b000;
  localparam logic [2:0] F3_LH  = 3'b001;
  localparam logic [2:0] F3_LW  = 3'b010;
  localparam logic [2:0] F3_LBU = 3'b100;
  localparam logic [2:0] F3_LHU = 3'b101;

  // Store 
  localparam logic [2:0] F3_SB = 3'b000;
  localparam logic [2:0] F3_SH = 3'b001;
  localparam logic [2:0] F3_SW = 3'b010;

  // ALU Operations (OP and OP-IMM)
  localparam logic [2:0] F3_ADD_SUB = 3'b000; // ADD/SUB/ADDI
  localparam logic [2:0] F3_SLL     = 3'b001;
  localparam logic [2:0] F3_SLT     = 3'b010;
  localparam logic [2:0] F3_SLTU    = 3'b011;
  localparam logic [2:0] F3_XOR     = 3'b100;
  localparam logic [2:0] F3_SRL_SRA = 3'b101; // SRL/SRA/SRLI/SRAI
  localparam logic [2:0] F3_OR      = 3'b110;
  localparam logic [2:0] F3_AND     = 3'b111;

  // M-Extension Operations (OP with funct7 == 7'b0000001)
  localparam logic [2:0] F3_MUL    = 3'b000;
  localparam logic [2:0] F3_MULH   = 3'b001;
  localparam logic [2:0] F3_MULHSU = 3'b010;
  localparam logic [2:0] F3_MULHU  = 3'b011;
  localparam logic [2:0] F3_DIV    = 3'b100;
  localparam logic [2:0] F3_DIVU   = 3'b101;
  localparam logic [2:0] F3_REM    = 3'b110;
  localparam logic [2:0] F3_REMU   = 3'b111;

  // System (CSR)
  localparam logic [2:0] F3_CSRRW  = 3'b001;
  localparam logic [2:0] F3_CSRRS  = 3'b010;
  localparam logic [2:0] F3_CSRRC  = 3'b011;
  localparam logic [2:0] F3_CSRRWI = 3'b101;
  localparam logic [2:0] F3_CSRRSI = 3'b110;
  localparam logic [2:0] F3_CSRRCI = 3'b111;

  // Internal Execution Enums
  typedef enum logic [3:0] {
    ALU_ADD    = 4'd0,
    ALU_SUB    = 4'd1,
    ALU_SLL    = 4'd2,
    ALU_SRL    = 4'd3,
    ALU_SRA    = 4'd4,
    ALU_AND    = 4'd5,
    ALU_OR     = 4'd6,
    ALU_XOR    = 4'd7,
    ALU_SLT    = 4'd8,
    ALU_SLTU   = 4'd9,
    ALU_PASS_B = 4'd10
  } alu_op_e;

  typedef enum logic [3:0] {
    MD_MUL,
    MD_MULH,
    MD_MULHSU,
    MD_MULHU,
    MD_DIV,
    MD_DIVU,
    MD_REM,
    MD_REMU
  } muldiv_op_e;
  
  typedef enum logic [2:0] {
    IMM_I,   // I-Type: loads, arithmetic immediate, jalr
    IMM_S,   // S-Type: stores
    IMM_B,   // B-Type: branches
    IMM_U,   // U-Type: lui, auipc
    IMM_J,   // J-Type: jal
    IMM_ZERO // R-Type: no immediate needed
  } imm_sel_e;

  // ALU operand A source
  typedef enum logic [1:0] {
    OPA_RS1,   // normal register operand
    OPA_PC,    // AUIPC, JAL, JALR
    OPA_ZERO   // LUI (add 0 + imm)
  } opa_sel_e;

  // ALU operand B source
  typedef enum logic [1:0] {
    OPB_RS2,   // R-Type
    OPB_IMM,   // I/S/B/U/J-Type
    OPB_FOUR   // PC+4 for JAL/JALR return address
  } opb_sel_e;

  // Result writeback source
  typedef enum logic [1:0] {
    WB_ALU,    // normal ALU result
    WB_MEM,    // load data from memory
    WB_PC4     // PC+4 for JAL/JALR
  } wb_sel_e;


  // Instruction Formats
  typedef struct packed {
    logic [6:0] funct7;
    logic [4:0] rs2;
    logic [4:0] rs1;
    logic [2:0] funct3;
    logic [4:0] rd;
    opcode_e    opcode; // instr[6:0]
  } instr_r_t;

  typedef struct packed {
    logic [11:0] imm_11_0;
    logic [4:0]  rs1;
    logic [2:0]  funct3;
    logic [4:0]  rd;
    opcode_e     opcode;
  } instr_i_t;

  typedef struct packed {
    logic [6:0]  imm_11_5;
    logic [4:0]  rs2;
    logic [4:0]  rs1;
    logic [2:0]  funct3;
    logic [4:0]  imm_4_0;
    opcode_e     opcode;
  } instr_s_t;

  typedef struct packed {
    logic        imm_12;
    logic [5:0]  imm_10_5;
    logic [4:0]  rs2;
    logic [4:0]  rs1;
    logic [2:0]  funct3;
    logic [3:0]  imm_4_1;
    logic        imm_11;
    opcode_e     opcode;
  } instr_b_t;

  typedef struct packed {
    logic [19:0] imm_31_12;
    logic [4:0]  rd;
    opcode_e     opcode;
  } instr_u_t;

  typedef struct packed {
    logic        imm_20;
    logic [9:0]  imm_10_1;
    logic        imm_11;
    logic [7:0]  imm_19_12;
    logic [4:0]  rd;
    opcode_e     opcode;
  } instr_j_t;

endpackage : riscv_pkg
