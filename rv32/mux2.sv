import riscv_pkg::XLEN;

module mux2 (
    input logic [XLEN-1:0] a, 
    input logic [XLEN-1:0] b,
    input logic sel,
    output logic [XLEN-1:0] y
);
    assign y = sel ? b : a;

endmodule
