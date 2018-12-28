module bit_slice (A, B, carry_in, subtract, cntrl, carry_out, result);

input logic  A, B, carry_in, subtract;
input logic [2:0] cntrl;
output logic carry_out, result;

logic        not_b, B_int;
logic [7:0]  mux_in;

full_adder add (.carry_in(carry_in),
                .A(A),
                .B(B_int),
                .sum_result(mux_in[2]),
                .carry_out(carry_out));

buf bit_buf (mux_in[0], B);
buf add_sub (mux_in[3], mux_in[2]);
and bit_and (mux_in[4], A, B);
or bit_or   (mux_in[5], A, B);
xor bit_xor (mux_in[6], A, B);

not nb (not_b, B);

mux_2x1 add_or_sub (.in({not_b, B}), .out(B_int), .sel(subtract));
mux_8x1 slice_result (.in(mux_in), .out(result), .sel(cntrl));

endmodule
