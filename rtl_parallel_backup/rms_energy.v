module rms_energy (
    input  wire clk,
    input  wire reset_n,

    input  wire sample_valid,
    input  wire window_first,
    input  wire window_last,

    input  wire signed [16:0] vib_x,
    input  wire signed [16:0] vib_y,
    input  wire signed [16:0] vib_z,

    output reg  [33:0] energy_value,
    output reg         energy_valid
);

    wire [16:0] abs_x = vib_x[16] ? (~vib_x + 1'b1) : vib_x;
    wire [16:0] abs_y = vib_y[16] ? (~vib_y + 1'b1) : vib_y;
    wire [16:0] abs_z = vib_z[16] ? (~vib_z + 1'b1) : vib_z;

    wire [33:0] square_x = abs_x * abs_x;
    wire [33:0] square_y = abs_y * abs_y;
    wire [33:0] square_z = abs_z * abs_z;

    wire [35:0] sample_energy =
        square_x + square_y + square_z;

    reg [43:0] energy_accumulator;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            energy_accumulator <= 0;
            energy_value       <= 0;
            energy_valid       <= 0;
        end else begin

            energy_valid <= 0;

            if (sample_valid) begin

                if (window_first) begin
                    energy_accumulator <= sample_energy;

                end else if (window_last) begin

                    // Divide by 256 using shift
                    energy_value <=
                        (energy_accumulator + sample_energy) >> 8;

                    energy_accumulator <= 0;
                    energy_valid <= 1;

                end else begin
                    energy_accumulator <=
                        energy_accumulator + sample_energy;
                end
            end
        end
    end

endmodule