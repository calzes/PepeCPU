module mux_8x1(in, out, sel);

    input logic [7:0] in;
    input logic [2:0] sel;
    output logic out;

    logic m0_out, m1_out;

    // intermediate muxes
    mux_4x1 m0 (.in(in[3:0]), .sel(sel[1:0]), .out(m0_out));
    mux_4x1 m1 (.in(in[7:4]), .sel(sel[1:0]), .out(m1_out));

    // final 2:1 mux
    mux_2x1 m2 (.in({m1_out, m0_out}), .sel(sel[2]), .out(out));

endmodule
