module vibration_asic_top #(
    parameter integer CLK_HZ = 10_000_000,
    parameter integer SAMPLE_HZ = 400,
    parameter integer LEARNING_WINDOWS = 94
) (
    input  wire clk,
    input  wire reset_n,
    input  wire enable,
    input  wire relearn,
    input  wire clear_alert,

    input  wire accel_miso,

    output wire accel_sclk,
    output wire accel_mosi,
    output wire accel_cs_n,

    output wire alert,

    output wire sensor_ok,
    output wire initialized,
    output wire status_learning,
    output wire status_monitor
);

    // ============================================================
    // SAMPLE CLOCK ENABLE
    // ============================================================

    wire sample_tick;

    sample_tick #(
        .CLK_HZ(CLK_HZ),
        .SAMPLE_HZ(SAMPLE_HZ)
    ) sample_tick_inst (
        .clk(clk),
        .reset_n(reset_n),
        .enable(enable),
        .sample_tick(sample_tick)
    );


    // ============================================================
    // SENSOR CONTROLLER
    // ============================================================

    reg start_init;

    wire sensor_sample_valid;

    wire signed [15:0] accel_x;
    wire signed [15:0] accel_y;
    wire signed [15:0] accel_z;

    lis3dh_controller sensor_inst (
        .clk(clk),
        .reset_n(reset_n),
        .start_init(start_init),
        .sample_tick(sample_tick),
        .miso(accel_miso),

        .sclk(accel_sclk),
        .mosi(accel_mosi),
        .cs_n(accel_cs_n),

        .sensor_ok(sensor_ok),
        .initialized(initialized),
        .sample_valid(sensor_sample_valid),

        .accel_x(accel_x),
        .accel_y(accel_y),
        .accel_z(accel_z)
    );


    // ============================================================
    // DC / GRAVITY REMOVAL
    // ============================================================

    wire signed [16:0] vib_x;
    wire signed [16:0] vib_y;
    wire signed [16:0] vib_z;

    dc_filter dc_inst (
        .clk(clk),
        .reset_n(reset_n),
        .sample_valid(sensor_sample_valid),

        .accel_x(accel_x),
        .accel_y(accel_y),
        .accel_z(accel_z),

        .vib_x(vib_x),
        .vib_y(vib_y),
        .vib_z(vib_z)
    );


    reg vib_valid;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            vib_valid <= 1'b0;
        else
            vib_valid <= sensor_sample_valid;
    end


    // ============================================================
    // WINDOW ENGINE
    // ============================================================

    wire window_first;
    wire window_last;
    wire window_done;

    wire [7:0] sample_index;

    window_engine window_inst (
        .clk(clk),
        .reset_n(reset_n),
        .sample_valid(vib_valid),

        .window_first(window_first),
        .window_last(window_last),
        .window_done(window_done),
        .sample_index(sample_index)
    );


    // ============================================================
    // PEAK
    // ============================================================

    wire [16:0] peak_value;
    wire peak_valid;

    peak_detector peak_inst (
        .clk(clk),
        .reset_n(reset_n),

        .sample_valid(vib_valid),
        .window_first(window_first),
        .window_last(window_last),

        .vib_x(vib_x),
        .vib_y(vib_y),
        .vib_z(vib_z),

        .peak_value(peak_value),
        .peak_valid(peak_valid)
    );


    // ============================================================
    // ZCR
    // ============================================================

    wire [9:0] zcr_value;
    wire zcr_valid;

    zcr_detector zcr_inst (
        .clk(clk),
        .reset_n(reset_n),

        .sample_valid(vib_valid),
        .window_first(window_first),
        .window_last(window_last),

        .vib_x(vib_x),
        .vib_y(vib_y),
        .vib_z(vib_z),

        .zcr_value(zcr_value),
        .zcr_valid(zcr_valid)
    );


    // ============================================================
    // ENERGY
    // ============================================================

    wire [33:0] energy_value;
    wire energy_valid;

    rms_energy energy_inst (
        .clk(clk),
        .reset_n(reset_n),

        .sample_valid(vib_valid),
        .window_first(window_first),
        .window_last(window_last),

        .vib_x(vib_x),
        .vib_y(vib_y),
        .vib_z(vib_z),

        .energy_value(energy_value),
        .energy_valid(energy_valid)
    );

    // ============================================================
    // SHARED GOERTZEL ENGINE
    // ============================================================

    wire [79:0] power_1;
    wire [79:0] power_2;
    wire [79:0] power_3;
    wire [79:0] power_4;
    wire        powers_valid;

    goertzel_shared goertzel_inst (
        .clk(clk),
        .reset_n(reset_n),

        .sample_valid(vib_valid),
        .window_first(window_first),
        .window_last(window_last),

        .vib_x(vib_x),
        .vib_y(vib_y),
        .vib_z(vib_z),

        .power_1(power_1),
        .power_2(power_2),
        .power_3(power_3),
        .power_4(power_4),

        .powers_valid(powers_valid)
    );


    // ============================================================
    // FEATURE SCALING
    // ============================================================

    wire [31:0] feature_peak;
    wire [31:0] feature_zcr;
    wire [31:0] feature_energy;
    wire [31:0] feature_g1;
    wire [31:0] feature_g2;
    wire [31:0] feature_g3;
    wire [31:0] feature_g4;

    feature_scaler scaler_inst (
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


    wire features_valid = powers_valid;


    // ============================================================
    // LEARNING / MONITOR MODE
    // ============================================================

    reg learning_mode;

    reg [15:0] learning_windows;

    assign status_learning = learning_mode;
    assign status_monitor  = initialized && !learning_mode;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin

            start_init       <= 1'b0;
            learning_mode    <= 1'b1;
            learning_windows <= 0;

        end else begin

            start_init <= 1'b0;

            if (enable && !initialized)
                start_init <= 1'b1;

            if (relearn) begin
                learning_mode    <= 1'b1;
                learning_windows <= 0;
            end

            else if (learning_mode && features_valid) begin

                // 94 × 0.64 s ≈ 60 seconds

                if (learning_windows == LEARNING_WINDOWS - 1) begin
                    learning_mode <= 1'b0;
                end
                else begin
                    learning_windows <=
                        learning_windows + 1'b1;
                end
            end
        end
    end


    // ============================================================
    // LEARNING BANK
    // ============================================================

    wire [31:0] mean_peak;
    wire [31:0] mean_zcr;
    wire [31:0] mean_energy;
    wire [31:0] mean_g1;
    wire [31:0] mean_g2;
    wire [31:0] mean_g3;
    wire [31:0] mean_g4;

    wire [63:0] var_peak;
    wire [63:0] var_zcr;
    wire [63:0] var_energy;
    wire [63:0] var_g1;
    wire [63:0] var_g2;
    wire [63:0] var_g3;
    wire [63:0] var_g4;

    wire learning_initialized;

    learning_bank learning_inst (
        .clk(clk),
        .reset_n(reset_n),

        .clear(relearn),
        .learn_enable(learning_mode),
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

        .learning_initialized(learning_initialized)
    );


    // ============================================================
    // ANOMALY SCORE
    // ============================================================

    wire [3:0] anomaly_points;
    wire anomaly_valid;

    anomaly_score anomaly_inst (
        .clk(clk),
        .reset_n(reset_n),

        .features_valid(
            features_valid &&
            !learning_mode &&
            learning_initialized
        ),

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


    // ============================================================
    // ALERT
    // ============================================================

    wire [2:0] persistence_count;

    alert_persistence alert_inst (
        .clk(clk),
        .reset_n(reset_n),

        .anomaly_valid(anomaly_valid),
        .anomaly_points(anomaly_points),

        .clear_alert(clear_alert | relearn),

        .alert(alert),
        .persistence_count(persistence_count)
    );

endmodule