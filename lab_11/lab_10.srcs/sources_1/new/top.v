`timescale 1ns / 1ps
module top (
    input  wire        clk,
    input  wire        btnC,
    input  wire [5:0]  sw,
    output wire [5:0]  led,
    output wire [6:0]  seg,
    output wire [3:0]  an
);
    wire clk_10mhz;
    wire [5:0] led_val;
    wire       led_we;

    ClockDivider u_clkdiv (
        .clk_100mhz (clk),
        .clk_10mhz  (clk_10mhz)
    );

    TopLevelProcessor u_cpu (
        .clk         (clk_10mhz),
        .reset       (btnC),
        .switch_in   (sw),
        .led_out     (led_val),
        .led_write_en(led_we),
        .seg         (seg),
        .an          (an)
    );

    assign led = led_val;

endmodule