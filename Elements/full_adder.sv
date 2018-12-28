`timescale 1ns / 10ps

module full_adder(carry_in, A, B, sum_result, carry_out);
	input logic carry_in, A, B;
	output logic sum_result, carry_out;

	logic a_xor_b;
	logic a_and_b;
	logic cin_ab;

	xor #0.05 ab (a_xor_b, A, B);
	xor #0.05 sum (sum_result, a_xor_b, carry_in);

	and #0.05 a_b (a_and_b, A, B);
	and #0.05 cin_ab1(cin_ab, carry_in, a_xor_b);

	or #0.05 carry (carry_out, a_and_b, cin_ab);


endmodule
