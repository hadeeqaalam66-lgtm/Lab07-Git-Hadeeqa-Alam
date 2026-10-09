`timescale 1ns / 1ps

module ALU (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  ALUControl,
    output reg  [31:0] ALUResult,
    output wire        Zero
);

    localparam ALU_AND = 4'b0000;
    localparam ALU_OR  = 4'b0001;
    localparam ALU_ADD = 4'b0010;
    localparam ALU_XOR = 4'b0011;
    localparam ALU_SLL = 4'b0100;
    localparam ALU_SRL = 4'b0101;
    localparam ALU_SUB = 4'b0110;

    always @(*) begin
        case (ALUControl)
            ALU_AND: ALUResult = A & B;
            ALU_OR:  ALUResult = A | B;
            ALU_ADD: ALUResult = A + B;
            ALU_SUB: ALUResult = A - B;
            ALU_XOR: ALUResult = A ^ B;
            ALU_SLL: ALUResult = A << B[4:0];
            ALU_SRL: ALUResult = A >> B[4:0];
            default: ALUResult = 32'b0;
        endcase
    end

    assign Zero = (ALUResult == 32'b0);

endmodule
