module mux_32x1(in, out, sel);

    input logic [31:0] in;
    input logic [4:0] sel;
    output logic out;

    logic m0_out, m1_out;

    // intermediate muxes (size log2(n-1))
    mux_16x1 m0 (.in(in[15:0]), .sel(sel[3:0]), .out(m0_out));
    mux_16x1 m1 (.in(in[31:16]), .sel(sel[3:0]), .out(m1_out));

    // final 2:1 mux
    mux_2x1 m2 (.in({m1_out, m0_out}), .sel(sel[4]), .out(out));
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
//         for (i=0; i<32; i=i+1) begin
//             sel = i;
//             // don't really want to test 2^32 possiblities
//             for (j=0; j<1000; j=j+1) begin
//                 in = j;
//         end
//     end
// endmodule
