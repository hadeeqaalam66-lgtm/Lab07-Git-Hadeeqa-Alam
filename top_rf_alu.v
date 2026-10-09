`timescale 1ns / 1ps

module top_rf_alu (
    input  wire        clk,
    input  wire        reset,      // btnC
    input  wire        btn_exec,   // btnU
    input  wire [15:0] sw,         // sw[3:0] = operation, sw[15] = demo mode
    output wire [15:0] led
);
    wire [3:0] sw_op;
    switch_interface sw_inst (.sw_in(sw[3:0]), .alu_ctrl_out(sw_op));

    // Debounce btnU and make a one-clock pulse
    wire btn_clean;
    reg  btn_prev;
    button_debouncer db_inst (.clk(clk), .rst(reset), .btn_in(btn_exec), .btn_out(btn_clean));

    always @(posedge clk or posedge reset) begin
        if (reset) btn_prev <= 1'b0;
        else       btn_prev <= btn_clean;
    end
    wire exec = btn_clean & ~btn_prev;

    wire [3:0]  state;
    wire        we;
    wire [4:0]  rs1, rs2, rd;
    wire [31:0] wdata, alu_result, rdata1, rdata2;
    wire [3:0]  alu_ctrl;
    wire        zero;

    rf_alu_fsm fsm_inst (
        .clk(clk), .rst(reset), .exec(exec), .demo(sw[15]), .sw_op(sw_op),
        .alu_result(alu_result), .zero(zero),
        .state(state), .we(we), .rs1(rs1), .rs2(rs2), .rd(rd),
        .wdata(wdata), .alu_ctrl(alu_ctrl)
    );

    RegisterFile rf_inst (
        .clk(clk), .rst(reset), .WriteEnable(we),
        .rs1(rs1), .rs2(rs2), .rd(rd), .WriteData(wdata),
        .ReadData1(rdata1), .ReadData2(rdata2)
    );

    ALU alu_inst (
        .A(rdata1), .B(rdata2), .ALUControl(alu_ctrl),
        .ALUResult(alu_result), .Zero(zero)
    );

    // Latch the result when the operation executes (state 5)
    reg [10:0] result_lat;
    reg        zero_lat;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            result_lat <= 11'b0;
            zero_lat   <= 1'b0;
        end else if (state == 4'd5) begin
            result_lat <= wdata[10:0];
            zero_lat   <= zero;
        end
    end

    // LED15 = Zero, LED14..11 = FSM state, LED10..0 = low 11 result bits
    led_interface led_inst (
        .alu_result({state, result_lat}),
        .zero_flag(zero_lat),
        .led_out(led)
    );
endmodule