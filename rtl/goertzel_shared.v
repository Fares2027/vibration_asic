module goertzel_shared (
    input  wire clk,
    input  wire reset_n,

    input  wire sample_valid,
    input  wire window_first,
    input  wire window_last,

    input  wire signed [16:0] vib_x,
    input  wire signed [16:0] vib_y,
    input  wire signed [16:0] vib_z,

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
    reg [3:0] state;

    integer i;

    localparam ST_IDLE      = 4'd0;
    localparam ST_FIRST     = 4'd1;
    localparam ST_REC_MUL   = 4'd2;
    localparam ST_REC_CALC  = 4'd3;
    localparam ST_S0_SQ     = 4'd4;
    localparam ST_S1_SQ     = 4'd5;
    localparam ST_COEFF_S0  = 4'd6;
    localparam ST_CROSS     = 4'd7;

    reg signed [16:0] current_sample;
    reg signed [15:0] current_coeff;

    wire signed [39:0] sample_ext =
        {{23{current_sample[16]}}, current_sample};

    wire signed [39:0] coeff_ext =
        {{24{current_coeff[15]}}, current_coeff};

    reg signed [39:0] mul_a;
    reg signed [39:0] mul_b;

    wire signed [79:0] mul_result =
        $signed(mul_a) * $signed(mul_b);

    reg signed [39:0] coeff_s1_scaled;
    reg signed [39:0] s0_temp;
    reg signed [39:0] scaled_s0_temp;

    reg signed [79:0] square_s0_temp;
    reg signed [79:0] square_s1_temp;

    wire signed [39:0] recurrence_value =
        sample_ext + coeff_s1_scaled - s2[ctx];

    wire signed [80:0] final_power =
        $signed({1'b0, square_s0_temp}) +
        $signed({1'b0, square_s1_temp}) -
        $signed({mul_result[79], mul_result});


    // Select axis and frequency for current context
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


    // ONE shared multiplier
    always @(*) begin

        mul_a = 0;
        mul_b = 0;

        case (state)

            ST_REC_MUL: begin
                mul_a = s1[ctx];
                mul_b = coeff_ext;
            end

            ST_S0_SQ: begin
                mul_a = s0_temp;
                mul_b = s0_temp;
            end

            ST_S1_SQ: begin
                mul_a = s1[ctx];
                mul_b = s1[ctx];
            end

            ST_COEFF_S0: begin
                mul_a = s0_temp;
                mul_b = coeff_ext;
            end

            ST_CROSS: begin
                mul_a = scaled_s0_temp;
                mul_b = s1[ctx];
            end

        endcase
    end


    always @(posedge clk or negedge reset_n) begin

        if (!reset_n) begin

            state <= ST_IDLE;
            ctx <= 0;

            powers_valid <= 0;

            power_1 <= 0;
            power_2 <= 0;
            power_3 <= 0;
            power_4 <= 0;

            sample_x <= 0;
            sample_y <= 0;
            sample_z <= 0;

            first_latched <= 0;
            last_latched <= 0;

            coeff_s1_scaled <= 0;
            s0_temp <= 0;
            scaled_s0_temp <= 0;

            square_s0_temp <= 0;
            square_s1_temp <= 0;

            for (i = 0; i < 12; i = i + 1) begin
                s1[i] <= 0;
                s2[i] <= 0;
            end

        end else begin

            powers_valid <= 0;

            case (state)

                // ----------------------------------------
                ST_IDLE: begin

                    if (sample_valid) begin

                        sample_x <= vib_x;
                        sample_y <= vib_y;
                        sample_z <= vib_z;

                        first_latched <= window_first;
                        last_latched  <= window_last;

                        ctx <= 0;

                        if (window_last) begin
                            power_1 <= 0;
                            power_2 <= 0;
                            power_3 <= 0;
                            power_4 <= 0;
                        end

                        if (window_first)
                            state <= ST_FIRST;
                        else
                            state <= ST_REC_MUL;
                    end
                end


                // ----------------------------------------
                // First sample does not require multiply
                ST_FIRST: begin

                    s1[ctx] <= sample_ext;
                    s2[ctx] <= 0;

                    if (ctx == 11) begin
                        state <= ST_IDLE;
                    end else begin
                        ctx <= ctx + 1'b1;
                    end
                end


                // ----------------------------------------
                // Multiply s1 × coefficient
                ST_REC_MUL: begin

                    coeff_s1_scaled <=
                        $signed(mul_result) >>> 14;

                    state <= ST_REC_CALC;
                end


                // ----------------------------------------
                // Calculate recurrence
                ST_REC_CALC: begin

                    if (last_latched) begin

                        s0_temp <= recurrence_value;
                        state <= ST_S0_SQ;

                    end else begin

                        s2[ctx] <= s1[ctx];
                        s1[ctx] <= recurrence_value;

                        if (ctx == 11) begin
                            state <= ST_IDLE;
                        end else begin
                            ctx <= ctx + 1'b1;
                            state <= ST_REC_MUL;
                        end
                    end
                end


                // ----------------------------------------
                // s0²
                ST_S0_SQ: begin

                    square_s0_temp <= mul_result;
                    state <= ST_S1_SQ;
                end


                // ----------------------------------------
                // s1²
                ST_S1_SQ: begin

                    square_s1_temp <= mul_result;
                    state <= ST_COEFF_S0;
                end


                // ----------------------------------------
                // coefficient × s0
                ST_COEFF_S0: begin

                    scaled_s0_temp <=
                        $signed(mul_result) >>> 14;

                    state <= ST_CROSS;
                end


                // ----------------------------------------
                // scaled_s0 × s1
                // then calculate final Goertzel power
                ST_CROSS: begin

                    if (!final_power[80]) begin

                        case (ctx[1:0])

                            2'd0:
                                if (final_power[79:0] > power_1)
                                    power_1 <= final_power[79:0];

                            2'd1:
                                if (final_power[79:0] > power_2)
                                    power_2 <= final_power[79:0];

                            2'd2:
                                if (final_power[79:0] > power_3)
                                    power_3 <= final_power[79:0];

                            2'd3:
                                if (final_power[79:0] > power_4)
                                    power_4 <= final_power[79:0];

                        endcase
                    end

                    s1[ctx] <= 0;
                    s2[ctx] <= 0;

                    if (ctx == 11) begin

                        powers_valid <= 1;
                        state <= ST_IDLE;

                    end else begin

                        ctx <= ctx + 1'b1;
                        state <= ST_REC_MUL;
                    end
                end

            endcase
        end
    end

endmodule