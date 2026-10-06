module goertzel_shared (
    input wire clk,
    input wire reset_n,

    input wire sample_valid,
    input wire window_first,
    input wire window_last,

    input wire signed [16:0] vib_x,
    input wire signed [16:0] vib_y,
    input wire signed [16:0] vib_z,

    output reg [79:0] power_1,
    output reg [79:0] power_2,
    output reg [79:0] power_3,
    output reg [79:0] power_4,

    output reg powers_valid
);

    reg signed [39:0] s1 [0:11];
    reg signed [39:0] s2 [0:11];

    reg signed [16:0] sample_x;
    reg signed [16:0] sample_y;
    reg signed [16:0] sample_z;

    reg first_latched;
    reg last_latched;

    reg [3:0] ctx;
    reg busy;

    integer i;

    reg signed [16:0] current_sample;
    reg signed [15:0] current_coeff;

    wire signed [39:0] sample_ext =
        {{23{current_sample[16]}}, current_sample};

    wire signed [55:0] coeff_mult =
        $signed(s1[ctx]) * $signed(current_coeff);

    wire signed [39:0] scaled_s1 =
        coeff_mult >>> 14;

    wire signed [39:0] s0 =
        sample_ext + scaled_s1 - s2[ctx];

    wire signed [79:0] s0_sq =
        $signed(s0) * $signed(s0);

    wire signed [79:0] s1_sq =
        $signed(s1[ctx]) * $signed(s1[ctx]);

    wire signed [55:0] coeff_s0_mult =
        $signed(s0) * $signed(current_coeff);

    wire signed [39:0] scaled_s0 =
        coeff_s0_mult >>> 14;

    wire signed [79:0] cross_term =
        $signed(scaled_s0) * $signed(s1[ctx]);

    wire signed [80:0] power_calc =
        $signed({1'b0, s0_sq}) +
        $signed({1'b0, s1_sq}) -
        $signed({cross_term[79], cross_term});


    always @(*) begin

        case (ctx[3:2])
            2'd0: current_sample = sample_x;
            2'd1: current_sample = sample_y;
            default: current_sample = sample_z;
        endcase

        case (ctx[1:0])
            2'd0: current_coeff = 16'sd30274;   // 25 Hz
            2'd1: current_coeff = 16'sd23170;   // 50 Hz
            2'd2: current_coeff = 16'sd0;       // 100 Hz
            default:
                current_coeff = -16'sd23170;    // 150 Hz
        endcase
    end


    always @(posedge clk or negedge reset_n) begin

        if (!reset_n) begin

            busy <= 0;
            ctx <= 0;
            powers_valid <= 0;

            power_1 <= 0;
            power_2 <= 0;
            power_3 <= 0;
            power_4 <= 0;

            for (i = 0; i < 12; i = i + 1) begin
                s1[i] <= 0;
                s2[i] <= 0;
            end

        end else begin

            powers_valid <= 0;

            if (!busy) begin

                if (sample_valid) begin

                    sample_x <= vib_x;
                    sample_y <= vib_y;
                    sample_z <= vib_z;

                    first_latched <= window_first;
                    last_latched  <= window_last;

                    ctx <= 0;
                    busy <= 1;

                    if (window_last) begin
                        power_1 <= 0;
                        power_2 <= 0;
                        power_3 <= 0;
                        power_4 <= 0;
                    end
                end

            end else begin

                if (first_latched) begin

                    s1[ctx] <= sample_ext;
                    s2[ctx] <= 0;

                end else if (last_latched) begin

                    case (ctx[1:0])

                        2'd0:
                            if (power_calc[79:0] > power_1)
                                power_1 <= power_calc[79:0];

                        2'd1:
                            if (power_calc[79:0] > power_2)
                                power_2 <= power_calc[79:0];

                        2'd2:
                            if (power_calc[79:0] > power_3)
                                power_3 <= power_calc[79:0];

                        2'd3:
                            if (power_calc[79:0] > power_4)
                                power_4 <= power_calc[79:0];

                    endcase

                    s1[ctx] <= 0;
                    s2[ctx] <= 0;

                end else begin

                    s2[ctx] <= s1[ctx];
                    s1[ctx] <= s0;

                end


                if (ctx == 11) begin

                    busy <= 0;

                    if (last_latched)
                        powers_valid <= 1;

                end else begin

                    ctx <= ctx + 1'b1;

                end
            end
        end
    end

endmodule