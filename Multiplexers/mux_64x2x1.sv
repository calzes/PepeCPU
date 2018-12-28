module mux_64x2x1 (in, out, sel);

	input             sel;
	input    [63:0]   in     [1:0];
	output   [63:0]   out;

	logic    [1:0]    in_int [63:0];

	genvar i, j;
	generate
		for (i=0; i<2; i=i+1) begin
			for (j=0; j<64; j=j+1) begin
				buf (in_int[j][i], in[i][j]);
			end
		end
	endgenerate

	genvar k;
	generate
		for (k = 0; k < 64; k = k + 1) begin
			mux_2x1 a (.in(in_int[k]), .out(out[k]), .sel(sel));
		end
	endgenerate
endmodule
