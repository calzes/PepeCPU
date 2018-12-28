module decoder_3x8 (in, out, enable);

input enable;
input [2:0] in;
output [7:0] out;

logic [1:0] enable_int;

decoder_2x4 d1(.in(in[1:0]), .out(out[3:0]), .enable(enable_int[0]));
decoder_2x4 d2(.in(in[1:0]), .out(out[7:4]), .enable(enable_int[1]));

decoder_1x2 d_int (.in(in[2]), .out(enable_int), .enable(enable));

endmodule
