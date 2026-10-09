`timescale 1ns / 1ps

module RF_ALU_FSM_tb;

    reg clk, rst;
    wire [31:0] ReadData1, ReadData2;
    wire [31:0] ALUResult;
    wire Zero;

    reg WriteEnable;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] WriteData;
    reg [3:0] ALUControl;

    // FSM state names
    localparam IDLE           = 4'd0,
               WRITE_X1       = 4'd1,
               WRITE_X2       = 4'd2,
               WRITE_X3       = 4'd3,
               DO_ADD         = 4'd4,
               DO_SUB         = 4'd5,
               DO_AND         = 4'd6,
               DO_OR          = 4'd7,
               DO_XOR         = 4'd8,
               DO_SLL         = 4'd9,
               DO_SRL         = 4'd10,
               DO_BEQ         = 4'd11,
               TEST_RAW_WRITE = 4'd12, // New state for explicit RAW test
               TEST_RAW_READ  = 4'd13, // New state for explicit RAW test
               DONE           = 4'd14;

    reg [3:0] state;

    RegisterFile rf (
        .clk(clk), .rst(rst), .WriteEnable(WriteEnable),
        .rs1(rs1), .rs2(rs2), .rd(rd), .WriteData(WriteData),
        .ReadData1(ReadData1), .ReadData2(ReadData2)
    );

    ALU alu (
        .A(ReadData1), .B(ReadData2), .ALUControl(ALUControl),
        .ALUResult(ALUResult), .Zero(Zero)
    );

    always #5 clk = ~clk;

    always @(*) begin
        WriteEnable = 1'b0;
        rs1 = 5'd0;
        rs2 = 5'd0;
        rd = 5'd0;
        WriteData = 32'b0;
        ALUControl = 4'b0000;  // AND by default

        case (state)
            WRITE_X1: begin
                rd = 5'd1;
                WriteData = 32'h10101010;
                WriteEnable = 1'b1;
            end
            WRITE_X2: begin
                rd = 5'd2;
                WriteData = 32'h01010101;
                WriteEnable = 1'b1;
            end
            WRITE_X3: begin
                rd = 5'd3;
                WriteData = 32'h00000005;
                WriteEnable = 1'b1;
            end
            DO_ADD: begin
                rs1 = 5'd1; rs2 = 5'd2; rd = 5'd4;
                ALUControl = 4'b0010; // ADD
                WriteData = ALUResult;
                WriteEnable = 1'b1;
            end
            DO_SUB: begin
                rs1 = 5'd1; rs2 = 5'd2; rd = 5'd5;
                ALUControl = 4'b0110; // SUB
                WriteData = ALUResult;
                WriteEnable = 1'b1;
            end
            DO_AND: begin
                rs1 = 5'd1; rs2 = 5'd2; rd = 5'd6;
                ALUControl = 4'b0000; // AND
                WriteData = ALUResult;
                WriteEnable = 1'b1;
            end
            DO_OR: begin
                rs1 = 5'd1; rs2 = 5'd2; rd = 5'd7;
                ALUControl = 4'b0001; // OR
                WriteData = ALUResult;
                WriteEnable = 1'b1;
            end
            DO_XOR: begin
                rs1 = 5'd1; rs2 = 5'd2; rd = 5'd8;
                ALUControl = 4'b0011; // XOR
                WriteData = ALUResult;
                WriteEnable = 1'b1;
            end
            DO_SLL: begin
                rs1 = 5'd1; rs2 = 5'd3; rd = 5'd9;
                ALUControl = 4'b0100; // Shift left by x3[4:0] = 5
                WriteData = ALUResult;
                WriteEnable = 1'b1;
            end
            DO_SRL: begin
                rs1 = 5'd1; rs2 = 5'd3; rd = 5'd10;
                ALUControl = 4'b0101; // Shift right by 5
                WriteData = ALUResult;
                WriteEnable = 1'b1;
            end
            DO_BEQ: begin
                rs1 = 5'd1; rs2 = 5'd1;
                ALUControl = 4'b0110; // x1 - x1; Zero should be 1
                rd = 5'd11;
                WriteData = Zero ? 32'd1 : 32'd0;
                WriteEnable = Zero; // conditionally write flag
            end
            TEST_RAW_WRITE: begin
                // Write known value to x12
                rd = 5'd12;
                WriteData = 32'hAAAA5555;
                WriteEnable = 1'b1;
            end
            TEST_RAW_READ: begin
                // Read x12 in the very next cycle and pass through ALU to x13
                rs1 = 5'd12; 
                rs2 = 5'd0;  // ReadData2 will be 0
                rd  = 5'd13;
                ALUControl = 4'b0010; // ADD (x12 + 0)
                WriteData = ALUResult;
                WriteEnable = 1'b1;
            end
            default: begin
                // IDLE and DONE: no write
            end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else begin
            case (state)
                IDLE:           state <= WRITE_X1;
                WRITE_X1:       state <= WRITE_X2;
                WRITE_X2:       state <= WRITE_X3;
                WRITE_X3:       state <= DO_ADD;
                DO_ADD:         state <= DO_SUB;
                DO_SUB:         state <= DO_AND;
                DO_AND:         state <= DO_OR;
                DO_OR:          state <= DO_XOR;
                DO_XOR:         state <= DO_SLL;
                DO_SLL:         state <= DO_SRL;
                DO_SRL:         state <= DO_BEQ;
                DO_BEQ:         state <= TEST_RAW_WRITE;
                TEST_RAW_WRITE: state <= TEST_RAW_READ;
                TEST_RAW_READ:  state <= DONE;
                DONE:           state <= DONE;
                default:        state <= IDLE;
            endcase
        end
    end

    initial begin
        $dumpfile("RF_ALU_FSM_tb.vcd");
        $dumpvars(0, RF_ALU_FSM_tb);

        clk = 0;
        rst = 1;
        state = IDLE;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 0;

        $display("Time  State  rs1 rs2 rd  ReadData1    ReadData2    ALUResult    Zero WE");
        $monitor("%4t  %d     %d   %d  %d  %h  %h  %h  %b   %b",
                 $time, state, rs1, rs2, rd, ReadData1, ReadData2,
                 ALUResult, Zero, WriteEnable);

        wait (state == DONE);
        @(negedge clk);
        $display("\nChecking results stored in registers:");

        if (rf.regs[4] !== (32'h10101010 + 32'h01010101))
            $display("FAIL ADD x4: %h", rf.regs[4]);
        else $display("PASS ADD -> x4 = %h", rf.regs[4]);

        if (rf.regs[5] !== (32'h10101010 - 32'h01010101))
            $display("FAIL SUB x5: %h", rf.regs[5]);
        else $display("PASS SUB -> x5 = %h", rf.regs[5]);

        if (rf.regs[6] !== (32'h10101010 & 32'h01010101))
            $display("FAIL AND x6: %h", rf.regs[6]);
        else $display("PASS AND -> x6 = %h", rf.regs[6]);

        if (rf.regs[7] !== (32'h10101010 | 32'h01010101))
            $display("FAIL OR x7: %h", rf.regs[7]);
        else $display("PASS OR -> x7 = %h", rf.regs[7]);

        if (rf.regs[8] !== (32'h10101010 ^ 32'h01010101))
            $display("FAIL XOR x8: %h", rf.regs[8]);
        else $display("PASS XOR -> x8 = %h", rf.regs[8]);

        if (rf.regs[9] !== (32'h10101010 << 5))
            $display("FAIL SLL x9: %h", rf.regs[9]);
        else $display("PASS SLL -> x9 = %h", rf.regs[9]);

        if (rf.regs[10] !== (32'h10101010 >> 5))
            $display("FAIL SRL x10: %h", rf.regs[10]);
        else $display("PASS SRL -> x10 = %h", rf.regs[10]);

        if (rf.regs[11] !== 32'd1)
            $display("FAIL BEQ flag x11: %h", rf.regs[11]);
        else $display("PASS BEQ equal flag -> x11 = 1");

        // Validate the explicitly added RAW test
        if (rf.regs[13] !== 32'hAAAA5555)
            $display("FAIL RAW Test -> x13: %h (Expected AAAAA5555)", rf.regs[13]);
        else $display("PASS Read-After-Write (RAW) timing -> x13 = %h", rf.regs[13]);

        $display("Integrated FSM + ALU + Register File testbench complete.");
        #10;
        $finish;
    end
endmodule