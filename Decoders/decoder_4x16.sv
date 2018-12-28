module decoder_4x16 (in, out, enable);

input enable;
input [3:0] in;
output [15:0] out;

logic [1:0] enable_int;

decoder_3x8 d1(.in(in[2:0]), .out(out[7:0]), .enable(enable_int[0]));
decoder_3x8 d2(.in(in[2:0]), .out(out[15:8]), .enable(enable_int[1]));

decoder_1x2 d_int (.in(in[3]), .out(enable_int), .enable(enable));

endmodule
