module instruction_stuff(BrTaken, UncondBr, instruction, CondAddr19, BrAddr26, clk, reset);
	input logic 		    BrTaken, UncondBr, clk, reset;
	input logic 	[18:0] 	CondAddr19;
	input logic     [25:0] 	BrAddr26;
	output logic 	[31:0]  instruction;

	logic [63:0] new_instruction_addr_norm; //
	logic [63:0] new_instruction_addr_jump; //
	logic [63:0] unmodified_instruction_addr; //Right out of the PC
	logic [63:0] new_instruction_official;
	logic [63:0] pc_in; //Feedback loop into PC

	logic [63:0] CondAddr64;
	logic [63:0] BrAddr64;
	logic [63:0] housekeeping [1:0];

	assign housekeeping[0] = CondAddr64;
	assign housekeeping[1] = BrAddr64;

	logic [63:0] ind_address; //BRANCH ADDRESS AFTER THE CondAddr AND BrAddr MUX. THIS WILL BE PUT INTO 4 BIT ADDER LATER

	//Sign extend
	assign CondAddr64 = {{ 43{CondAddr19[18]}}, CondAddr19[18:0], 2'b00};
	assign BrAddr64 = {{36{BrAddr26[25]}}, BrAddr26[25:0], 2'b00};

	logic [63:0] reset_register [1:0];
	assign reset_register[0] = new_instruction_official;
	assign reset_register[1] = 64'b0;
	mux_64x2x1 reset_mux (.in(reset_register), .out(pc_in), .sel(reset));

	logic [63:0] prev_instruction_addr;
	register instruction_prev(.clk(clk),
						 	              .write_enable(1'b1),
						                .data_in(unmodified_instruction_addr),
					                	.data_out(prev_instruction_addr));


	//Branch or condition mux
	mux_64x2x1 br_or_cond(.in(housekeeping), .out(ind_address), .sel(UncondBr));

	//Add the branch/true condition address (ind_address) to the PC
	adder_nbit add_branch_pc(.A(ind_address), .B(prev_instruction_addr), .sum(new_instruction_addr_jump), .carry_out_msb(), .overflow(), .subtract(1'b0));

	//PC instantiation.
	register p_c(.write_enable(1'b1),.data_in(pc_in), .data_out(unmodified_instruction_addr), .clk(clk));

	//Add 4 to the PC in the regular/false condition case
	adder_nbit add_pc_4 (.A(64'd4) , .B(unmodified_instruction_addr), .sum(new_instruction_addr_norm), .carry_out_msb(), .overflow(), .subtract(1'b0));

	//Inside goes
	instructmem instructmem_ (.address(unmodified_instruction_addr),  .instruction(instruction), .clk(clk)); //Check inputs later


	/*******************/
	/***Final Decision**/
	/*******************/

	logic [63:0] housekeeping1 [1:0];
	assign housekeeping1[0] = new_instruction_addr_norm;
	assign housekeeping1[1] = new_instruction_addr_jump;
	mux_64x2x1 ultimate_mux(.in(housekeeping1), .out(new_instruction_official), .sel(BrTaken));

endmodule
