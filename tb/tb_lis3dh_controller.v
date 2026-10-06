`timescale 1ns/1ps

module tb_lis3dh_controller;

    reg clk;
    reg reset_n;
    reg start_check;
    reg miso;

    wire sclk;
    wire mosi;
    wire cs_n;
    wire sensor_ok;
    wire done;

    reg [15:0] slave_response;
    integer slave_index;

    lis3dh_controller dut (
        .clk(clk),
        .reset_n(reset_n),
        .start_check(start_check),
        .miso(miso),

        .sclk(sclk),
        .mosi(mosi),
        .cs_n(cs_n),

        .sensor_ok(sensor_ok),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;   // 10 MHz
    end

    // Simulated LIS3DH response:
    // First byte ignored
    // Second byte = WHO_AM_I = 0x33
    initial begin
        slave_response = 16'h0033;
        slave_index = 15;
        miso = 0;
    end

    always @(negedge cs_n) begin
        slave_index = 15;
        miso = slave_response[15];
    end

    always @(negedge sclk) begin
        if (!cs_n && slave_index > 0) begin
            slave_index = slave_index - 1;
            miso = slave_response[slave_index];
        end
    end

    initial begin
        reset_n = 0;
        start_check = 0;

        #500;
        reset_n = 1;

        #200;
        start_check = 1;

        #100;
        start_check = 0;

        @(posedge done);
        #10;

        if (sensor_ok)
            $display("TEST LIS3DH WHO_AM_I: PASS");
        else
            $display("TEST LIS3DH WHO_AM_I: FAIL");

        $finish;
    end

endmodule