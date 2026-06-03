import riscv_pkg::XLEN;

module mux4 (
    input logic [XLEN-1:0] i_in0,
    input logic [XLEN-1:0] i_in1,
    input logic [XLEN-1:0] i_in2,
    input logic [XLEN-1:0] i_in3,
    input logic [1:0] i_sel,
    output logic [XLEN-1:0] o_out
);
    always_comb begin
        case (i_sel)
            2'b00: o_out = i_in0;
            2'b01: o_out = i_in1;
            2'b10: o_out = i_in2;
            2'b11: o_out = i_in3;
            default: o_out = '0;
        endcase
    end
endmodule
