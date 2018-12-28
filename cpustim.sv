`timescale 1ns/10ps

module cpustim();

	parameter ClockDelay = 1000000000;

	// =====================================================
	// Declare input and output signals from the module here
	// =====================================================
	logic		clk, reset;




	// ==================================
	// Instantiate the module in question
	// ==================================
	Pipelined_CPU dut (clk, reset);

	// Force %t's to print in a nice format.
	initial $timeformat(-9, 2, " ns", 10);

	// Integer for iterating
	integer i;

	// ===========================================================
	// Set up the clock if sequential circuit (comment out if not)
	// ===========================================================
	initial begin
		clk <= 0;
		reset <= 1;
		forever #(ClockDelay/2) clk <= ~clk;
	end

	initial begin
	// ===========================================================
	// Set up logic here (use #(delay) or @(posedge clock))
	// ===========================================================
			@(posedge clk);
			reset <= 0;
			for (int i = 0; i < 1500; i++) begin
				@(posedge clk);
			end
			$stop;

  end
endmodule
