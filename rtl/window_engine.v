module window_engine #(
    parameter integer WINDOW_SIZE = 256
)(
    input  wire       clk,
    input  wire       reset_n,
    input  wire       sample_valid,

    output wire       window_first,
    output wire       window_last,
    output wire       window_done,
    output reg [7:0]  sample_index
);

    assign window_first = sample_valid && (sample_index == 0);
    assign window_last  = sample_valid && (sample_index == WINDOW_SIZE - 1);
    assign window_done  = window_last;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sample_index <= 8'd0;
        end
        else if (sample_valid) begin
            if (sample_index == WINDOW_SIZE - 1)
                sample_index <= 8'd0;
            else
                sample_index <= sample_index + 1'b1;
        end
    end

endmodule