module sample_tick #(
    parameter integer CLK_HZ    = 10_000_000,
    parameter integer SAMPLE_HZ = 400
)(
    input  wire clk,
    input  wire reset_n,
    input  wire enable,
    output reg  sample_tick
);

    localparam integer DIVISOR = CLK_HZ / SAMPLE_HZ;
    localparam integer COUNTER_WIDTH = $clog2(DIVISOR);

    reg [COUNTER_WIDTH-1:0] counter;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter     <= 0;
            sample_tick <= 1'b0;
        end
        else if (!enable) begin
            counter     <= 0;
            sample_tick <= 1'b0;
        end
        else begin
            sample_tick <= 1'b0;

            if (counter == DIVISOR - 1) begin
                counter     <= 0;
                sample_tick <= 1'b1;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end
    end

endmodule