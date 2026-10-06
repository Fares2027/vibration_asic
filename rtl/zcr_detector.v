module zcr_detector (
    input  wire clk,
    input  wire reset_n,

    input  wire sample_valid,
    input  wire window_first,
    input  wire window_last,

    input  wire signed [16:0] vib_x,
    input  wire signed [16:0] vib_y,
    input  wire signed [16:0] vib_z,

    output reg [9:0] zcr_value,
    output reg       zcr_valid
);

    reg prev_sign_x;
    reg prev_sign_y;
    reg prev_sign_z;

    reg [9:0] zcr_count;

    wire cross_x = (vib_x[16] != prev_sign_x);
    wire cross_y = (vib_y[16] != prev_sign_y);
    wire cross_z = (vib_z[16] != prev_sign_z);

    wire [1:0] crossings_now =
        cross_x + cross_y + cross_z;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            prev_sign_x <= 0;
            prev_sign_y <= 0;
            prev_sign_z <= 0;

            zcr_count <= 0;
            zcr_value <= 0;
            zcr_valid <= 0;

        end else begin

            zcr_valid <= 0;

            if (sample_valid) begin

                if (window_first) begin
                    zcr_count <= 0;

                end else if (window_last) begin
                    zcr_value <= zcr_count + crossings_now;
                    zcr_valid <= 1;
                    zcr_count <= 0;

                end else begin
                    zcr_count <= zcr_count + crossings_now;
                end

                prev_sign_x <= vib_x[16];
                prev_sign_y <= vib_y[16];
                prev_sign_z <= vib_z[16];

            end
        end
    end

endmodule