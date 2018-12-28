`timescale 1ns / 10ps

module mux_2x1(in, out, sel);

    input logic [1:0] in;
    input logic sel;
    output logic out;

    logic int_0, int_1;
    logic not_sel;

    not #0.05 invert (not_sel, sel);
    and #0.05 a1 (int_0, in[0], not_sel);
    and #0.05 a2 (int_1, in[1], sel);
    or #0.05 o1 (out, int_0, int_1);
    /*
    always_comb begin
        int_0 = in[0] & ~sel;
        int_1 = in[1] & sel;

        out = int_0 | int_1;
    end
    */
endmodule
