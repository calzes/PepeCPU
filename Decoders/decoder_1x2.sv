`timescale 1ns / 10ps

module decoder_1x2 (in, out, enable);

    input logic enable;
    input logic in;
    output logic [1:0] out;

    logic not_in;

    and #0.05 a1 (out[1], in, enable);
    not #0.05 invert(not_in, in);
    and #0.05 a2 (out[0], not_in, enable);

endmodule
