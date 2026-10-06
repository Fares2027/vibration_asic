module dc_filter #(
    parameter integer SHIFT = 6,
    parameter integer FRAC_BITS = 8
)(
    input  wire clk,
    input  wire reset_n,
    input  wire sample_valid,

    input  wire signed [15:0] accel_x,
    input  wire signed [15:0] accel_y,
    input  wire signed [15:0] accel_z,

    output reg signed [16:0] vib_x,
    output reg signed [16:0] vib_y,
    output reg signed [16:0] vib_z
);

    localparam integer ACC_WIDTH = 16 + FRAC_BITS + 2;

    reg signed [ACC_WIDTH-1:0] dc_x;
    reg signed [ACC_WIDTH-1:0] dc_y;
    reg signed [ACC_WIDTH-1:0] dc_z;

    wire signed [ACC_WIDTH-1:0] x_ext =
        {{(ACC_WIDTH-16){accel_x[15]}}, accel_x};

    wire signed [ACC_WIDTH-1:0] y_ext =
        {{(ACC_WIDTH-16){accel_y[15]}}, accel_y};

    wire signed [ACC_WIDTH-1:0] z_ext =
        {{(ACC_WIDTH-16){accel_z[15]}}, accel_z};

    wire signed [ACC_WIDTH-1:0] x_q = x_ext <<< FRAC_BITS;
    wire signed [ACC_WIDTH-1:0] y_q = y_ext <<< FRAC_BITS;
    wire signed [ACC_WIDTH-1:0] z_q = z_ext <<< FRAC_BITS;

    wire signed [ACC_WIDTH-1:0] err_x = x_q - dc_x;
    wire signed [ACC_WIDTH-1:0] err_y = y_q - dc_y;
    wire signed [ACC_WIDTH-1:0] err_z = z_q - dc_z;

    wire signed [15:0] dc_x_int = dc_x >>> FRAC_BITS;
    wire signed [15:0] dc_y_int = dc_y >>> FRAC_BITS;
    wire signed [15:0] dc_z_int = dc_z >>> FRAC_BITS;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            dc_x  <= 0;
            dc_y  <= 0;
            dc_z  <= 0;

            vib_x <= 0;
            vib_y <= 0;
            vib_z <= 0;

        end else if (sample_valid) begin

            vib_x <=
                $signed({accel_x[15], accel_x}) -
                $signed({dc_x_int[15], dc_x_int});

            vib_y <=
                $signed({accel_y[15], accel_y}) -
                $signed({dc_y_int[15], dc_y_int});

            vib_z <=
                $signed({accel_z[15], accel_z}) -
                $signed({dc_z_int[15], dc_z_int});

            dc_x <= dc_x + (err_x >>> SHIFT);
            dc_y <= dc_y + (err_y >>> SHIFT);
            dc_z <= dc_z + (err_z >>> SHIFT);

        end
    end

endmodule