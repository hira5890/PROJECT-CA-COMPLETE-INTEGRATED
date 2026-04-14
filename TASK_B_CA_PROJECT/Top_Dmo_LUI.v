`timescale 1ns / 1ps
// =============================================================================
// top_lui_demo
// Basys-3 top for the LUI demonstration.
// CPU at 2 Hz so PC steps are visible on the 7-seg.
// 7-seg TDM stays on 100 MHz.
// =============================================================================
module top_lui_demo (
    input  wire        clk,
    input  wire        btnC,
    input  wire [5:0]  sw,
    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire [3:0]  an
);
    wire clk_slow;

    ClockDividerSlow u_slow (
        .clk_100mhz (clk),
        .clk_slow   (clk_slow)
    );

    TopLevelProcessor_lui u_cpu (
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
