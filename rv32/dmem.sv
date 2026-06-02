import riscv_pkg::*;

module dmem (
    input logic i_clk,
    input logic [XLEN-1:0] i_cpu_addr,
    input logic i_cpu_req,
    input logic i_cpu_we,
    input logic [3:0] i_cpu_wmask,
    input logic [XLEN-1:0] i_cpu_wdata,
    output logic [XLEN-1:0] o_cpu_rdata,
    output logic o_cpu_hit,

    input logic i_fill_valid,
    input logic [XLEN-1:0] i_fill_addr,
    input logic [XLEN-1:0] i_fill_data
);
    logic [8:0] cpu_index, fill_index;
    logic [20:0] cpu_tag, fill_tag;

    assign cpu_index = i_cpu_addr[10:2];
    assign cpu_tag = i_cpu_addr[31:11];
    assign fill_index = i_fill_addr[10:2];
    assign fill_tag = i_fill_addr[31:11];

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
    assign o_cpu_rdata = sram_data_out;

    // write port mux (priority: fillvalid > cpu store hit > idle)
    logic data_we;
    logic [3:0] data_wmask;
    logic [8:0] data_windex;
    logic [XLEN-1:0] data_wdata;

    always_comb begin
        if (i_fill_valid) begin
            // miss fill: override, full word write
            data_we = 1'b1;
            data_wmask = 4'b1111;
            data_windex = fill_index;
            data_wdata = i_fill_data;
        end else if (i_cpu_req && i_cpu_we && o_cpu_hit) begin
            // store hit: write to cache
            data_we = 1'b1;
            data_wmask = i_cpu_wmask;
            data_windex = cpu_index;
            data_wdata = i_cpu_wdata;
        end else begin
            // idle: no write
            data_we = 1'b0;
            data_wmask = 4'b0000;
            data_windex = '0;
            data_wdata = '0;
        end
    end

    logic [XLEN-1:0] tag_write_data;
    assign tag_write_data = {1'b1, 10'd0, fill_tag};

    sram_1rw1r_32x512 u_data_ram (
        .i_clk0   (i_clk),
        .i_csb0    (i_fill_valid),   // active-high, wrapper inverts
        .i_we0    (data_we),
        .i_wmask0 (data_wmask),
        .i_addr0  (data_windex),
        .i_din0   (data_wdata),
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
        .i_csb1 (i_cpu_req), // store needs tag check for hit
        .i_addr1  (cpu_index),
        .o_dout1  (sram_tag_out)
    );

endmodule
