module register(
    input logic              clk, write_enable, //reset,
    input logic   [63:0]     data_in,
    output logic  [63:0]     data_out
    );
    logic     		write_enable_int;
    logic     [63:0]     data;

    logic ground;
    // 64 D flip-flops to hold each bit of data
    assign ground = 1'b0;

    genvar i;
    generate
        for (i=0; i<64; i++) begin
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

module register_testbench();
    logic              clk, write_enable;//, reset;
    logic   [63:0]     data_in;
    logic   [63:0]     data_out;

    parameter ClockDelay = 5000;

    register dut(.clk, .write_enable, /*.reset, */.data_in, .data_out);
    initial begin // Set up the clock
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end
	    //reset = 1;
	    //reset = 0;
	    //test changes in data_in but not enable. No change should be seen
    initial begin
	    write_enable = 0;
	    data_in = 0;
        @(posedge clk);
        @(posedge clk);
	    data_in = 1;
        @(posedge clk);
        @(posedge clk);
	    write_enable = 1;
        @(posedge clk);
        @(posedge clk);
	    //We should see some change now
	    data_in = 1;
        @(posedge clk);
        @(posedge clk);
	    data_in = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        $stop;
    end
endmodule
