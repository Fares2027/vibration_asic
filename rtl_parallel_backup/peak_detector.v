module peak_detector (
    input  wire clk,
    input  wire reset_n,

    input  wire sample_valid,
    input  wire window_first,
    input  wire window_last,

    input  wire signed [16:0] vib_x,
    input  wire signed [16:0] vib_y,
    input  wire signed [16:0] vib_z,

    output reg  [16:0] peak_value,
    output reg         peak_valid
);

    wire [16:0] abs_x =
        vib_x[16] ? (~vib_x + 1'b1) : vib_x;

    wire [16:0] abs_y =
        vib_y[16] ? (~vib_y + 1'b1) : vib_y;

    wire [16:0] abs_z =
        vib_z[16] ? (~vib_z + 1'b1) : vib_z;

    wire [16:0] sample_peak =
        (abs_x >= abs_y && abs_x >= abs_z) ? abs_x :
        (abs_y >= abs_z) ? abs_y :
                           abs_z;

    reg [16:0] running_peak;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            running_peak <= 17'd0;
            peak_value   <= 17'd0;
            peak_valid   <= 1'b0;
        end
        else begin
            peak_valid <= 1'b0;

            if (sample_valid) begin

                if (window_first) begin
                    running_peak <= sample_peak;

                    if (window_last) begin
                        peak_value <= sample_peak;
                        peak_valid <= 1'b1;
                    end
                end
                else if (window_last) begin

                    if (sample_peak > running_peak)
                        peak_value <= sample_peak;
                    else
                        peak_value <= running_peak;

                    peak_valid   <= 1'b1;
                    running_peak <= 17'd0;

                end
                else if (sample_peak > running_peak) begin
                    running_peak <= sample_peak;
                end
            end
        end
    end

endmodule