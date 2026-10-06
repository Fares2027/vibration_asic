`timescale 1ns/1ps

module tb_peak_detector;

    reg clk;
    reg reset_n;
    reg sample_valid;
    reg window_first;
    reg window_last;

    reg signed [16:0] vib_x;
    reg signed [16:0] vib_y;
    reg signed [16:0] vib_z;

    wire [16:0] peak_value;
    wire peak_valid;

    integer i;

    peak_detector dut (
        .clk(clk),
        .reset_n(reset_n),

        .sample_valid(sample_valid),
        .window_first(window_first),
        .window_last(window_last),

        .vib_x(vib_x),
        .vib_y(vib_y),
        .vib_z(vib_z),

        .peak_value(peak_value),
        .peak_valid(peak_valid)
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

        send_sample(100, -200, 50, 1, 0);

        for (i = 1; i < 100; i = i + 1)
            send_sample(300, -400, 200, 0, 0);

        // Largest vibration in entire window
        send_sample(-2500, 500, 100, 0, 0);

        for (i = 101; i < 255; i = i + 1)
            send_sample(600, 700, -800, 0, 0);

        send_sample(900, -1000, 1100, 0, 1);

      
        #10;

        if (peak_value == 2500)
            $display("TEST PEAK DETECTOR: PASS");
        else
            $display(
                "TEST PEAK DETECTOR: FAIL PEAK=%0d",
                peak_value
            );

        $finish;
    end

endmodule