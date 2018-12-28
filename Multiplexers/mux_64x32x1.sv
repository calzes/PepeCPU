module mux_64x32x1 (in, out, sel);

	input [4:0] sel;
	input [63:0] in [31:0];
	output [63:0] out;

	logic [31:0] in_int [63:0];

	genvar i, j;
	generate
		for (i=0; i<32; i=i+1) begin
			for (j=0; j<64; j=j+1) begin
				buf (in_int[j][i], in[i][j]);
			end
		end
	endgenerate

	genvar k;
	generate
		for (k = 0; k < 64; k = k + 1) begin
			mux_32x1 a (.in(in_int[k]), .out(out[k]), .sel(sel));
		end
	endgenerate
endmodule
