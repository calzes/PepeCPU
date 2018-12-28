module decoder_2x4 (in, out, enable);

input enable;
input [1:0] in;
output logic [3:0] out;

logic [1:0] enable_int;

decoder_1x2 d0 (.in(in[0]), .out(out[1:0]), .enable(enable_int[0]));
decoder_1x2 d1 (.in(in[0]), .out(out[3:2]), .enable(enable_int[1]));

decoder_1x2 d_int (.in(in[1]), .out(enable_int), .enable(enable));

endmodule

module decoder_2x4_testbench ();
    logic enable;
    logic [1:0] in;
    logic [3:0] out;

    integer i;

    decoder_2x4 dut (.in(in), .out(out), .enable(enable));

    initial begin
        enable = 1;
        for (i=0; i<4; i=i+1) begin
            in = i;
        end

        enable = 0;
        for (i=0; i<4; i=i+1) begin
            in = i;
        end
    end
endmodule
