module register_nbit #(parameter WIDTH=64) (
    input logic              clk, write_enable,
    input logic   [WIDTH-1:0]     data_in,
    output logic  [WIDTH-1:0]     data_out
    );
    logic     		write_enable_int;
    logic     [WIDTH-1:0]     data;

    logic ground;
    // 64 D flip-flops to hold each bit of data
    assign ground = 1'b0;

    genvar i;
    generate
        for (i=0; i<WIDTH; i++) begin
            D_FF reg_ffs (
                .q(data_out[i]),
                .d(data[i]),
                .clk(clk),
                .reset(ground)
            );
            mux_2x1 m (.in({data_in[i], data_out[i]}), .out(data[i]), .sel(write_enable)); //concat issues?
        end
    endgenerate

endmodule
