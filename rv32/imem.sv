// L1 cache for instruction memory
import riscv_pkg::*;


module imem (
    input  logic i_clk,
    // CPU fetch
    input  logic [XLEN-1:0] i_cpu_addr,
    input  logic i_cpu_req,
    output logic [XLEN-1:0] o_cpu_instr,
    output logic o_cpu_hit,

    // Cache fill from main memory
    input  logic        i_fill_valid,
    input  logic [XLEN-1:0] i_fill_addr,
    input  logic [XLEN-1:0] i_fill_data
);
    // tag: [31:11]
    // index: [10:2] (9bits = 512 words)
    // offset [1:0] (2bits)
    
    logic [8:0] cpu_index, fill_index;
    logic [20:0] cpu_tag, fill_tag;

    assign cpu_index = i_cpu_addr[10:2];
    assign cpu_tag = i_cpu_addr[31:11];
    assign fill_index = i_fill_addr[10:2];
    assign fill_tag = i_fill_addr[31:11];

    // tag compare (tag delayed by 1 cycle)
    logic [20:0] cpu_tag_r;
    always_ff @(posedge i_clk) begin
        if (i_cpu_req) begin
            cpu_tag_r <= cpu_tag;
        end else begin
            cpu_tag_r <= '0;
        end
    end

    logic [XLEN-1:0] sram_data_out, sram_tag_out;
    logic read_valid;
    logic [20:0] read_tag;
    assign read_valid = sram_tag_out[31];
    assign read_tag = sram_tag_out[20:0];

    assign o_cpu_hit = read_valid && (read_tag == cpu_tag_r);
    assign o_cpu_instr = sram_data_out;

    // sram write data
    logic [XLEN-1:0] tag_write_data;
    assign tag_write_data = {1'b1, 10'd0, fill_tag};

    sram_1rw1r_32x512 u_data_ram (
        .i_clk0   (i_clk),
        .i_csb0    (i_fill_valid),   // active-high, wrapper inverts
        .i_we0    (1'b1),           // when selected, always write
        .i_wmask0 (4'b1111),
        .i_addr0  (fill_index),
        .i_din0   (i_fill_data),
        .o_dout0  (),               // unused on write port

        .i_clk1   (i_clk),
        .i_csb1    (i_cpu_req),
        .i_addr1  (cpu_index),
        .o_dout1  (sram_data_out)
    );

    sram_1rw1r_32x512 u_tag_ram (
        .i_clk0   (i_clk),
        .i_csb0    (i_fill_valid),   // active-high, wrapper inverts
        .i_we0    (1'b1),           // when selected, always write
        .i_wmask0 (4'b1111),
        .i_addr0  (fill_index),
        .i_din0   (tag_write_data),
        .o_dout0  (),               // unused on write port

        .i_clk1   (i_clk),
        .i_csb1    (i_cpu_req),
        .i_addr1  (cpu_index),
        .o_dout1  (sram_tag_out)
    );

endmodule
