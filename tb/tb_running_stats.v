`timescale 1ns/1ps

module tb_running_stats;

    reg clk;
    reg reset_n;
    reg clear;
    reg learn_enable;
    reg feature_valid;

    reg [31:0] feature_in;

    wire [31:0] mean_value;
    wire [63:0] variance_value;
    wire initialized;

    integer i;
    reg [31:0] frozen_mean;

    running_stats dut (
        .clk(clk),
        .reset_n(reset_n),
        .clear(clear),
        .learn_enable(learn_enable),
        .feature_valid(feature_valid),

        .feature_in(feature_in),

        .mean_value(mean_value),
        .variance_value(variance_value),
        .initialized(initialized)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    task send_feature;
        input [31:0] value;
        begin
            @(negedge clk);

            feature_in = value;
            feature_valid = 1;

            @(negedge clk);

            feature_valid = 0;
        end
    endtask

    initial begin

        reset_n = 0;
        clear = 0;
        learn_enable = 0;
        feature_valid = 0;
        feature_in = 0;

        #500;
        reset_n = 1;

        learn_enable = 1;

        // Normal feature around 1000
        for (i = 0; i < 100; i = i + 1) begin
            if (i[0])
                send_feature(32'd1050);
            else
                send_feature(32'd950);
        end

        #100;

        if (
            mean_value > 32'd970 &&
            mean_value < 32'd1030 &&
            variance_value > 0
        )
            $display("STATS LEARNING: PASS");
        else
            $display(
                "STATS LEARNING: FAIL MEAN=%0d VAR=%0d",
                mean_value,
                variance_value
            );

        frozen_mean = mean_value;

        // Freeze learning
        learn_enable = 0;

        // Large anomaly
        send_feature(32'd5000);

        #100;

        if (mean_value == frozen_mean)
            $display("STATS FREEZE: PASS");
        else
            $display("STATS FREEZE: FAIL");

        $finish;
    end

endmodule