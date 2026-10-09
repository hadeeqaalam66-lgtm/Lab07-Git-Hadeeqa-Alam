`timescale 1ns / 1ps
module RegisterFile (
    input wire clk,
    input wire rst,
    input wire WriteEnable,
    input wire [4:0] rs1,
    input wire [4:0] rs2,
    input wire [4:0] rd,
    input wire [31:0] WriteData,
    output wire [31:0] ReadData1,
    output wire [31:0] ReadData2
);

    reg [31:0] regs [31:0];
    integer i;

    // Synchronous active-high reset: clears x1 through x31.
    // x0 is not stored as writable data; it is forced to zero on reads.
    always @(posedge clk) begin
        if (rst) begin
            for (i = 1; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end
        else if (WriteEnable && (rd != 5'd0)) begin
            regs[rd] <= WriteData;
        end
    end

    // Combinational/asynchronous reads.
    assign ReadData1 = (rs1 == 5'd0) ? 32'b0 : regs[rs1];
    assign ReadData2 = (rs2 == 5'd0) ? 32'b0 : regs[rs2];

endmodule
