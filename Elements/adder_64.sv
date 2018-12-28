module adder_nbit #(parameter WIDTH=64)(A, B, sum, overflow, carry_out_msb, subtract);

    input logic  [(WIDTH-1):0] A, B;
    input logic                subtract;

    output logic [(WIDTH-1):0] sum;
    output logic               overflow;
    output logic               carry_out_msb;

    logic        [(WIDTH-1):0] carry;
    logic        [(WIDTH-1):0] b_in;

    assign carry_out_msb = carry[WIDTH-1];

    full_adder lsb (.A(A[0]),
                    .B(b_in[0]),
                    .sum_result(sum[0]),
                    .carry_in(subtract),
                    .carry_out(carry[0]));

    full_adder msb (.A(A[(WIDTH-1)]),
                    .B(b_in[(WIDTH-1)]),
                    .sum_result(sum[(WIDTH-1)]),
                    .carry_in(carry[WIDTH-2]),
                    .carry_out(carry[WIDTH-1]));

    xor of (overflow, carry[WIDTH-1], carry[WIDTH-2]);

    genvar i;
    generate
        for (i=0; i<WIDTH; i=i+1) begin
            xor b_input (b_in[i], B[i], subtract);
        end
        for (i=1; i<(WIDTH-1); i=i+1) begin
            full_adder add (.A(A[i]),
                            .B(b_in[i]),
                            .sum_result(sum[i]),
                            .carry_in(carry[i - 1]),
                            .carry_out(carry[i]));
        end
    endgenerate

endmodule
