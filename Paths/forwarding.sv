
module forwarding (ALU_write, Mem_write, Da_read, Db_read, forward_EX_A, forward_EX_B, forward_MEM_A, forward_MEM_B, Mem_WE, EX_WE);
    input logic [4:0] ALU_write, Mem_write;
    input logic [4:0] Da_read, Db_read;
    input logic Mem_WE, EX_WE;
    output logic forward_EX_A, forward_EX_B;
    output logic forward_MEM_A, forward_MEM_B;

    always_comb begin
        forward_EX_A = 1'b0;
        forward_EX_B = 1'b0;
        forward_MEM_A = 1'b0;
        forward_MEM_B = 1'b0;
        //Forwarding from the data memory stage
        if (Mem_write == Da_read && Mem_WE && Da_read != 5'b11111) begin
            forward_MEM_A = 1'b1;
        end
        if (Mem_write == Db_read && Mem_WE && Db_read != 5'b11111) begin
            forward_MEM_B = 1'b1;
        end
        //Forwarding from the execute stage
        if (ALU_write == Da_read && EX_WE && Da_read != 5'b11111) begin
          forward_EX_A = 1'b1;
          forward_MEM_A = 1'b0;
        end
        if (ALU_write == Db_read && EX_WE && Db_read != 5'b11111) begin
            forward_EX_B = 1'b1;
            forward_MEM_B = 1'b0;
        end
    end
endmodule
