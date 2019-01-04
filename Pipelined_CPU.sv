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
    logic [63:0] ImSrc_out;

    assign ImSrc_out = (ImSrc) ? {{52{1'b0}}, ALU_Imm12} : {{55{DAddr9[8]}}, DAddr9};


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

    // Forwarding Mux For Db (Execute stage)
    logic [63:0] Db_out;
    assign Db_out = (forward_EX_B) ? EX_selection_out : Db;

    // Forwarding Mux For Da (Mem Stage)
    logic [63:0] EX_result;
    logic [63:0] Shift_out;

    logic [63:0] Da_out_final;
    assign Da_out_final = (forward_MEM_A) ? Shift_out : ((forward_EX_A) ? EX_selection_out : Da);


    // Forwarding Mux For Db (Mem Stage)
    logic [63:0] Db_out_final;
    assign Db_out_final = (forward_MEM_B) ? Shift_out : ((forward_EX_B) ? EX_selection_out : Db);

    // ALUSrc Control
    logic [63:0] ALUSrc_out;
    assign ALUSrc_out = (ALUSrc) ? ImSrc_out : Db_out_final;


    // Accelerated Branching: checks if a register is zero in the RD phase
    is_zero zero_checker (.in(Db_out_final), .zero(Db_zero));

    /***********************************************************/
    /******** Stateholding elements for end of RD stage ********/
    /***********************************************************/

    logic [63:0] RD_Da, RD_Db, RD_ALUSrc_out;
    logic [2:0] RD_ALUOp;
    logic [5:0] RD_shamt;

    logic RD_MemWrite, RD_MemToReg, RD_Shift, RD_SetFlags;

    always_ff @(posedge clk) begin
        RD_Da <= Da_out_final;
        RD_Db <= Db_out_final;
        RD_ALUSrc_out <= ALUSrc_out;

        RD_ALUOp <= ALUOp;
        RD_shamt <= shamt;
        RD_Rd <= Rd;

        RD_SetFlags <= SetFlags;
        RD_MemWrite <= MemWrite;
        RD_MemToReg <= MemToReg;
        RD_RegWrite <= RegWrite;
        RD_Shift <= Shift;
    end

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
    assign zero = (RD_SetFlags) ? zero_alu : zero_store;
    assign overflow = (RD_SetFlags) ? overflow_alu: overflow_store;
    assign negative = (RD_SetFlags) ? negative_alu: negative_store;
    assign carry_out = (RD_SetFlags) ? carry_out_alu: carry_out_store;

    // Shifting unit for LSR
    logic [63:0] shift_result;
    shifter shifter_ (.value(RD_Da),
                      .direction(1'b1), // 0: left, 1: right
                      .distance(RD_shamt),
                      .result(shift_result));

    // Mux to select what is forwarded: either the shift result or the alu result
    assign EX_selection_out = (RD_Shift) ? shift_result : ALU_result;

    /***********************************************************/
    /******** Stateholding elements for end of EX stage ********/
    /***********************************************************/

    logic [63:0] EX_Db, EX_shout;
    logic EX_MemWrite, EX_MemToReg, EX_Shift;

    always_ff @(posedge clk) begin
        EX_result <= ALU_result;
        EX_Db <= RD_Db;
        EX_shout <= shift_result;

        if (RD_SetFlags) begin
            zero_store <= zero_alu;
            overflow_store <= overflow_alu;
            negative_store <= negative_alu;
            carry_out_store <= carry_out_alu;
        end

        EX_MemWrite <= RD_MemWrite;
        EX_MemToReg <= RD_MemToReg;
        EX_RegWrite <= RD_RegWrite;
        EX_Shift <= RD_Shift;

        EX_Rd <= RD_Rd;
    end

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
    logic [63:0] MemToReg_out;
    assign MemToReg_out = (EX_MemToReg) ? Datamem_out : EX_result;

    // Shift Mux (decides the final result to write back)
    assign Shift_out  = (EX_Shift) ? EX_shout : MemToReg_out;

    /************************************************************/
    /******** Stateholding elements for end of MEM stage ********/
    /************************************************************/

    always_ff @(posedge clk) begin
        DM_Rd <= EX_Rd;
        DM_ToWrite <= Shift_out;
        DM_RegWrite <= EX_RegWrite;
    end

    ///////////////////////////////////
    ///////////// Writeback ///////////
    ///////////////////////////////////

    /* Writeback is lonely because the register file was already instantiated in the RD stage */

endmodule
