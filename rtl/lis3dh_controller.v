module lis3dh_controller (
    input  wire clk,
    input  wire reset_n,
    input  wire start_init,
    input  wire sample_tick,
    input  wire miso,

    output wire sclk,
    output wire mosi,
    output wire cs_n,

    output reg  sensor_ok,
    output reg  initialized,
    output reg  sample_valid,

    output reg signed [15:0] accel_x,
    output reg signed [15:0] accel_y,
    output reg signed [15:0] accel_z
);

    reg spi_start;
    reg [63:0] spi_tx;
    reg [6:0] transfer_bits;

    wire spi_busy;
    wire spi_done;
    wire [63:0] spi_rx;

    reg [3:0] state;

    localparam IDLE        = 4'd0;
    localparam WHO_SETUP   = 4'd1;
    localparam WHO_START   = 4'd2;
    localparam WHO_WAIT    = 4'd3;
    localparam CFG1_SETUP  = 4'd4;
    localparam CFG1_START  = 4'd5;
    localparam CFG1_WAIT   = 4'd6;
    localparam CFG4_SETUP  = 4'd7;
    localparam CFG4_START  = 4'd8;
    localparam CFG4_WAIT   = 4'd9;
    localparam READY       = 4'd10;
    localparam READ_SETUP  = 4'd11;
    localparam READ_START  = 4'd12;
    localparam READ_WAIT   = 4'd13;

    spi_master #(
        .CLK_DIV(5)
    ) spi_inst (
        .clk(clk),
        .reset_n(reset_n),
        .start(spi_start),
        .tx_data(spi_tx),
        .transfer_bits(transfer_bits),
        .miso(miso),

        .sclk(sclk),
        .mosi(mosi),
        .cs_n(cs_n),

        .busy(spi_busy),
        .done(spi_done),
        .rx_data(spi_rx)
    );

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state         <= IDLE;
            spi_start     <= 0;
            spi_tx        <= 0;
            transfer_bits <= 0;

            sensor_ok     <= 0;
            initialized   <= 0;
            sample_valid  <= 0;

            accel_x       <= 0;
            accel_y       <= 0;
            accel_z       <= 0;

        end else begin

            spi_start    <= 0;
            sample_valid <= 0;

            case (state)

                IDLE: begin
                    if (start_init)
                        state <= WHO_SETUP;
                end

                WHO_SETUP: begin
                    spi_tx        <= 64'h0000000000008F00;
                    transfer_bits <= 16;
                    state         <= WHO_START;
                end

                WHO_START: begin
                    spi_start <= 1;
                    state <= WHO_WAIT;
                end

                WHO_WAIT: begin
                    if (spi_done) begin
                        if (spi_rx[7:0] == 8'h33) begin
                            sensor_ok <= 1;
                            state <= CFG1_SETUP;
                        end else begin
                            sensor_ok <= 0;
                            state <= IDLE;
                        end
                    end
                end

                // CTRL_REG1 0x20 = 0x77
                CFG1_SETUP: begin
                    spi_tx        <= 64'h0000000000002077;
                    transfer_bits <= 16;
                    state         <= CFG1_START;
                end

                CFG1_START: begin
                    spi_start <= 1;
                    state <= CFG1_WAIT;
                end

                CFG1_WAIT: begin
                    if (spi_done)
                        state <= CFG4_SETUP;
                end

                // CTRL_REG4 0x23 = 0x98
                CFG4_SETUP: begin
                    spi_tx        <= 64'h0000000000002398;
                    transfer_bits <= 16;
                    state         <= CFG4_START;
                end

                CFG4_START: begin
                    spi_start <= 1;
                    state <= CFG4_WAIT;
                end

                CFG4_WAIT: begin
                    if (spi_done) begin
                        initialized <= 1;
                        state <= READY;
                    end
                end

                READY: begin
                    if (sample_tick)
                        state <= READ_SETUP;
                end

                // 0xE8:
                // READ + MULTI-BYTE + address 0x28
                READ_SETUP: begin
                    spi_tx        <= 64'h00E8000000000000;
                    transfer_bits <= 56;
                    state         <= READ_START;
                end

                READ_START: begin
                    spi_start <= 1;
                    state <= READ_WAIT;
                end

                READ_WAIT: begin
                    if (spi_done) begin

                        accel_x <= {
                            spi_rx[39:32],
                            spi_rx[47:40]
                        };

                        accel_y <= {
                            spi_rx[23:16],
                            spi_rx[31:24]
                        };

                        accel_z <= {
                            spi_rx[7:0],
                            spi_rx[15:8]
                        };

                        sample_valid <= 1;
                        state <= READY;
                    end
                end

            endcase
        end
    end

endmodule