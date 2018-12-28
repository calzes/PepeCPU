module mux_4x1(in, out, sel);

    input logic [3:0] in;
    input logic [1:0] sel;
    output logic out;

    logic m0_out, m1_out;

    // intermediate muxes
    mux_2x1 m0 (.in(in[1:0]), .sel(sel[0]), .out(m0_out));
    mux_2x1 m1 (.in(in[3:2]), .sel(sel[0]), .out(m1_out));

    // final 2:1 mux
    mux_2x1 m2 (.in({m1_out, m0_out}), .sel(sel[1]), .out(out));

endmodule

// module mux_4x1_testbench();
//     logic [3:0] in;
//     logic [1:0] sel;
//     logic out;
//
//     mux_4x1 dut(.in(in), .sel(sel), .out(out));
//
//     integer i, j;
//     initial begin
//         for (i=0; i<4; i=i+1) begin
//             sel = i;
//             for (j=0; j<16; j=j+1) begin
//                 in = j;
//         end
//     end
//
// endmodule
