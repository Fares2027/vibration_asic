module running_stats #(
    parameter integer SHIFT = 4
)(
    input  wire clk,
    input  wire reset_n,
    input  wire clear,
    input  wire learn_enable,
    input  wire feature_valid,

    input  wire [31:0] feature_in,

    output reg  [31:0] mean_value,
    output reg  [63:0] variance_value,
    output reg         initialized
);

    wire signed [32:0] difference =
        $signed({1'b0, feature_in}) -
        $signed({1'b0, mean_value});

    wire signed [65:0] difference_sq =
        difference * difference;

    wire signed [64:0] variance_error =
        $signed({1'b0, difference_sq[63:0]}) -
        $signed({1'b0, variance_value});

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mean_value     <= 0;
            variance_value <= 0;
            initialized    <= 0;
        end
        else if (clear) begin
            mean_value     <= 0;
            variance_value <= 0;
            initialized    <= 0;
        end
        else if (learn_enable && feature_valid) begin

            if (!initialized) begin
                mean_value     <= feature_in;
                variance_value <= 0;
                initialized    <= 1;
            end
            else begin

                mean_value <=
                    $signed({1'b0, mean_value}) +
                    (difference >>> SHIFT);

                variance_value <=
                    $signed({1'b0, variance_value}) +
                    (variance_error >>> SHIFT);

            end
        end
    end

endmodule