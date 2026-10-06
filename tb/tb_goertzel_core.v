`timescale 1ns/1ps

module tb_goertzel_core;

    reg clk;
    reg reset_n;

    reg sample_valid;
    reg window_first;
    reg window_last;

    reg signed [16:0] sample_in;
    reg signed [15:0] coeff_q14;

    wire [79:0] power_value;
    wire power_valid;

    integer i;

    goertzel_core dut (
        .clk(clk),
        .reset_n(reset_n),

        .sample_valid(sample_valid),
        .window_first(window_first),
        .window_last(window_last),

        .sample_in(sample_in),
        .coeff_q14(coeff_q14),

        .power_value(power_value),
        .power_valid(power_valid)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    function signed [16:0] tone25;
        input integer n;
        begin
            case (n % 16)
                 0: tone25 = 0;
                 1: tone25 = 383;
                 2: tone25 = 707;
                 3: tone25 = 924;
                 4: tone25 = 1000;
                 5: tone25 = 924;
                 6: tone25 = 707;
                 7: tone25 = 383;
                 8: tone25 = 0;
                 9: tone25 = -383;
                10: tone25 = -707;
                11: tone25 = -924;
                12: tone25 = -1000;
                13: tone25 = -924;
                14: tone25 = -707;
                15: tone25 = -383;
            endcase
        end
    endfunction

    function signed [16:0] tone50;
        input integer n;
        begin
            case (n % 8)
                0: tone50 = 0;
                1: tone50 = 707;
                2: tone50 = 1000;
                3: tone50 = 707;
                4: tone50 = 0;
                5: tone50 = -707;
                6: tone50 = -1000;
                7: tone50 = -707;
            endcase
        end
    endfunction

    task send_sample;
        input signed [16:0] value;
        input first_s;
        input last_s;

        begin
            @(negedge clk);

            sample_in   = value;
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
        sample_in = 0;

        // 25 Hz coefficient in Q2.14
        coeff_q14 = 16'sd30274;

        #500;
        reset_n = 1;

        // TEST 1: 25 Hz signal
        for (i = 0; i < 256; i = i + 1)
            send_sample(
                tone25(i),
                (i == 0),
                (i == 255)
            );

        #10;

        if (power_value > 80'd10000000000)
            $display("GOERTZEL 25HZ DETECTION: PASS");
        else
            $display(
                "GOERTZEL 25HZ DETECTION: FAIL POWER=%0d",
                power_value
            );

        // TEST 2: 50 Hz signal should be rejected
        for (i = 0; i < 256; i = i + 1)
            send_sample(
                tone50(i),
                (i == 0),
                (i == 255)
            );

        #10;

        if (power_value < 80'd1000000)
            $display("GOERTZEL 50HZ REJECTION: PASS");
        else
            $display(
                "GOERTZEL 50HZ REJECTION: FAIL POWER=%0d",
                power_value
            );

        $finish;
    end

endmodule