`timescale 1ns / 1ps

module ALU_tb;
    reg [31:0] A, B;
    reg [3:0] ALUControl;
    wire [31:0] ALUResult;
    wire Zero;

    ALU uut (
        .A(A), .B(B), .ALUControl(ALUControl),
        .ALUResult(ALUResult), .Zero(Zero)
    );

    initial begin
        $dumpfile("ALU_tb.vcd");
        $dumpvars(0, ALU_tb);
        $monitor("t=%0t A=%h B=%h OP=%b Result=%h Zero=%b",
                 $time, A, B, ALUControl, ALUResult, Zero);

        A = 32'h10101010;
        B = 32'h01010101;

        ALUControl = 4'b0010; #10; // ADD
        ALUControl = 4'b0110; #10; // SUB
        ALUControl = 4'b0000; #10; // AND
        ALUControl = 4'b0001; #10; // OR
        ALUControl = 4'b0011; #10; // XOR
        ALUControl = 4'b0100; #10; // SLL
        ALUControl = 4'b0101; #10; // SRL

        B = A;
        ALUControl = 4'b0110; #10; // A-A = 0, Zero=1

        $display("ALU testbench complete.");
        $finish;
    end
endmodule
