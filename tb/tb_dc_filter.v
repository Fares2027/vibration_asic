`timescale 1ns/1ps

module tb_dc_filter;

    reg clk;
    reg reset_n;
    reg sample_valid;

    reg signed [15:0] accel_x;
    reg signed [15:0] accel_y;
    reg signed [15:0] accel_z;

    wire signed [16:0] vib_x;
    wire signed [16:0] vib_y;
    wire signed [16:0] vib_z;

    integer i;

    dc_filter dut (
        .clk(clk),
        .reset_n(reset_n),
        .sample_valid(sample_valid),

        .accel_x(accel_x),
        .accel_y(accel_y),
        .accel_z(accel_z),

        .vib_x(vib_x),
        .vib_y(vib_y),
        .vib_z(vib_z)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    task send_sample;
        input signed [15:0] x;
        input signed [15:0] y;
        input signed [15:0] z;

        begin
            @(negedge clk);

            accel_x = x;
            accel_y = y;
            accel_z = z;
            sample_valid = 1;

            @(negedge clk);
            sample_valid = 0;
        end
    endtask

    initial begin

        reset_n = 0;
        sample_valid = 0;

        accel_x = 0;
        accel_y = 0;
        accel_z = 0;

        #500;
        reset_n = 1;

        // Constant acceleration / gravity
        for (i = 0; i < 600; i = i + 1)
            send_sample(1000, -500, 2000);

        // DC should now be removed
        if (
            vib_x > -5 && vib_x < 5 &&
            vib_y > -5 && vib_y < 5 &&
            vib_z > -5 && vib_z < 5
        )
            $display("DC LEARNING: PASS");
        else
            $display(
                "DC LEARNING: FAIL X=%d Y=%d Z=%d",
                vib_x, vib_y, vib_z
            );

        // Introduce vibration/change
        send_sample(1500, -1000, 2600);

        if (
            vib_x > 400 &&
            vib_y < -400 &&
            vib_z > 500
        )
            $display("TEST DC FILTER: PASS");
        else
            $display(
                "TEST DC FILTER: FAIL X=%d Y=%d Z=%d",
                vib_x, vib_y, vib_z
            );

        $finish;
    end

endmodule