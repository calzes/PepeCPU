module control (


    input logic [31:0] instruction,
    input logic        Db_zero, zero, negative, overflow, carry_out,

    ///////////////////////////////////
    ///////// Data Path Output ////////
    ///////////////////////////////////
    output logic [2:0] ALUOp,
    output logic       Reg2Loc,
                       RegWrite,
                       ALUSrc,
                       MemWrite,
                       MemToReg,
                       Shift,
                       ImSrc,
                       SetFlags,

    output logic [5:0]  shamt, // shift amount for LSR
    output logic [11:0] ALU_Imm12, // immediate for ADDI
    output logic [8:0] DAddr9,  // Store Address
    output logic [4:0]  Rd, Rm, Rn, // Registers for RegFile in

    ///////////////////////////////////
    ///// Instruction Path Output /////
    ///////////////////////////////////
    output logic            UncondBr,
                            BrTaken,
    output logic 	[18:0] 	CondAddr19,
    output logic    [25:0] 	BrAddr26

);
    always_comb begin
        case(instruction[28:26])

            /******D-TYPE******/
            3'b110: begin
                        Reg2Loc = 0;
                        BrTaken = 0;
                        Shift = 0;
                        ImSrc = 0;
                        ALUSrc = 1;
                        ALUOp = 3'b010;
                        SetFlags = 0;
                        DAddr9 = instruction[20:12];
                        Rd = instruction[4:0];
                        Rn = instruction[9:5];
                        if (instruction[22]) begin // LDUR
                            RegWrite = 1;
                            MemWrite = 0;
                            MemToReg = 1;
                        end else begin // STUR
                            RegWrite = 0;
                            MemWrite = 1;
                        end
                    end
            /******B-TYPE******/
            /*****CB-TYPE******/
            3'b101: begin
                        RegWrite = 0;
                        MemWrite = 0;
                        Shift = 0;
                        SetFlags = 0;
                        Rd = instruction[4:0];
                        CondAddr19 = instruction[23:5];
                        Rn = 5'b11111;
                        case (instruction[31:29])
                            3'b101: begin // CBZ
                                        Reg2Loc = 0;
                                        UncondBr = 0;
                                        BrTaken = Db_zero; //Something
                                    end
                            3'b010: begin // B.LT
                                        UncondBr = 0;
                                        Rn = 5'd31;
                                        BrTaken = negative ^ overflow;
                                    end
                            3'b000: begin // B
                                        BrAddr26 = instruction[25:0];
                                        UncondBr = 1;
                                        BrTaken = 1;
                                    end
                        endcase
                    end
            /******R-TYPE******/
            3'b010: begin
                        Rm = instruction[20:16];
                        Rn = instruction[9:5];
                        Rd = instruction[4:0];
                        Reg2Loc  = 1;
                        RegWrite = 1;
                        MemWrite = 0;
                        ALUSrc   = 0;
                        BrTaken  = 0;
                        Shift    = 0;
                        MemToReg = 0;
                        SetFlags = instruction[29];
                        case (instruction[31:29])
                            3'b111: ALUOp = 3'b011; // SUBS
                            3'b101: ALUOp = 3'b010; // ADDS
                            3'b110: ALUOp = 3'b110; // EOR
                            3'b100: ALUOp = 3'b100; // AND
                        endcase
                    end
            /******I-TYPE******/
            /******LSR******/
            3'b100: begin
                        Rn = instruction[9:5];
                        Rd = instruction[4:0];
                        Reg2Loc = 1;
                        RegWrite = 1;
                        MemWrite = 0;
                        BrTaken = 0;
                        MemToReg = 0;
                        SetFlags = 0;
                        if (instruction[30] == 1) begin // LSR
                            ALUSrc = 0;
                            Shift = 1;
                            shamt = instruction[15:10];
                        end else begin // ADDI
                            ALUSrc = 1;
                            ALUOp = 3'b010;
                            Shift = 0;
                            ImSrc = 1;
                            ALU_Imm12 = instruction[21:10];
                        end
                    end
            default: begin
                         BrTaken = 0;
                         ALUSrc = 1;
                         Rn = 5'b11111;
                     end
       endcase
    end
endmodule
