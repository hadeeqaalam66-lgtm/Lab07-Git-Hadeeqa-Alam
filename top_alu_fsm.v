`timescale 1ns / 1ps

// Optional FPGA-board demonstration from the earlier lab.
// Not required for the Task 2 Register File/ALU/FSM simulation.
module top_alu_fsm (
    input  wire clk,
    input  wire reset,
    input  wire btn_exec,
    input  wire [3:0] sw,
    output wire [15:0] led
);
    wire [31:0] A = 32'h10101010;
    wire [31:0] B = 32'h01010101;

    wire [3:0] alu_control;
    wire [31:0] raw_alu_result;
    wire raw_zero;
    wire btn_clean;

    reg [14:0] latched_result;
    reg latched_zero;

    switch_interface sw_inst (
        .sw_in(sw),
        .alu_ctrl_out(alu_control)
    );

    button_debouncer db_inst (
        .clk(clk),
        .rst(reset),
        .btn_in(btn_exec),
        .btn_out(btn_clean)
    );

    ALU alu_inst (
        .A(A),
        .B(B),
        .ALUControl(alu_control),
        .ALUResult(raw_alu_result),
        .Zero(raw_zero)
    );

    led_interface led_inst (
        .alu_result(latched_result),
        .zero_flag(latched_zero),
        .led_out(led)
    );

    localparam IDLE = 1'b0;
    localparam EXEC = 1'b1;
    reg state, next_state;

    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (btn_clean) next_state = EXEC;
            EXEC: if (!btn_clean) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            latched_result <= 15'b0;
            latched_zero   <= 1'b0;
        end else if (state == EXEC) begin
            latched_result <= raw_alu_result[14:0];
            latched_zero   <= raw_zero;
        end
    end
endmodule
