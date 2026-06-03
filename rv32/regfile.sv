import riscv_pkg::*;

module regfile (
    input logic i_clk,
    input logic i_rstn,
    input logic [NR_READ_PORTS-1:0][4:0] i_raddr,
    output logic [NR_READ_PORTS-1:0][XLEN-1:0] rdata_o,
    
    input logic [NR_WRITE_PORTS-1:0][4:0] i_waddr,
    input logic [NR_WRITE_PORTS-1:0][XLEN-1:0] i_wdata,
    input logic [NR_WRITE_PORTS-1:0] i_wr_en
);
    logic [XLEN-1:0] mem [0:REG_COUNT-1];

    // async read x0 hard0
    for (genvar rp = 0; rp < NR_READ_PORTS; rp++) begin : gen_rports
        assign rdata_o[rp] = (i_raddr[rp] == '0) ? '0 : mem[i_raddr[rp]];
    end

    // sync write
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            for (int i =0; i < REG_COUNT; i++) begin
                mem[i] <= '0;
            end
        end else begin
            for (int wrp = 0; wrp < NR_WRITE_PORTS; wrp++) begin
                if (i_wr_en[wrp] && i_waddr[wrp] != '0) begin
                    mem[i_waddr[wrp]] <= i_wdata[wrp];
                end
            end
        end
    end

endmodule
