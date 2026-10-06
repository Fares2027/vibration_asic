module goertzel_bank (
    input  wire clk,
    input  wire reset_n,

    input  wire sample_valid,
    input  wire window_first,
    input  wire window_last,

    input  wire signed [16:0] sample_in,

    input  wire signed [15:0] coeff_1,
    input  wire signed [15:0] coeff_2,
    input  wire signed [15:0] coeff_3,
    input  wire signed [15:0] coeff_4,

    output wire [79:0] power_1,
    output wire [79:0] power_2,
    output wire [79:0] power_3,
    output wire [79:0] power_4,

    output wire powers_valid
);

    wire valid_1;
    wire valid_2;
    wire valid_3;
    wire valid_4;

    goertzel_core g1 (
        .clk(clk),
        .reset_n(reset_n),
        .sample_valid(sample_valid),
        .window_first(window_first),
        .window_last(window_last),
        .sample_in(sample_in),
        .coeff_q14(coeff_1),
        .power_value(power_1),
        .power_valid(valid_1)
    );

    goertzel_core g2 (
        .clk(clk),
        .reset_n(reset_n),
        .sample_valid(sample_valid),
        .window_first(window_first),
        .window_last(window_last),
        .sample_in(sample_in),
        .coeff_q14(coeff_2),
        .power_value(power_2),
        .power_valid(valid_2)
    );

    goertzel_core g3 (
        .clk(clk),
        .reset_n(reset_n),
        .sample_valid(sample_valid),
        .window_first(window_first),
        .window_last(window_last),
        .sample_in(sample_in),
        .coeff_q14(coeff_3),
        .power_value(power_3),
        .power_valid(valid_3)
    );

    goertzel_core g4 (
        .clk(clk),
        .reset_n(reset_n),
        .sample_valid(sample_valid),
        .window_first(window_first),
        .window_last(window_last),
        .sample_in(sample_in),
        .coeff_q14(coeff_4),
        .power_value(power_4),
        .power_valid(valid_4)
    );

    assign powers_valid =
        valid_1 & valid_2 & valid_3 & valid_4;

endmodule