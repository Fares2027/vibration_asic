`timescale 1ns/1ps

module tb_zcr_detector;

    reg clk;
    reg reset_n;
    reg sample_valid;
    reg window_first;
    reg window_last;

    reg signed [16:0] vib_x;
    reg signed [16:0] vib_y;
    reg signed [16:0] vib_z;

    wire [9:0] zcr_value;
    wire zcr_valid;

    integer i;

    zcr_detector dut (
        .clk(clk),
        .reset_n(reset_n),

        .sample_valid(sample_valid),
        .window_first(window_first),
        .window_last(window_last),

        .vib_x(vib_x),
        .vib_y(vib_y),
        .vib_z(vib_z),

        .zcr_value(zcr_value),
        .zcr_valid(zcr_valid)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    task send_sample;
        input signed [16:0] x;
        input signed [16:0] y;
        input signed [16:0] z;
        input first_s;
        input last_s;

        begin
            @(negedge clk);

            vib_x = x;
            vib_y = y;
            vib_z = z;

            window_first = first_s;
            window_last  = last_s;
            sample_valid = 1;

            @(negedge clk);

            sample_valid = 0;
            window_first = 0;
            window_last  = 0;
        end
    endtask

    initial begin

        reset_n = 0;
        sample_valid = 0;
        window_first = 0;
        window_last = 0;

        vib_x = 0;
        vib_y = 0;
        vib_z = 0;

        #500;
        reset_n = 1;

        // First sample: no crossing counted
        send_sample(100, 100, 100, 1, 0);

        // X crosses: +1
        send_sample(-100, 100, 100, 0, 0);

        // Y and Z cross: +2
        send_sample(-100, -100, -100, 0, 0);

        // X and Y cross: +2
        send_sample(100, 100, -100, 0, 0);

        // Fill rest without additional crossings
        for (i = 4; i < 255; i = i + 1)
            send_sample(100, 100, -100, 0, 0);

        send_sample(100, 100, -100, 0, 1);

        #10;

        if (zcr_value == 5)
            $display("TEST ZCR DETECTOR: PASS");
        else
            $display(
                "TEST ZCR DETECTOR: FAIL ZCR=%0d",
                zcr_value
            );

        $finish;
    end

endmodule