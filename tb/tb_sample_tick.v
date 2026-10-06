`timescale 1ns/1ps

module tb_sample_tick;

    reg clk;
    reg reset_n;
    reg enable;
    wire sample_tick;

    integer tick_count;

    sample_tick dut (
        .clk(clk),
        .reset_n(reset_n),
        .enable(enable),
        .sample_tick(sample_tick)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;   // 10 MHz
    end

    initial begin
        reset_n = 0;
        enable = 0;
        tick_count = 0;

        #500;
        reset_n = 1;
        enable = 1;

        wait(tick_count == 3);

        $display("TEST SAMPLE TICK: PASS");
        $finish;
    end

    always @(posedge clk) begin
        if (sample_tick)
            tick_count = tick_count + 1;
    end

endmodule