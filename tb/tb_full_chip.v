`timescale 1ns/1ps

module tb_full_chip;

    reg clk;
    reg reset_n;
    reg enable;
    reg relearn;
    reg clear_alert;
    reg accel_miso;

    wire accel_sclk;
    wire accel_mosi;
    wire accel_cs_n;
    wire alert;
    wire sensor_ok;
    wire initialized;
    wire status_learning;
    wire status_monitor;

    reg [63:0] response;
    integer response_index;
    integer transaction;
    integer sample_number;
    reg anomaly_phase;

    reg signed [15:0] x_value;
    reg signed [15:0] y_value;
    reg signed [15:0] z_value;

    vibration_asic_top #(
        .CLK_HZ(100000),
        .SAMPLE_HZ(100),
        .LEARNING_WINDOWS(2)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .enable(enable),
        .relearn(relearn),
        .clear_alert(clear_alert),

        .accel_miso(accel_miso),

        .accel_sclk(accel_sclk),
        .accel_mosi(accel_mosi),
        .accel_cs_n(accel_cs_n),

        .alert(alert),
        .sensor_ok(sensor_ok),
        .initialized(initialized),
        .status_learning(status_learning),
        .status_monitor(status_monitor)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;   // 10 MHz simulation clock
    end

    initial begin
        transaction = 0;
        sample_number = 0;
        anomaly_phase = 0;
        accel_miso = 0;
    end

    // Simulated LIS3DH
    always @(negedge accel_cs_n) begin

        transaction = transaction + 1;

        case (transaction)

            // WHO_AM_I
            1: begin
                response = 64'h0000000000000033;
                response_index = 15;
            end

            // CTRL_REG1 write
            2: begin
                response = 0;
                response_index = 15;
            end

            // CTRL_REG4 write
            3: begin
                response = 0;
                response_index = 15;
            end

            // XYZ reads
            default: begin

                sample_number = sample_number + 1;

                if (!anomaly_phase) begin
                    // Normal machine
                    x_value = 16'sd0;
                    y_value = 16'sd0;
                    z_value = 16'sd0;
                end
                else begin
                    // Strong imbalance/vibration
                    if (sample_number[0])
                        x_value = 16'sd6000;
                    else
                        x_value = -16'sd6000;

                    y_value = 16'sd0;
                    z_value = 16'sd0;
                end

                response = {
                    8'h00,

                    x_value[7:0],
                    x_value[15:8],

                    y_value[7:0],
                    y_value[15:8],

                    z_value[7:0],
                    z_value[15:8],

                    8'h00
                };

                response = response >> 8;

                response_index = 55;
            end
        endcase

        accel_miso = response[response_index];
    end

    always @(negedge accel_sclk) begin
        if (!accel_cs_n && response_index > 0) begin
            response_index = response_index - 1;
            accel_miso = response[response_index];
        end
    end

    initial begin

        reset_n = 0;
        enable = 0;
        relearn = 0;
        clear_alert = 0;

        #1000;

        reset_n = 1;
        enable = 1;

        // Sensor initialization
        wait(initialized);

        $display("FULL CHIP: SENSOR INITIALIZED");

        // Wait until learning finishes
        wait(status_monitor);

        $display("FULL CHIP: LEARNING COMPLETE");

        // Introduce simulated imbalance
        anomaly_phase = 1;

        $display("FULL CHIP: IMBALANCE INTRODUCED");

        // Wait for persistence logic to trigger
        wait(alert);

        $display("FULL CHIP: ALERT TRIGGERED");
        $display("FULL CHIP SIMULATION: PASS");

        #1000;
        $finish;
    end

    // Safety timeout
    initial begin
        #1000000000;
        $display("FULL CHIP SIMULATION: TIMEOUT FAIL");
        $finish;
    end

endmodule
