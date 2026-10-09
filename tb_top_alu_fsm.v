`timescale 1ns / 1ps

// Optional testbench for the earlier FPGA-board demo.
module tb_top_alu_fsm;
    reg clk, reset, btn_exec;
    reg [3:0] sw;
    wire [15:0] led;

    top_alu_fsm uut (
        .clk(clk), .reset(reset), .btn_exec(btn_exec),
        .sw(sw), .led(led)
    );

    always #5 clk = ~clk;

    task press_button;
        begin
            btn_exec = 1'b1;
            #700000;
            btn_exec = 1'b0;
            #700000;
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        btn_exec = 0;
        sw = 4'b0000;

        #100;
        reset = 0;
        #100;

        $display("--- Testing OR operation ---");
        sw = 4'b0001;
        press_button();
        $display("SW=%b LED=%h", sw, led);
        if (led === 16'h1111)
            $display("PASS: OR result");
        else
            $display("FAIL: OR result, got %h expected 1111", led);

        $display("--- Testing ADD operation ---");
        sw = 4'b0010;
        press_button();
        $display("SW=%b LED=%h", sw, led);

        $display("--- Testing AND operation ---");
        sw = 4'b0000;
        press_button();
        $display("SW=%b LED=%h", sw, led);

        $finish;
    end
endmodule
