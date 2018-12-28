module enable_DFF (in, out, enable, clk);

    input logic in, enable, clk;
    output logic out;
    logic reg_in;

    mux_2x1 mux_ (.in({in, out}), .out(reg_in), .sel(enable));
    D_FF DFF_in (.d(reg_in), .q(out), .reset(1'b0), .clk(clk));

endmodule
