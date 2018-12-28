module regfile (ReadData1,
                ReadData2,
                WriteData,
                ReadRegister1,
                ReadRegister2,
                WriteRegister,
                RegWrite,
                clk);

    input logic [63:0] WriteData;
    input logic [4:0] ReadRegister1, ReadRegister2, WriteRegister;
    input logic RegWrite, clk;

    output logic [63:0] ReadData1, ReadData2;

    logic [31:0] write_enable;
    logic [63:0] reg_out [31:0];

    decoder_5x32 decoder (.in(WriteRegister), .out(write_enable), .enable(RegWrite));

    mux_64x32x1 mux_r1 (.in(reg_out), .out(ReadData1), .sel(ReadRegister1));
    mux_64x32x1 mux_r2 (.in(reg_out), .out(ReadData2), .sel(ReadRegister2));

    genvar i;
    generate
        for (i=0; i<31; i=i+1) begin
            register regs (.clk(clk),
//                          .reset(),
                          .write_enable(write_enable[i]),
                          .data_in(WriteData),
                          .data_out(reg_out[i]));
        end
    endgenerate
    assign reg_out[31] = 64'b0;

endmodule
