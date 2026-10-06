module spi_master #(
    parameter integer CLK_DIV = 5
)(
    input  wire        clk,
    input  wire        reset_n,
    input  wire        start,

    input  wire [63:0] tx_data,
    input  wire [6:0]  transfer_bits,

    input  wire        miso,

    output reg         sclk,
    output reg         mosi,
    output reg         cs_n,
    output reg         busy,
    output reg         done,

    output reg [63:0]  rx_data
);

    reg [7:0] div_counter;
    reg [5:0] bit_index;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sclk        <= 1'b0;
            mosi        <= 1'b0;
            cs_n        <= 1'b1;
            busy        <= 1'b0;
            done        <= 1'b0;
            rx_data     <= 64'd0;
            div_counter <= 8'd0;
            bit_index   <= 6'd0;
        end else begin

            done <= 1'b0;

            if (!busy) begin
                sclk <= 1'b0;

                if (start && transfer_bits >= 2 && transfer_bits <= 64) begin
                    busy        <= 1'b1;
                    cs_n        <= 1'b0;
                    div_counter <= 0;
                    rx_data     <= 0;

                    bit_index <= transfer_bits - 1'b1;
                    mosi      <= tx_data[transfer_bits - 1'b1];
                end

            end else begin

                if (div_counter == CLK_DIV - 1) begin
                    div_counter <= 0;

                    if (!sclk) begin
                        sclk <= 1'b1;
                        rx_data[bit_index] <= miso;

                    end else begin
                        sclk <= 1'b0;

                        if (bit_index == 0) begin
                            busy <= 1'b0;
                            cs_n <= 1'b1;
                            done <= 1'b1;

                        end else begin
                            bit_index <= bit_index - 1'b1;
                            mosi <= tx_data[bit_index - 1'b1];
                        end
                    end

                end else begin
                    div_counter <= div_counter + 1'b1;
                end
            end
        end
    end

endmodule