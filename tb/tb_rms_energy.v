`timescale 1ns/1ps

module tb_rms_energy;

    reg clk;
    reg reset_n;

    reg sample_valid;
    reg window_first;
    reg window_last;

    reg signed [16:0] vib_x;
    reg signed [16:0] vib_y;
    reg signed [16:0] vib_z;

    wire [33:0] energy_value;
    wire energy_valid;

    integer i;

    rms_energy dut (
        .clk(clk),
        .reset_n(reset_n),

        .sample_valid(sample_valid),
        .window_first(window_first),
        .window_last(window_last),

        .vib_x(vib_x),
        .vib_y(vib_y),
        .vib_z(vib_z),

        .energy_value(energy_value),
        .energy_valid(energy_valid)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    task send_sample;
        input first_s;
        input last_s;

        begin
            @(negedge clk);

            vib_x = 100;
            vib_y = -200;
            vib_z = 300;

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

        send_sample(1, 0);

        for (i = 1; i < 255; i = i + 1)
            send_sample(0, 0);

        send_sample(0, 1);

        #10;

        // 100² + 200² + 300² = 140000
        if (energy_value == 140000)
            $display("TEST RMS ENERGY: PASS");
        else
            $display(
                "TEST RMS ENERGY: FAIL ENERGY=%0d",
                energy_value
            );

        $finish;
    end

endmodule