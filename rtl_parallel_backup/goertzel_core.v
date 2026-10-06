module goertzel_core (
    input  wire clk,
    input  wire reset_n,

    input  wire sample_valid,
    input  wire window_first,
    input  wire window_last,

    input  wire signed [16:0] sample_in,
    input  wire signed [15:0] coeff_q14,

    output reg  [79:0] power_value,
    output reg         power_valid
);

    reg signed [39:0] s1;
    reg signed [39:0] s2;

    wire signed [39:0] sample_ext =
        {{23{sample_in[16]}}, sample_in};

    wire signed [55:0] mult_s1 =
        $signed(s1) * $signed(coeff_q14);

    wire signed [55:0] scaled_s1_full =
        mult_s1 >>> 14;

    wire signed [39:0] scaled_s1 =
        scaled_s1_full[39:0];

    wire signed [39:0] s0 =
        sample_ext + scaled_s1 - s2;

    wire signed [79:0] s0_sq =
        $signed(s0) * $signed(s0);

    wire signed [79:0] s1_sq =
        $signed(s1) * $signed(s1);

    wire signed [55:0] mult_s0 =
        $signed(s0) * $signed(coeff_q14);

    wire signed [55:0] scaled_s0_full =
        mult_s0 >>> 14;

    wire signed [39:0] scaled_s0 =
        scaled_s0_full[39:0];

    wire signed [79:0] cross_term =
        $signed(scaled_s0) * $signed(s1);

    wire signed [80:0] power_calc =
        $signed({1'b0, s0_sq}) +
        $signed({1'b0, s1_sq}) -
        $signed({cross_term[79], cross_term});

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            s1          <= 0;
            s2          <= 0;
            power_value <= 0;
            power_valid <= 0;

        end else begin

            power_valid <= 0;

            if (sample_valid) begin

                if (window_first) begin
                    s1 <= sample_ext;
                    s2 <= 0;

                end else if (window_last) begin

                    power_value <= power_calc[79:0];
                    power_valid <= 1;

                    s1 <= 0;
                    s2 <= 0;

                end else begin

                    s2 <= s1;
                    s1 <= s0;

                end
            end
        end
    end

endmodule