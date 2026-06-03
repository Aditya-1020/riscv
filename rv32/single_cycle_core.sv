import riscv_pkg::*;

module single_cycle_core (
    input logic clk,
    input logic rst_n
);
    logic [XLEN-1:0] pc, instr;
    logic [XLEN-1:0] pc_target;
    
    pc pc_inst (
        .i_clk(clk),
        .i_rstn(rst_n),
        .pc_src(), // control
        .pc_target(),
        .pc(pc)
    );

    imem imem_inst (
        .i_clk(clk),
        .i_cpu_addr(),
        .i_cpu_req(),
        .o_cpu_instr(),
        .o_cpu_hit(),
        .i_fill_valid(),
        .i_fill_addr(),
        .i_fill_data()
    );
    
    regfile regfile_inst (
        .i_clk(clk),
        .i_rstn(rst_n),
        .i_raddr(),
        .rdata_o(),
        .i_waddr(),
        .i_wdata(),
        .i_wr_en()
    );

    imm_ext imm_ext_inst (
        .i_instr(),
        .i_imm_sel(),
        .o_imm()
    );

    

endmodule
