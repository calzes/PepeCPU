module Pipelined_CPU (clk, reset);
    input logic clk, reset;

/**** Control Logic Signals ****/
    logic [2:0]  ALUOp;
    logic        Reg2Loc,
                 RegWrite,
                 ALUSrc,
                 MemWrite,
                 MemToReg,
                 Shift,
                 ImSrc,
                 SetFlags,
                 UncondBr,
                 BrTaken;
    logic [5:0]  shamt; // shift amount for LSR
    logic [11:0] ALU_Imm12; // immediate for ADDI
    logic [8:0]  DAddr9;  // Store Address
    logic [4:0]  Rd, Rm, Rn; // Registers for RegFile in
    logic [18:0] CondAddr19;
    logic [25:0] BrAddr26;
    logic [31:0] instruction;
    logic        Db_zero, zero, negative, overflow, carry_out;
    logic        zero_alu, overflow_alu, negative_alu, carry_out_alu;
    logic        zero_store, overflow_store, negative_store, carry_out_store;
    logic [63:0] Da, Db;

    ///////////////////////////////////
    //////// Instruction Fetch  ///////
    ///////////////////////////////////

    /* Input: New Instruction
     * Outputs: Old Instruction
     */
     instruction_stuff i_path(.BrTaken(BrTaken),
                              .UncondBr(UnCondBr),
                              .CondAddr19(CondAddr19),
                              .BrAddr26(BrAddr26),
                              .instruction(instruction),
                              .clk(clk),
                              .reset(reset));

    logic [31:0] IF_instruction;
    register_nbit #(.WIDTH(32)) IF_output
                                  (.clk(clk),
                                   .write_enable(1'b1),
                                   .data_in(instruction),
                                   .data_out(IF_instruction));

    ///////////////////////////////////
    ///////// Register/Decode  ////////
    ///////////////////////////////////

     control control_ ( // Inputs
                       .instruction(IF_instruction),
                       .Db_zero(Db_zero),
                       .zero(zero), .negative(negative), .overflow(overflow), .carry_out(carry_out),

                       // Instruction/Fetch (Stage 1, No Passes)
                       .UncondBr(UnCondBr),
                       .BrTaken(BrTaken), //Outputs BrTaken for the next instruction. At this point at the delay slot
                       .CondAddr19(CondAddr19),
                       .BrAddr26(BrAddr26),

                       // Register/Decode (Stage 2, No Passes)
                       .Reg2Loc(Reg2Loc), .ALUSrc(ALUSrc), .ImSrc(ImSrc),
                       .Rd(Rd), .Rn(Rn), .Rm(Rm), // Forwarding?
                       .ALU_Imm12(ALU_Imm12), .DAddr9(DAddr9),

                       // Execute (Stage 3, 1 Pass)
                       .ALUOp(ALUOp),
                       .shamt(shamt),
                        .SetFlags(SetFlags),

                       // Data Memory (Stage 4, 2 Passes)
                       .MemWrite(MemWrite),
                       .MemToReg(MemToReg),
                       .Shift(Shift),

                       // Writeback (Stage 5, 3 Passes)
                       .RegWrite(RegWrite));

     // Reg2Loc Mux
     logic [4:0] Reg2Loc_in  [1:0];
     logic [4:0] Reg2Loc_out;
     assign Reg2Loc_in[0] = Rd;
     assign Reg2Loc_in[1] = Rm;
     mux_5x2x1 Reg2Loc_mux   (.in(Reg2Loc_in), .out(Reg2Loc_out), .sel(Reg2Loc));

     // Define the writeback signals
     logic [63:0] DM_ToWrite;
     logic DM_RegWrite;
     logic [4:0] DM_Rd;

     regfile regfile_ (.ReadData1(Da),
                       .ReadData2(Db),
                       .WriteData(DM_ToWrite),
                       .ReadRegister1(Rn),
                       .ReadRegister2(Reg2Loc_out),
                       .WriteRegister(DM_Rd),
                       .RegWrite(DM_RegWrite),
                       .clk(~clk));

    // ImSrc Mux
    logic [63:0] ImSrc_in    [1:0];
    logic [63:0] ImSrc_out;
    assign ImSrc_in[0] = {{55{DAddr9[8]}}, DAddr9};
    assign ImSrc_in[1] = {{52{1'b0}}, ALU_Imm12};
    mux_64x2x1 ImSrc_mux    (.in(ImSrc_in), .out(ImSrc_out), .sel(ImSrc));

    // Logic for forwarding
    logic [4:0] RD_Rd, EX_Rd;
    logic forward_EX_A, forward_EX_B;
    logic forward_MEM_A, forward_MEM_B;
    logic EX_RegWrite, RD_RegWrite;

    forwarding forwarding_boi(.ALU_write(RD_Rd),
                              .Mem_write(EX_Rd),
                              .Da_read(Rn),
                              .Db_read(Reg2Loc_out),
                              .forward_EX_A,
                              .forward_EX_B,
                              .forward_MEM_A,
                              .forward_MEM_B,
                              .Mem_WE(EX_RegWrite),
                              .EX_WE(RD_RegWrite));

    // Forwarding Mux For Da (Execute stage)
    logic [63:0] ALU_result;
    logic [63:0] EX_selection_out;
    logic [63:0] Da_in   [1:0];
    logic [63:0] Da_out;
    assign Da_in[0] =  Da;
    assign Da_in[1] =  EX_selection_out; //EX_Selection_out is the ALU result or shift result
    mux_64x2x1 FWD_A_EX_mux   (.in(Da_in), .out(Da_out), .sel(forward_EX_A));

    // Forwarding Mux For Db (Execute stage)
    logic [63:0] Db_in   [1:0];
    logic [63:0] Db_out;
    assign Db_in[0] =  Db;
    assign Db_in[1] =  EX_selection_out;
    mux_64x2x1 FWD_B_EX_mux   (.in(Db_in), .out(Db_out), .sel(forward_EX_B));

    // Forwarding Mux For Da (Mem Stage)
    logic [63:0] EX_result;
    logic [63:0] Shift_out;
    logic [63:0] Da_in_final   [1:0];
    logic [63:0] Da_out_final;
    assign Da_in_final[0] =  Da_out;
    assign Da_in_final[1] =  Shift_out;
    mux_64x2x1 FWD_A_MEM_mux   (.in(Da_in_final), .out(Da_out_final), .sel(forward_MEM_A));

    // Forwarding Mux For Db (Mem Stage)
    logic [63:0] Db_in_final   [1:0];
    logic [63:0] Db_out_final;
    assign Db_in_final[0] =  Db_out;
    assign Db_in_final[1] =  Shift_out;
    mux_64x2x1 FWD_B_MEM_mux   (.in(Db_in_final), .out(Db_out_final), .sel(forward_MEM_B));

    // ALUSrc Control
    logic [63:0] ALUSrc_in   [1:0];
    logic [63:0] ALUSrc_out;
    assign ALUSrc_in[0] =  Db_out_final;
    assign ALUSrc_in[1] =  ImSrc_out;
    mux_64x2x1 ALUSrc_mux   (.in(ALUSrc_in), .out(ALUSrc_out), .sel(ALUSrc));

    // Accelerated Branching: checks if a register is zero in the RD phase
    is_zero zero_checker (.in(Db_out_final), .zero(Db_zero));

    /***********************************************************/
    /******** Stateholding elements for end of RD stage ********/
    /***********************************************************/

    logic [63:0] RD_Da, RD_Db, RD_ALUSrc_out;

    register RD_RD1 (.clk(clk),
                     .write_enable(1'b1),
                     .data_in(Da_out_final),
                     .data_out(RD_Da));

    register RD_RD2 (.clk(clk),
                     .write_enable(1'b1),
                     .data_in(Db_out_final),
                     .data_out(RD_Db));

    register RD_ALU (.clk(clk),
                    .write_enable(1'b1),
                    .data_in(ALUSrc_out),
                    .data_out(RD_ALUSrc_out));

    logic [2:0] RD_ALUOp;
    logic [5:0] RD_shamt;

    logic RD_MemWrite, RD_MemToReg, RD_Shift, RD_SetFlags;

    register_nbit #(.WIDTH(3)) RD_ALUOp_reg
                                  (.clk(clk),
                                   .write_enable(1'b1),
                                   .data_in(ALUOp),
                                   .data_out(RD_ALUOp));

    register_nbit #(.WIDTH(6)) RD_shamt_reg
                                  (.clk(clk),
                                   .write_enable(1'b1),
                                   .data_in(shamt),
                                   .data_out(RD_shamt));

    D_FF RD_SetFlags_ff (.d(SetFlags), .q(RD_SetFlags), .clk(clk), .reset(1'b0));


    register_nbit #(.WIDTH(5)) RD_Rd_reg
                                  (.clk(clk),
                                   .write_enable(1'b1),
                                   .data_in(Rd),
                                   .data_out(RD_Rd));

    D_FF RD_MemWrite_ff (.d(MemWrite), .q(RD_MemWrite), .clk(clk), .reset(1'b0));
    D_FF RD_MemToReg_ff (.d(MemToReg), .q(RD_MemToReg), .clk(clk), .reset(1'b0));
    D_FF RD_RegWrite_ff (.d(RegWrite), .q(RD_RegWrite), .clk(clk), .reset(1'b0));
    D_FF RD_Shift_ff    (.d(Shift), .q(RD_Shift), .clk(clk), .reset(1'b0));

    ///////////////////////////////////
    ///////////// Execute  ////////////
    ///////////////////////////////////


    alu alu_         (.A(RD_Da),
                      .B(RD_ALUSrc_out),
                      .cntrl(RD_ALUOp),
                      .result(ALU_result),
                      .negative(negative_alu),
                      .zero(zero_alu),
                      .overflow(overflow_alu),
                      .carry_out(carry_out_alu));


    // If set flags, use the flags straight out of the ALU, otherwise use the flags from the DFFS
    logic [1:0] zero_select;
    assign zero_select[0] = zero_store;
    assign zero_select[1] = zero_alu;
    mux_2x1 zero_mux (.in(zero_select), .out(zero), .sel(RD_SetFlags));

    logic [1:0]overflow_select;
    assign overflow_select[0] = overflow_store;
    assign overflow_select[1] = overflow_alu;
    mux_2x1 overflow_mux (.in(overflow_select), .out(overflow), .sel(RD_SetFlags));

    logic [1:0]negative_select;
    assign negative_select[0] = negative_store;
    assign negative_select[1] = negative_alu;
    mux_2x1 negative_mux (.in(negative_select), .out(negative), .sel(RD_SetFlags));

    logic [1:0] carry_out_select;
    assign carry_out_select[0] = carry_out_store;
    assign carry_out_select[1] = carry_out_alu;
    mux_2x1 carry_out_mux (.in(carry_out_select), .out(carry_out), .sel(RD_SetFlags));

    // Shifting unit for LSR
    logic [63:0] shift_result;
    shifter shifter_ (.value(RD_Da),
                      .direction(1'b1), // 0: left, 1: right
                      .distance(RD_shamt),
                      .result(shift_result));

    // Mux to select what is forwarded: either the shift result or the alu result
    logic [63:0] EX_selection_in   [1:0];
    assign EX_selection_in[0] =  ALU_result;
    assign EX_selection_in[1] =  shift_result;
    mux_64x2x1 EX_selection_mux   (.in(EX_selection_in), .out(EX_selection_out), .sel(RD_Shift));

    /***********************************************************/
    /******** Stateholding elements for end of EX stage ********/
    /***********************************************************/

    logic [63:0] EX_Db, EX_shout;

    register EX_ALU (.clk(clk),
                     .write_enable(1'b1),
                     .data_in(ALU_result),
                     .data_out(EX_result));


    register EX_RD2 (.clk(clk),
                     .write_enable(1'b1),
                     .data_in(RD_Db),
                     .data_out(EX_Db));

    register EX_sft (.clk(clk),
                     .write_enable(1'b1),
                     .data_in(shift_result),
                     .data_out(EX_shout));


    enable_DFF zero_reg (.in(zero_alu), .out(zero_store), .enable(RD_SetFlags), .clk(clk));
    enable_DFF of_reg (.in(overflow_alu), .out(overflow_store), .enable(RD_SetFlags), .clk(clk));
    enable_DFF negative_reg (.in(negative_alu), .out(negative_store), .enable(RD_SetFlags), .clk(clk));
    enable_DFF carry_out_reg (.in(carry_out_alu), .out(carry_out_store), .enable(RD_SetFlags), .clk(clk));


    logic EX_MemWrite, EX_MemToReg, EX_Shift;
    D_FF EX_MemWrite_ff (.d(RD_MemWrite), .q(EX_MemWrite), .clk(clk), .reset(1'b0));
    D_FF EX_MemToReg_ff (.d(RD_MemToReg), .q(EX_MemToReg), .clk(clk), .reset(1'b0));
    D_FF EX_RegWrite_ff (.d(RD_RegWrite), .q(EX_RegWrite), .clk(clk), .reset(1'b0));
    D_FF EX_Shift_ff    (.d(RD_Shift), .q(EX_Shift), .clk(clk), .reset(1'b0));

    register_nbit #(.WIDTH(5)) EX_Rd_reg
                                  (.clk(clk),
                                   .write_enable(1'b1),
                                   .data_in(RD_Rd),
                                   .data_out(EX_Rd));

    ///////////////////////////////////
    /////////// Data Memory  //////////
    ///////////////////////////////////

    logic [63:0] Datamem_out;

    datamem datamem_ (.address(EX_result),
                      .write_enable(EX_MemWrite),
                      .read_enable(~EX_MemWrite),
                      .write_data(EX_Db),
                      .clk(clk),
                      .xfer_size(4'd8),
                      .read_data(Datamem_out));

    // MemToReg Mux
    logic [63:0] MemToReg_in [1:0];
    logic [63:0] MemToReg_out;
    assign MemToReg_in[0] = EX_result;
    assign MemToReg_in[1] = Datamem_out;
    mux_64x2x1 MemToReg_mux (.in(MemToReg_in), .out(MemToReg_out), .sel(EX_MemToReg));

    // Shift Mux (decides the final result to write back)
    logic [63:0] Shift_in    [1:0];
    assign Shift_in[0] = MemToReg_out;
    assign Shift_in[1] = EX_shout;
    mux_64x2x1 Shift_mux    (.in(Shift_in), .out(Shift_out), .sel(EX_Shift));


    /************************************************************/
    /******** Stateholding elements for end of MEM stage ********/
    /************************************************************/

    register_nbit #(.WIDTH(5)) DM_Rd_reg
                                  (.clk(clk),
                                   .write_enable(1'b1),
                                   .data_in(EX_Rd),
                                   .data_out(DM_Rd));

    register DM_Data_out (.clk(clk),
                          .write_enable(1'b1),
                          .data_in(Shift_out),
                          .data_out(DM_ToWrite));

    D_FF DM_RegWrite_ff (.d(EX_RegWrite), .q(DM_RegWrite), .clk(clk), .reset(1'b0));

    ///////////////////////////////////
    ///////////// Writeback ///////////
    ///////////////////////////////////

    /* Writeback is lonely because the register file was already instantiated in the RD stage */

endmodule
