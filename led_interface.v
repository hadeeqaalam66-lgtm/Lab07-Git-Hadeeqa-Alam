`timescale 1ns / 1ps

module led_interface (
    input  wire [14:0] alu_result,
    input  wire        zero_flag,
    output wire [15:0] led_out
);
    assign led_out = {zero_flag, alu_result};
endmodule
