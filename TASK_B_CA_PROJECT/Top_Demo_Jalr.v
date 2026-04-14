`timescale 1ns / 1ps
// =============================================================================
// top_jalr_demo  (updated for visible PC stepping)
//
// KEY CHANGE: two separate clocks.
//
//   CPU clock  = ~2 Hz (from ClockDividerSlow)
//     Each instruction takes ~0.5 s, so the 7-seg value changes slowly
//     enough to read.  You will visibly see:
//       0000 -> 0004 -> 0008 -> 000C -> 0010 -> 0014 -> 0018
//       001C  (JALR call  - next value jumps to...)
//       002C -> 0030 -> 0034
//       0034  (JALR return - next value jumps back to...)
//       0020 -> 0024  (halts here)
//
//   7-seg clock = 100 MHz (raw board clock)
//     The TDM multiplexer inside sevenseg_basys3_4digit needs a fast clock
//     to cycle through the 4 digits quickly enough to avoid flicker.
//     If it ran at 2 Hz the digits would visibly flash on/off one at a time.
//     Keeping it on 100 MHz means ~9.8 kHz per digit - solid display.
//
// The processor's val_in (PC[15:0]) is a register output, so it is stable
// between CPU clock edges and safe to sample on the faster 7-seg clock.
// =============================================================================
module top_jalr_demo (
    input  wire        clk,       // 100 MHz board clock
    input  wire        btnC,      // centre button = synchronous reset
    input  wire [5:0]  sw,
    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire [3:0]  an
);
    // -------------------------------------------------------------------------
    // Two clocks
    // -------------------------------------------------------------------------
    wire clk_slow;   // ~2 Hz  -> drives CPU

    ClockDividerSlow u_slow (
        .clk_100mhz (clk),
        .clk_slow   (clk_slow)
    );
    // 100 MHz (clk) drives the 7-seg directly - passed through the processor
    // port below via sys_clk_fast.

    // -------------------------------------------------------------------------
    // Processor  (CPU on slow clock, 7-seg on fast clock)
    // -------------------------------------------------------------------------
    TopLevelProcessor_jalr u_cpu (
        .clk          (clk_slow),   // CPU steps at 2 Hz
        .clk_fast     (clk),        // 7-seg TDM runs at 100 MHz
        .reset        (btnC),
        .switch_in    (sw),
        .led_out      (led),
        .led_write_en (),
        .seg          (seg),
        .an           (an)
    );

endmodule
