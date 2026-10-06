module anomaly_score #(
    parameter integer THRESHOLD_SHIFT = 2
)(
    input wire clk,
    input wire reset_n,
    input wire features_valid,

    input wire [31:0] feature_peak,
    input wire [31:0] feature_zcr,
    input wire [31:0] feature_energy,
    input wire [31:0] feature_g1,
    input wire [31:0] feature_g2,
    input wire [31:0] feature_g3,
    input wire [31:0] feature_g4,

    input wire [31:0] mean_peak,
    input wire [31:0] mean_zcr,
    input wire [31:0] mean_energy,
    input wire [31:0] mean_g1,
    input wire [31:0] mean_g2,
    input wire [31:0] mean_g3,
    input wire [31:0] mean_g4,

    input wire [63:0] var_peak,
    input wire [63:0] var_zcr,
    input wire [63:0] var_energy,
    input wire [63:0] var_g1,
    input wire [63:0] var_g2,
    input wire [63:0] var_g3,
    input wire [63:0] var_g4,

    output reg [3:0] anomaly_points,
    output reg       anomaly_valid
);

    function automatic is_anomaly;
        input [31:0] feature;
        input [31:0] mean;
        input [63:0] variance;

        reg signed [32:0] diff;
        reg [65:0] diff_sq;
        reg [65:0] threshold;
        begin
            diff = $signed({1'b0, feature}) -
                   $signed({1'b0, mean});

            diff_sq = diff * diff;

            if (variance == 0)
                threshold = 66'd16;
            else
                threshold =
                    ({2'b00, variance} << THRESHOLD_SHIFT);

            is_anomaly = (diff_sq > threshold);
        end
    endfunction

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            anomaly_points <= 0;
            anomaly_valid  <= 0;
        end
        else begin
            anomaly_valid <= 0;

            if (features_valid) begin

                anomaly_points <=
                    is_anomaly(feature_peak,   mean_peak,   var_peak)   +
                    is_anomaly(feature_zcr,    mean_zcr,    var_zcr)    +
                    is_anomaly(feature_energy, mean_energy, var_energy) +
                    is_anomaly(feature_g1,     mean_g1,     var_g1)     +
                    is_anomaly(feature_g2,     mean_g2,     var_g2)     +
                    is_anomaly(feature_g3,     mean_g3,     var_g3)     +
                    is_anomaly(feature_g4,     mean_g4,     var_g4);

                anomaly_valid <= 1;
            end
        end
    end

endmodule