module alert_persistence #(
    parameter integer POINT_THRESHOLD = 3,
    parameter integer PERSIST_WINDOWS = 3
)(
    input  wire       clk,
    input  wire       reset_n,

    input  wire       anomaly_valid,
    input  wire [3:0] anomaly_points,

    input  wire       clear_alert,

    output reg        alert,
    output reg [2:0]  persistence_count
);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            alert             <= 1'b0;
            persistence_count <= 3'd0;

        end else if (clear_alert) begin
            alert             <= 1'b0;
            persistence_count <= 3'd0;

        end else if (anomaly_valid) begin

            if (anomaly_points >= POINT_THRESHOLD) begin

                if (persistence_count < PERSIST_WINDOWS)
                    persistence_count <= persistence_count + 1'b1;

                if (persistence_count == PERSIST_WINDOWS - 1)
                    alert <= 1'b1;

            end else begin
                persistence_count <= 3'd0;
            end
        end
    end

endmodule