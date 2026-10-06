`timescale 1ns/1ps

module tb_lis3dh_xyz;

    reg clk;
    reg reset_n;
    reg start_init;
    reg sample_tick;
    reg miso;

    wire sclk;
    wire mosi;
    wire cs_n;

    wire sensor_ok;
    wire initialized;
    wire sample_valid;

    wire signed [15:0] accel_x;
    wire signed [15:0] accel_y;
    wire signed [15:0] accel_z;

    reg [63:0] response;
    integer response_index;
    integer transaction;

    lis3dh_controller dut (
        .clk(clk),
        .reset_n(reset_n),
        .start_init(start_init),
        .sample_tick(sample_tick),
        .miso(miso),

        .sclk(sclk),
        .mosi(mosi),
        .cs_n(cs_n),

        .sensor_ok(sensor_ok),
        .initialized(initialized),
        .sample_valid(sample_valid),

        .accel_x(accel_x),
        .accel_y(accel_y),
        .accel_z(accel_z)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    initial begin
        transaction = 0;
        miso = 0;
    end

    always @(negedge cs_n) begin

        transaction = transaction + 1;

        case (transaction)

            // WHO_AM_I = 0x33
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

            // XYZ burst:
            // X = 0x1230
            // Y = 0xFED0
            // Z = 0x4560
            4: begin
                response = 64'h00003012D0FE6045;
                response_index = 55;
            end

        endcase

        miso = response[response_index];
    end

    always @(negedge sclk) begin
        if (!cs_n && response_index > 0) begin
            response_index = response_index - 1;
            miso = response[response_index];
        end
    end

    initial begin

        reset_n    = 0;
        start_init = 0;
        sample_tick = 0;

        #500;
        reset_n = 1;

        #200;

        start_init = 1;
        #100;
        start_init = 0;

        wait(initialized);

        #500;

        sample_tick = 1;
        #100;
        sample_tick = 0;

        @(posedge sample_valid);
        #10;

        if (
            accel_x == 16'h1230 &&
            accel_y == 16'hFED0 &&
            accel_z == 16'h4560
        )
            $display("TEST LIS3DH XYZ: PASS");
        else
            $display(
                "TEST LIS3DH XYZ: FAIL X=%h Y=%h Z=%h",
                accel_x,
                accel_y,
                accel_z
            );

        $finish;
    end

endmodule