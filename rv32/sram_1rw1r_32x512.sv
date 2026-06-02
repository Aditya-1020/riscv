module sram_1rw1r_32x512 (
    // Port 0: read/write
    input logic i_clk0,
    input logic i_csb0,
    input logic i_we0,
    input logic [3:0] i_wmask0,
    input logic [8:0] i_addr0,
    input  logic [31:0] i_din0,
    output logic [31:0] o_dout0,

    // port 1 REad
    input logic i_clk1,
    input logic i_csb1,
    input logic [8:0] i_addr1,
    output logic [31:0] o_dout1
);

    sky130_sram_2kbyte_1rw1r_32x512_8 u_sram (
    `ifdef USE_POWER_PINS
        .vccd1  (1'b1),
        .vssd1  (1'b0),
    `endif
        .clk0   (i_clk0),
        .csb0   (i_csb0),
        .web0   (i_we0),
        .wmask0 (i_wmask0),
        .addr0  (i_addr0),
        .din0   (i_din0),
        .dout0  (o_dout0),
        .clk1   (i_clk1),
        .csb1   (~i_csb1),
        .addr1  (i_addr1),
        .dout1  (o_dout1)
    );

endmodule
