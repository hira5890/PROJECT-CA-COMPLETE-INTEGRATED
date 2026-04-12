`timescale 1ns / 1ps
// =============================================================================
// top_assembly_code_testing_task_b
//
// Top module for Task B assembly-level testing on Basys-3.
// Runs the simple 3-instruction demo program:
//   LUI + BNE loop + JALR call/return -> displays 7 on 7-seg
//
// Uses standard TopLevelProcessor with instruction memory swapped out.
// No changes to DataMemory, AddressDecoder, or any other module.
// =============================================================================
module top_assembly_code_testing_task_b (
    input  wire        clk,
    input  wire        btnC,
    input  wire [5:0]  sw,
    output wire [5:0]  led,
    output wire [6:0]  seg,
    output wire [3:0]  an
);
    wire clk_10mhz;

    ClockDivider u_clkdiv (
        .clk_100mhz (clk),
        .clk_10mhz  (clk_10mhz)
    );

    TopLevelProcessor_taskb u_cpu (
        .clk         (clk_10mhz),
        .reset       (btnC),
        .switch_in   (sw),
        .led_out     (led),
        .led_write_en(),
        .seg         (seg),
        .an          (an)
    );

endmodule