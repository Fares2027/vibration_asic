module learning_bank (
    input  wire clk,
    input  wire reset_n,
    input  wire clear,
    input  wire learn_enable,
    input  wire features_valid,

    input  wire [31:0] feature_peak,
    input  wire [31:0] feature_zcr,
    input  wire [31:0] feature_energy,
    input  wire [31:0] feature_g1,
    input  wire [31:0] feature_g2,
    input  wire [31:0] feature_g3,
    input  wire [31:0] feature_g4,

    output wire [31:0] mean_peak,
    output wire [31:0] mean_zcr,
    output wire [31:0] mean_energy,
    output wire [31:0] mean_g1,
    output wire [31:0] mean_g2,
    output wire [31:0] mean_g3,
    output wire [31:0] mean_g4,

    output wire [63:0] var_peak,
    output wire [63:0] var_zcr,
    output wire [63:0] var_energy,
    output wire [63:0] var_g1,
    output wire [63:0] var_g2,
    output wire [63:0] var_g3,
    output wire [63:0] var_g4,

    output wire learning_initialized
);

    wire init_peak;
    wire init_zcr;
    wire init_energy;
    wire init_g1;
    wire init_g2;
    wire init_g3;
    wire init_g4;

    running_stats s_peak (
        .clk(clk),
        .reset_n(reset_n),
        .clear(clear),
        .learn_enable(learn_enable),
        .feature_valid(features_valid),
        .feature_in(feature_peak),
        .mean_value(mean_peak),
        .variance_value(var_peak),
        .initialized(init_peak)
    );

    running_stats s_zcr (
        .clk(clk),
        .reset_n(reset_n),
        .clear(clear),
        .learn_enable(learn_enable),
        .feature_valid(features_valid),
        .feature_in(feature_zcr),
        .mean_value(mean_zcr),
        .variance_value(var_zcr),
        .initialized(init_zcr)
    );

    running_stats s_energy (
        .clk(clk),
        .reset_n(reset_n),
        .clear(clear),
        .learn_enable(learn_enable),
        .feature_valid(features_valid),
        .feature_in(feature_energy),
        .mean_value(mean_energy),
        .variance_value(var_energy),
        .initialized(init_energy)
    );

    running_stats s_g1 (
        .clk(clk),
        .reset_n(reset_n),
        .clear(clear),
        .learn_enable(learn_enable),
        .feature_valid(features_valid),
        .feature_in(feature_g1),
        .mean_value(mean_g1),
        .variance_value(var_g1),
        .initialized(init_g1)
    );

    running_stats s_g2 (
        .clk(clk),
        .reset_n(reset_n),
        .clear(clear),
        .learn_enable(learn_enable),
        .feature_valid(features_valid),
        .feature_in(feature_g2),
        .mean_value(mean_g2),
        .variance_value(var_g2),
        .initialized(init_g2)
    );

    running_stats s_g3 (
        .clk(clk),
        .reset_n(reset_n),
        .clear(clear),
        .learn_enable(learn_enable),
        .feature_valid(features_valid),
        .feature_in(feature_g3),
        .mean_value(mean_g3),
        .variance_value(var_g3),
        .initialized(init_g3)
    );

    running_stats s_g4 (
        .clk(clk),
        .reset_n(reset_n),
        .clear(clear),
        .learn_enable(learn_enable),
        .feature_valid(features_valid),
        .feature_in(feature_g4),
        .mean_value(mean_g4),
        .variance_value(var_g4),
        .initialized(init_g4)
    );

    assign learning_initialized =
        init_peak &
        init_zcr &
        init_energy &
        init_g1 &
        init_g2 &
        init_g3 &
        init_g4;

endmodule