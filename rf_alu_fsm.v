`timescale 1ns / 1ps

// IDLE -> WRITE_X1 -> WRITE_X2 -> WRITE_X3 -> WAIT_OP
// WAIT_OP --btnU--> EXEC -> SHOW_RESULT --btnU--> EXEC -> SHOW_RESULT ...
module rf_alu_fsm (
    input  wire        clk,
    input  wire        rst,
    input  wire        exec,        // one-clock pulse from btnU
    input  wire        demo,        // sw[15]: 1 = run the fixed demo sequence
    input  wire [3:0]  sw_op,       // sw[3:0]: operation select
    input  wire [31:0] alu_result,
    input  wire        zero,
    output reg  [3:0]  state,
    output reg         we,
    output reg  [4:0]  rs1,
    output reg  [4:0]  rs2,
    output reg  [4:0]  rd,
    output reg  [31:0] wdata,
    output reg  [3:0]  alu_ctrl
);

    localparam IDLE        = 4'd0,
               WRITE_X1    = 4'd1,
               WRITE_X2    = 4'd2,
               WRITE_X3    = 4'd3,
               WAIT_OP     = 4'd4,
               EXEC        = 4'd5,
               SHOW_RESULT = 4'd6;

    // Operation codes (same as ALUControl; 0111 = BEQ check)
    localparam OP_AND = 4'b0000, OP_OR  = 4'b0001, OP_ADD = 4'b0010,
               OP_XOR = 4'b0011, OP_SLL = 4'b0100, OP_SRL = 4'b0101,
               OP_SUB = 4'b0110, OP_BEQ = 4'b0111;

    // Demo sequence: ADD, SUB, AND, OR, XOR, SLL, SRL, BEQ
    reg [2:0] demo_idx;
    reg [3:0] demo_op;
    always @(*) begin
        case (demo_idx)
            3'd0: demo_op = OP_ADD;
            3'd1: demo_op = OP_SUB;
            3'd2: demo_op = OP_AND;
            3'd3: demo_op = OP_OR;
            3'd4: demo_op = OP_XOR;
            3'd5: demo_op = OP_SLL;
            3'd6: demo_op = OP_SRL;
            default: demo_op = OP_BEQ;
        endcase
    end

    wire [3:0] op = demo ? demo_op : sw_op;

    always @(posedge clk or posedge rst) begin
        if (rst) demo_idx <= 3'd0;
        else if (state == EXEC && demo) demo_idx <= demo_idx + 1'b1;
    end

    reg [3:0] next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:        next_state = WRITE_X1;
            WRITE_X1:    next_state = WRITE_X2;
            WRITE_X2:    next_state = WRITE_X3;
            WRITE_X3:    next_state = WAIT_OP;
            WAIT_OP:     if (exec) next_state = EXEC;
            EXEC:        next_state = SHOW_RESULT;
            SHOW_RESULT: if (exec) next_state = EXEC;
            default:     next_state = IDLE;
        endcase
    end

    always @(*) begin
        we = 1'b0; rs1 = 5'd0; rs2 = 5'd0; rd = 5'd0;
        wdata = 32'b0; alu_ctrl = 4'b0000;

        case (state)
            WRITE_X1: begin rd = 5'd1; wdata = 32'h10101010; we = 1'b1; end
            WRITE_X2: begin rd = 5'd2; wdata = 32'h01010101; we = 1'b1; end
            WRITE_X3: begin rd = 5'd3; wdata = 32'h00000005; we = 1'b1; end

            EXEC: begin
                case (op)
                    OP_ADD: begin rs1=5'd1; rs2=5'd2; rd=5'd4;  alu_ctrl=4'b0010; wdata=alu_result; we=1'b1; end
                    OP_SUB: begin rs1=5'd1; rs2=5'd2; rd=5'd5;  alu_ctrl=4'b0110; wdata=alu_result; we=1'b1; end
                    OP_AND: begin rs1=5'd1; rs2=5'd2; rd=5'd6;  alu_ctrl=4'b0000; wdata=alu_result; we=1'b1; end
                    OP_OR:  begin rs1=5'd1; rs2=5'd2; rd=5'd7;  alu_ctrl=4'b0001; wdata=alu_result; we=1'b1; end
                    OP_XOR: begin rs1=5'd1; rs2=5'd2; rd=5'd8;  alu_ctrl=4'b0011; wdata=alu_result; we=1'b1; end
                    OP_SLL: begin rs1=5'd1; rs2=5'd3; rd=5'd9;  alu_ctrl=4'b0100; wdata=alu_result; we=1'b1; end
                    OP_SRL: begin rs1=5'd1; rs2=5'd3; rd=5'd10; alu_ctrl=4'b0101; wdata=alu_result; we=1'b1; end
                    OP_BEQ: begin
                        rs1=5'd1; rs2=5'd1; rd=5'd11; alu_ctrl=4'b0110;
                        wdata = zero ? 32'd1 : 32'd0;
                        we    = zero;
                    end
                    default: ; // unused switch codes: no write
                endcase
            end

            default: ; // IDLE, WAIT_OP, SHOW_RESULT: no write
        endcase
    end

endmodule