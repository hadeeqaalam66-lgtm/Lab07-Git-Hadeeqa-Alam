`timescale 1ns / 1ps

module switch_interface (
    input  wire [3:0] sw_in,
    output wire [3:0] alu_ctrl_out
);
    assign alu_ctrl_out = sw_in;
endmodule

