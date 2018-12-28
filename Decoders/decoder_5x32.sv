module decoder_5x32 (in, out, enable);

input enable;
input [4:0] in;
output [31:0] out;

logic [1:0] enable_int;

decoder_4x16 d1(.in(in[3:0]), .out(out[15:0]), .enable(enable_int[0]));
decoder_4x16 d2(.in(in[3:0]), .out(out[31:16]), .enable(enable_int[1]));

decoder_1x2 d_int (.in(in[4]), .out(enable_int), .enable(enable));

endmodule

module decoder_5x32_testbench ();
    logic enable;
    logic [4:0] in;
    logic [31:0] out;

    integer i;

    decoder_2x4 dut (.in(in), .out(out), .enable(enable));

    initial begin
        enable = 1;
        for (i=0; i<32; i=i+1) begin
            in = i;
        end

        enable = 0;
        for (i=0; i<32; i=i+1) begin
            in = i;
        end
    end
endmodule
