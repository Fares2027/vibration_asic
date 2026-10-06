`timescale 1ns/1ps

module tb_anomaly_score;

    reg clk;
    reg reset_n;
    reg features_valid;

    reg [31:0] feature_peak, feature_zcr, feature_energy;
    reg [31:0] feature_g1, feature_g2, feature_g3, feature_g4;

    reg [31:0] mean_peak, mean_zcr, mean_energy;
    reg [31:0] mean_g1, mean_g2, mean_g3, mean_g4;

    reg [63:0] var_peak, var_zcr, var_energy;
    reg [63:0] var_g1, var_g2, var_g3, var_g4;

    wire [3:0] anomaly_points;
    wire anomaly_valid;

    anomaly_score dut (
        .clk(clk),
        .reset_n(reset_n),
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

        .var_peak(var_peak),
        .var_zcr(var_zcr),
        .var_energy(var_energy),
        .var_g1(var_g1),
        .var_g2(var_g2),
        .var_g3(var_g3),
        .var_g4(var_g4),

        .anomaly_points(anomaly_points),
        .anomaly_valid(anomaly_valid)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    initial begin

        reset_n = 0;
        features_valid = 0;

        mean_peak   = 1000;
        mean_zcr    = 10;
        mean_energy = 50000;
        mean_g1 = 200;
        mean_g2 = 300;
        mean_g3 = 400;
        mean_g4 = 500;

        var_peak   = 10000;
        var_zcr    = 4;
        var_energy = 1000000;
        var_g1 = 100;
        var_g2 = 100;
        var_g3 = 100;
        var_g4 = 100;

        #500;
        reset_n = 1;

        // Normal features
        feature_peak   = 1050;
        feature_zcr    = 11;
        feature_energy = 50500;
        feature_g1 = 205;
        feature_g2 = 295;
        feature_g3 = 405;
        feature_g4 = 495;

        @(negedge clk);
        features_valid = 1;

        @(negedge clk);
        features_valid = 0;

        @(posedge anomaly_valid);
        #10;

        if (anomaly_points == 0)
            $display("NORMAL SCORE: PASS");
        else
            $display("NORMAL SCORE: FAIL SCORE=%0d", anomaly_points);

        // Make 3 features anomalous
        feature_peak   = 1500;
        feature_zcr    = 11;
        feature_energy = 55000;
        feature_g1 = 260;
        feature_g2 = 295;
        feature_g3 = 405;
        feature_g4 = 495;

        @(negedge clk);
        features_valid = 1;

        @(negedge clk);
        features_valid = 0;

        @(posedge anomaly_valid);
        #10;

        if (anomaly_points == 3)
            $display("ANOMALY SCORE: PASS");
        else
            $display(
                "ANOMALY SCORE: FAIL SCORE=%0d",
                anomaly_points
            );

        $finish;
    end

endmodule