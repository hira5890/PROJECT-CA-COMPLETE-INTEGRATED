`timescale 1ns / 1ps
// =============================================================================
// Module      : Top_for_task_A
// Description : Top-level wrapper for Task A countdown processor on Basys3.
//               - ClockDivider_A divides 100MHz to ~8Hz for CPU
//               - btnC is reset: 3-stage synchronizer + pulse stretcher
//                 ensures clean reset across the slow clock domain
//               - Press btnC to reset and restart the countdown
// =============================================================================
module Top_for_task_A (
    input  wire        clk,
    input  wire        btnC,
    input  wire [5:0]  sw,
    output wire [5:0]  led,
    output wire [6:0]  seg,
    output wire [3:0]  an
);
    wire clk_slow;
    wire [5:0] led_val;
    wire       led_we;

    // -------------------------------------------------------------------------
    // Reset synchronizer + pulse stretcher
    // Synchronizes btnC into the 100MHz domain then stretches the pulse so
    // the slow CPU clock domain sees a clean reset assertion.
    // -------------------------------------------------------------------------
    reg [2:0] rst_sync;
    reg [3:0] rst_stretch;

    always @(posedge clk) begin
        rst_sync <= {rst_sync[1:0], btnC};  // 3-stage synchronizer
    end

    wire btn_synced = rst_sync[2];

    always @(posedge clk) begin
        if (btn_synced)
            rst_stretch <= 4'hF;            // hold reset while button pressed
        else if (rst_stretch != 0)
            rst_stretch <= rst_stretch - 1; // drain a few cycles after release
    end

    wire reset = (rst_stretch != 0);

    // -------------------------------------------------------------------------
    // Clock divider and CPU
    // -------------------------------------------------------------------------
    ClockDivider_A u_clkdiv (
        .clk_100mhz (clk),
        .clk_10mhz  (clk_slow)
    );

    TopLevelProcessor_TASK_A u_cpu (
        .clk         (clk_slow),
        .reset       (reset),
        .switch_in   (sw),
        .led_out     (led_val),
        .led_write_en(led_we),
        .seg         (seg),
        .an          (an)
    );

    assign led = led_val;

endmodule