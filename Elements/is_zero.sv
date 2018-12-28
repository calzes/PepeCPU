`timescale 1ns / 10ps

module is_zero (in, zero);

    input logic [63:0] in;
    output logic       zero;

    // 4 input gates are allowed: 64 -> 16 -> 4 -> 1

    logic [15:0] layer_1;
    logic [3:0]  layer_2;
    logic        layer_3;

    genvar i;
    generate
        // First layer: squeezes 64 bits to 16 bits, propogating ones
        for (i=0; i<16; i=i+1) begin
            or #0.05 L_1 (layer_1[i], in[4*i], in[4*i+1], in[4*i+2], in[4*i+3]);
        end

        // Second Layer squeezes 16 bits to 4 bits
        for(i=0; i<4; i=i+1) begin
            or #0.05 L_2 (layer_2[i], layer_1[4*i], layer_1[4*i+1], layer_1[4*i+2], layer_1[4*i+3]);
        end
    endgenerate

    // Takes in remaining bits and converts to one bit
    or #0.05 not_zero (layer_3, layer_2[0], layer_2[1], layer_2[2], layer_2[3]);

    // Flips result: if one was in input, result is zero. No one: one.
    nor #0.05 result (zero, layer_3);

endmodule
