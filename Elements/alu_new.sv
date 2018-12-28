`timescale 1ns / 10ps

module alu (A, B, cntrl, result, negative, zero, overflow, carry_out);

	input logic  [63:0]  A, B;
 	input logic  [2:0]   cntrl;

 	output logic [63:0]  result;
	output logic         negative, zero, overflow, carry_out;

	logic [63:0] carry;

	genvar i;
	generate
		for (i=1; i<64; i=i+1) begin
			bit_slice bits (.A(A[i]),
			                .B(B[i]),
							.carry_in(carry[i-1]),
							.subtract(cntrl[0]),
							.cntrl(cntrl),
							.carry_out(carry[i]),
							.result(result[i]));
		end
	endgenerate

	bit_slice lsb  (.A(A[0]),
					.B(B[0]),
					.carry_in(cntrl[0]),
					.subtract(cntrl[0]),
					.cntrl(cntrl),
					.carry_out(carry[0]),
					.result(result[0]));

	buf neg_buf        (negative, result[63]);
	buf c_out          (carry_out, carry[63]);
	xor overflow_test  (overflow, carry[63], carry[62]);
	is_zero zero_test  (.in(result), .zero(zero));

endmodule
