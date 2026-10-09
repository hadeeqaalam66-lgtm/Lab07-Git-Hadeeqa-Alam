`timescale 1ns / 1ps

module button_debouncer (
    input  wire clk,
    input  wire rst,
    input  wire btn_in,
    output reg  btn_out
);
    reg [15:0] count;
    reg state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count   <= 16'b0;
            state   <= 1'b0;
            btn_out <= 1'b0;
        end else begin
            if (btn_in != state && count < 16'hFFFF) begin
                count <= count + 1'b1;
            end else if (count == 16'hFFFF) begin
                state <= btn_in;
                count <= 16'b0;
            end else begin
                count <= 16'b0;
            end
            btn_out <= state;
        end
    end
endmodule