`timescale 1ns / 1ps

module RegisterFile_tb;

    reg clk, rst, WriteEnable;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] WriteData;
    wire [31:0] ReadData1, ReadData2;

    RegisterFile uut (
        .clk(clk), .rst(rst), .WriteEnable(WriteEnable),
        .rs1(rs1), .rs2(rs2), .rd(rd), .WriteData(WriteData),
        .ReadData1(ReadData1), .ReadData2(ReadData2)
    );

    always #5 clk = ~clk;  // 10 ns clock period

    task write_register;
        input [4:0] address;
        input [31:0] value;
        begin
            @(negedge clk);
            rd = address;
            WriteData = value;
            WriteEnable = 1'b1;
            @(posedge clk);  // data is stored on this rising edge
            #1;
            @(negedge clk);
            WriteEnable = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("RegisterFile_tb.vcd");
        $dumpvars(0, RegisterFile_tb);

        clk = 0;
        rst = 1;
        WriteEnable = 0;
        rs1 = 0; rs2 = 0; rd = 0; WriteData = 0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 0;

        // Test 1: write x5 and read it through both read ports.
        write_register(5'd5, 32'hDEADBEEF);
        rs1 = 5'd5;
        rs2 = 5'd5;
        #1;
        if (ReadData1 !== 32'hDEADBEEF || ReadData2 !== 32'hDEADBEEF)
            $display("FAIL: x5 read test. R1=%h R2=%h", ReadData1, ReadData2);
        else
            $display("PASS: x5 write/read and simultaneous dual read.");

        // Test 2: writes to x0 must be ignored.
        write_register(5'd0, 32'h12345678);
        rs1 = 5'd0;
        rs2 = 5'd0;
        #1;
        if (ReadData1 !== 32'b0 || ReadData2 !== 32'b0)
            $display("FAIL: x0 did not read as zero.");
        else
            $display("PASS: writes to x0 are ignored; x0 reads zero.");

        // Test 3: overwrite x5.
        write_register(5'd5, 32'hCAFEF00D);
        rs1 = 5'd5;
        #1;
        if (ReadData1 !== 32'hCAFEF00D)
            $display("FAIL: overwrite test. Got %h", ReadData1);
        else
            $display("PASS: x5 overwrite test.");

        // Test 4: read two different registers simultaneously.
        write_register(5'd6, 32'h0BADF00D);
        rs1 = 5'd5;
        rs2 = 5'd6;
        #1;
        if (ReadData1 !== 32'hCAFEF00D || ReadData2 !== 32'h0BADF00D)
            $display("FAIL: dual read test. R1=%h R2=%h", ReadData1, ReadData2);
        else
            $display("PASS: both read ports return correct values concurrently.");

        // Test 5: reset clears registers.
        @(negedge clk);
        rst = 1;
        @(posedge clk);
        #1;
        rst = 0;
        rs1 = 5'd5;
        rs2 = 5'd6;
        #1;
        if (ReadData1 !== 32'b0 || ReadData2 !== 32'b0)
            $display("FAIL: reset did not clear x5/x6.");
        else
            $display("PASS: reset clears registers.");

        $display("RegisterFile testbench complete.");
        #10;
        $finish;
    end

endmodule
