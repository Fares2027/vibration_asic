`timescale 1ns/1ps

module tb_window_engine;

    reg clk;
    reg reset_n;
    reg sample_valid;

    wire window_first;
    wire window_last;
    wire window_done;
    wire [7:0] sample_index;

    integer i;
    integer first_count;
    integer last_count;
    integer done_count;

    window_engine dut (
        .clk(clk),
        .reset_n(reset_n),
        .sample_valid(sample_valid),

        .window_first(window_first),
        .window_last(window_last),
        .window_done(window_done),
        .sample_index(sample_index)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    task send_sample;
        begin
            @(negedge clk);
            sample_valid = 1;

            @(negedge clk);
            sample_valid = 0;
        end
    endtask

    always @(posedge clk) begin
        if (window_first)
            first_count = first_count + 1;

        if (window_last)
            last_count = last_count + 1;

        if (window_done)
            done_count = done_count + 1;
    end

    initial begin

        reset_n = 0;
        sample_valid = 0;

        first_count = 0;
        last_count = 0;
        done_count = 0;

        #500;
        reset_n = 1;

        // Send exactly two windows
        for (i = 0; i < 512; i = i + 1)
            send_sample();

        #200;

        if (
            first_count == 2 &&
            last_count  == 2 &&
            done_count  == 2 &&
            sample_index == 0
        )
            $display("TEST WINDOW ENGINE: PASS");
        else
            $display(
                "TEST WINDOW ENGINE: FAIL FIRST=%0d LAST=%0d DONE=%0d INDEX=%0d",
                first_count,
                last_count,
                done_count,
                sample_index
            );

        $finish;
    end

endmodule