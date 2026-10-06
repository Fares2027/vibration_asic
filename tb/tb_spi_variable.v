`timescale 1ns/1ps

module tb_spi_variable;

    reg clk;
    reg reset_n;
    reg start;

    reg  [63:0] tx_data;
    reg  [6:0]  transfer_bits;

    wire miso;

    wire sclk;
    wire mosi;
    wire cs_n;
    wire busy;
    wire done;

    wire [63:0] rx_data;

    assign miso = ~mosi;

    spi_master dut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),

        .tx_data(tx_data),
        .transfer_bits(transfer_bits),

        .miso(miso),

        .sclk(sclk),
        .mosi(mosi),
        .cs_n(cs_n),
        .busy(busy),
        .done(done),

        .rx_data(rx_data)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    initial begin

        reset_n = 0;
        start = 0;

        #500;
        reset_n = 1;

        // 56-bit transaction
        tx_data = 64'h00E8000000000000;
        transfer_bits = 56;

        #200;

        start = 1;
        #100;
        start = 0;

        @(posedge done);
        #10;

        if (rx_data == 64'h0017FFFFFFFFFFFF)
            $display("TEST VARIABLE SPI 56-BIT: PASS");
        else
            $display("TEST VARIABLE SPI 56-BIT: FAIL RX=%h", rx_data);

        $finish;
    end

endmodule