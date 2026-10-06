module feature_scaler #(
    parameter integer ENERGY_SHIFT = 2,
    parameter integer G1_SHIFT = 24,
    parameter integer G2_SHIFT = 24,
    parameter integer G3_SHIFT = 24,
    parameter integer G4_SHIFT = 24
)(
    input  wire [16:0] peak_value,
    input  wire [9:0]  zcr_value,
    input  wire [33:0] energy_value,

    input  wire [79:0] power_1,
    input  wire [79:0] power_2,
    input  wire [79:0] power_3,
    input  wire [79:0] power_4,

    output wire [31:0] feature_peak,
    output wire [31:0] feature_zcr,
    output wire [31:0] feature_energy,
    output wire [31:0] feature_g1,
    output wire [31:0] feature_g2,
    output wire [31:0] feature_g3,
    output wire [31:0] feature_g4
);

    function [31:0] scale80;
        input [79:0] value;
        input integer shift;
        reg [79:0] shifted;
        begin
            shifted = value >> shift;

            if (|shifted[79:32])
                scale80 = 32'hFFFFFFFF;
            else
                scale80 = shifted[31:0];
        end
    endfunction

    wire [33:0] energy_shifted =
        energy_value >> ENERGY_SHIFT;

    assign feature_peak = {15'd0, peak_value};
    assign feature_zcr  = {22'd0, zcr_value};

    assign feature_energy =
        (|energy_shifted[33:32]) ?
        32'hFFFFFFFF :
        energy_shifted[31:0];

    assign feature_g1 = scale80(power_1, G1_SHIFT);
    assign feature_g2 = scale80(power_2, G2_SHIFT);
    assign feature_g3 = scale80(power_3, G3_SHIFT);
    assign feature_g4 = scale80(power_4, G4_SHIFT);

endmodule