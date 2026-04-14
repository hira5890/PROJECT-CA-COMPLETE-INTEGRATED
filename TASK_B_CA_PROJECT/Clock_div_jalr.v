`timescale 1ns / 1ps
// =============================================================================
// ClockDividerSlow
//
// Divides 100 MHz down to ~2 Hz so PC increments are visible on the 7-seg.
// Each instruction executes for ~0.5 seconds - plenty of time to read the
// display before it jumps to the next value.
//
// Toggle every 25_000_000 cycles -> 100MHz / (2 * 25M) = 2 Hz output.
// Change TOGGLE_COUNT to adjust speed:
//   25_000_000 = 2 Hz  (0.5s per instruction) -- default
//   12_500_000 = 4 Hz  (0.25s per instruction) -- faster
//   50_000_000 = 1 Hz  (1s per instruction)    -- slower
// =============================================================================
module ClockDividerSlow (
    input  wire clk_100mhz,
    output reg  clk_slow
);
    localparam TOGGLE_COUNT = 25_000_000;  // -> 2 Hz

    reg [24:0] count;

    initial begin
        count    = 0;
        clk_slow = 0;
    end

    always @(posedge clk_100mhz) begin
        if (count == TOGGLE_COUNT - 1) begin
            count    <= 0;
            clk_slow <= ~clk_slow;
        end else begin
            count <= count + 1;
        end
    end
endmodule
