`timescale 1ns/1ps

module tb_goertzel_bank;

    reg clk;
    reg reset_n;

    reg sample_valid;
    reg window_first;
    reg window_last;

    reg signed [16:0] sample_in;

    wire [79:0] p1;
    wire [79:0] p2;
    wire [79:0] p3;
    wire [79:0] p4;

    wire powers_valid;

    integer i;

    goertzel_bank dut (
        .clk(clk),
        .reset_n(reset_n),

        .sample_valid(sample_valid),
        .window_first(window_first),
        .window_last(window_last),

        .sample_in(sample_in),

        .coeff_1(16'sd30274),
        .coeff_2(16'sd23170),
        .coeff_3(16'sd0),
        .coeff_4(-16'sd23170),

        .power_1(p1),
        .power_2(p2),
        .power_3(p3),
        .power_4(p4),

        .powers_valid(powers_valid)
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

    task send_sample;
        input signed [16:0] value;
        input first_s;
        input last_s;

        begin
            @(negedge clk);

            sample_in    = value;
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

        #500;
        reset_n = 1;

        for (i = 0; i < 256; i = i + 1)
            send_sample(
                tone25(i),
                (i == 0),
                (i == 255)
            );

        #10;

        if (
            p1 > p2 &&
            p1 > p3 &&
            p1 > p4
        )
            $display("TEST GOERTZEL BANK: PASS");
        else
            $display(
                "TEST GOERTZEL BANK: FAIL P1=%0d P2=%0d P3=%0d P4=%0d",
                p1, p2, p3, p4
            );

        $finish;
    end

endmodule