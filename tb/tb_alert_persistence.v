`timescale 1ns/1ps

module tb_alert_persistence;

    reg clk;
    reg reset_n;
    reg anomaly_valid;
    reg [3:0] anomaly_points;
    reg clear_alert;

    wire alert;
    wire [2:0] persistence_count;

    alert_persistence dut (
        .clk(clk),
        .reset_n(reset_n),

        .anomaly_valid(anomaly_valid),
        .anomaly_points(anomaly_points),

        .clear_alert(clear_alert),

        .alert(alert),
        .persistence_count(persistence_count)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    task send_window;
        input [3:0] points;
        begin
            @(negedge clk);

            anomaly_points = points;
            anomaly_valid = 1;

            @(negedge clk);

            anomaly_valid = 0;
        end
    endtask

    initial begin

        reset_n = 0;
        anomaly_valid = 0;
        anomaly_points = 0;
        clear_alert = 0;

        #500;
        reset_n = 1;

        // Normal
        send_window(1);

        if (alert != 0)
            $display("NORMAL TEST: FAIL");

        // Two anomalous windows only
        send_window(4);
        send_window(5);

        if (alert == 0)
            $display("PERSISTENCE HOLD: PASS");
        else
            $display("PERSISTENCE HOLD: FAIL");

        // Third consecutive anomaly
        send_window(3);

        #10;

        if (alert == 1)
            $display("ALERT TRIGGER: PASS");
        else
            $display("ALERT TRIGGER: FAIL");

        // Clear
        @(negedge clk);
        clear_alert = 1;

        @(negedge clk);
        clear_alert = 0;

        #10;

        if (alert == 0 && persistence_count == 0)
            $display("ALERT CLEAR: PASS");
        else
            $display("ALERT CLEAR: FAIL");

        $finish;
    end

endmodule