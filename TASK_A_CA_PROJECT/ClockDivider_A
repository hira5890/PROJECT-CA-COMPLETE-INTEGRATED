`timescale 1ns / 1ps
// =============================================================================
// Module      : ClockDivider_A
// Description : Divides 100MHz input clock down to ~8Hz for CPU clock.
//               At 8Hz, each instruction takes ~0.125s.
//               The countdown loop is ~4 instructions per step,
//               so each displayed decrement takes ~0.5s - visible but snappy.
//
//               To tune speed:
//               4  Hz -> count = 12_499_999  (~1s per step)
//               8  Hz -> count =  6_249_999  (~0.5s per step) DEFAULT
//               16 Hz -> count =  3_124_999  (~0.25s per step)
// =============================================================================
module ClockDivider_A (
    input  wire clk_100mhz,
    output reg  clk_10mhz      // name kept for port compatibility, actual ~8Hz
);
    reg [23:0] count;
    initial begin
        count     = 0;
        clk_10mhz = 0;
    end
    always @(posedge clk_100mhz) begin
        if (count == 24'd6_249_999) begin   // 100MHz / (2 * 6,250,000) = 8Hz
            count     <= 24'd0;
            clk_10mhz <= ~clk_10mhz;
        end else begin
            count <= count + 24'd1;
        end
    end
endmodule
