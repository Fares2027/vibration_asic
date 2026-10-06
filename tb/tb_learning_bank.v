`timescale 1ns/1ps

module tb_learning_bank;

    reg clk;
    reg reset_n;
    reg clear;
    reg learn_enable;
    reg features_valid;

    reg [31:0] feature_peak;
    reg [31:0] feature_zcr;
    reg [31:0] feature_energy;
    reg [31:0] feature_g1;
    reg [31:0] feature_g2;
    reg [31:0] feature_g3;
    reg [31:0] feature_g4;

    wire [31:0] mean_peak;
    wire [31:0] mean_zcr;
    wire [31:0] mean_energy;
    wire [31:0] mean_g1;
    wire [31:0] mean_g2;
    wire [31:0] mean_g3;
    wire [31:0] mean_g4;

    wire learning_initialized;

    integer i;

    learning_bank dut (
        .clk(clk),
        .reset_n(reset_n),
        .clear(clear),
        .learn_enable(learn_enable),
        .features_valid(features_valid),

        .feature_peak(feature_peak),
        .feature_zcr(feature_zcr),
        .feature_energy(feature_energy),
        .feature_g1(feature_g1),
        .feature_g2(feature_g2),
        .feature_g3(feature_g3),
        .feature_g4(feature_g4),

        .mean_peak(mean_peak),
        .mean_zcr(mean_zcr),
        .mean_energy(mean_energy),
        .mean_g1(mean_g1),
        .mean_g2(mean_g2),
        .mean_g3(mean_g3),
        .mean_g4(mean_g4),

        .learning_initialized(learning_initialized)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    task send_features;
        begin
            @(negedge clk);
            features_valid = 1;

            @(negedge clk);
            features_valid = 0;

            // Shared engine needs time to process all 7 features
            repeat (20) @(posedge clk);
        end
    endtask

    initial begin

        reset_n = 0;
        clear = 0;
        learn_enable = 0;
        features_valid = 0;

        feature_peak   = 1000;
        feature_zcr    = 10;
        feature_energy = 50000;
        feature_g1     = 200;
        feature_g2     = 300;
        feature_g3     = 400;
        feature_g4     = 500;

        #500;
        reset_n = 1;

        learn_enable = 1;

        for (i = 0; i < 50; i = i + 1)
            send_features();

        #100;

        if (
            learning_initialized &&
            mean_peak   == 1000 &&
            mean_zcr    == 10 &&
            mean_energy == 50000 &&
            mean_g1     == 200 &&
            mean_g2     == 300 &&
            mean_g3     == 400 &&
            mean_g4     == 500
        )
            $display("TEST LEARNING BANK: PASS");
        else
            $display(
                "TEST LEARNING BANK: FAIL P=%0d Z=%0d E=%0d G1=%0d G2=%0d G3=%0d G4=%0d INIT=%b",
                mean_peak,
                mean_zcr,
                mean_energy,
                mean_g1,
                mean_g2,
                mean_g3,
                mean_g4,
                learning_initialized
            );

        $finish;
    end

endmodule