`timescale 1ns/1ps

module tb_spi_master;

    reg clk;
    reg reset_n;
    reg start;
    reg [15:0] tx_data;

    wire miso;
    wire sclk;
    wire mosi;
    wire cs_n;
    wire busy;
    wire done;
    wire [15:0] rx_data;

    // Simulated slave returns inverted MOSI
    assign miso = ~mosi;

    spi_master #(
        .CLK_DIV(5)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .tx_data(tx_data),
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
        forever #50 clk = ~clk;   // 10 MHz
    end

    initial begin
        reset_n = 0;
        start   = 0;
        tx_data = 16'h8F00;

        #500;
        reset_n = 1;

        #200;
        start = 1;

        #100;
        start = 0;

        @(posedge done);
        #10;

        if (rx_data == 16'h70FF)
            $display("TEST SPI MASTER: PASS");
        else
            $display("TEST SPI MASTER: FAIL - RX=%h", rx_data);

        $finish;
    end

endmodule