`timescale 1ns / 1ps
// =============================================================================
// top_blt_demo
// Basys-3 top wrapper for BLT demonstration.
// CPU runs at 2Hz so each PC step is visible on the 7-seg display.
// =============================================================================
module top_blt_demo (
    input  wire        clk,       // 100MHz board clock
    input  wire        btnC,      // reset
    input  wire [5:0]  sw,
    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire [3:0]  an
);
    wire clk_slow;

    ClockDividerSlow u_slow (
        .clk_100mhz (clk),
        .clk_slow   (clk_slow)    // ~2Hz for visible PC stepping
    );

    TopLevelProcessor_blt u_cpu (
        .clk          (clk_slow),
        .clk_fast     (clk),
        .reset        (btnC),
        .switch_in    (sw),
        .led_out      (led),
        .led_write_en (),
        .seg          (seg),
        .an           (an)
    );
endmodule
