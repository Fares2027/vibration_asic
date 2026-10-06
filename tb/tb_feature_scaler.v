`timescale 1ns/1ps

module tb_feature_scaler;

    reg [16:0] peak_value;
    reg [9:0] zcr_value;
    reg [33:0] energy_value;

    reg [79:0] power_1;
    reg [79:0] power_2;
    reg [79:0] power_3;
    reg [79:0] power_4;

    wire [31:0] feature_peak;
    wire [31:0] feature_zcr;
    wire [31:0] feature_energy;
    wire [31:0] feature_g1;
    wire [31:0] feature_g2;
    wire [31:0] feature_g3;
    wire [31:0] feature_g4;

    feature_scaler dut (
        .peak_value(peak_value),
        .zcr_value(zcr_value),
        .energy_value(energy_value),

        .power_1(power_1),
        .power_2(power_2),
        .power_3(power_3),
        .power_4(power_4),

        .feature_peak(feature_peak),
        .feature_zcr(feature_zcr),
        .feature_energy(feature_energy),
        .feature_g1(feature_g1),
        .feature_g2(feature_g2),
        .feature_g3(feature_g3),
        .feature_g4(feature_g4)
    );

    initial begin

        peak_value   = 17'd2500;
        zcr_value    = 10'd5;
        energy_value = 34'd140000;

        power_1 = 80'd1677721600;
        power_2 = 80'd3355443200;
        power_3 = 80'd5033164800;
        power_4 = 80'd6710886400;

        #10;

        if (
            feature_peak   == 32'd2500 &&
            feature_zcr    == 32'd5 &&
            feature_energy == 32'd35000 &&
            feature_g1     == 32'd100 &&
            feature_g2     == 32'd200 &&
            feature_g3     == 32'd300 &&
            feature_g4     == 32'd400
        )
            $display("TEST FEATURE SCALER: PASS");
        else
            $display(
                "TEST FEATURE SCALER: FAIL %0d %0d %0d %0d %0d %0d %0d",
                feature_peak,
                feature_zcr,
                feature_energy,
                feature_g1,
                feature_g2,
                feature_g3,
                feature_g4
            );

        $finish;
    end

endmodule