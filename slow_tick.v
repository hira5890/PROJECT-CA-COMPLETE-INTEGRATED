`timescale 1ns / 1ps
module SlowTick(
    input  wire clk_10mhz,  // 10 MHz input
    input  wire reset,
    output reg  tick_1hz    // 1 Hz output
);
    reg [23:0] counter; // 24-bit is enough for 10M cycles

    initial begin
        counter = 0;
        tick_1hz = 0;
    end

    always @(posedge clk_10mhz or posedge reset) begin
        if (reset) begin
            counter <= 0;
            tick_1hz <= 0;
        end else if (counter == 24'd9_999_999) begin
            counter <= 0;
            tick_1hz <= 1;
        end else begin
            counter <= counter + 1;
            tick_1hz <= 0;
        end
    end
endmodule