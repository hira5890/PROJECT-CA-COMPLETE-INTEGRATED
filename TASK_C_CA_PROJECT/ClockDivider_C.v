`timescale 1ns / 1ps
module ClockDivider (
    input  wire clk_100mhz,
    output reg  clk_10mhz
);
    reg [2:0] count;
    initial begin
        count     = 0;
        clk_10mhz = 0;
    end
    always @(posedge clk_100mhz) begin
        if (count == 3'd4) begin      // toggle every 5 cycles = 10MHz
            count     <= 3'd0;
            clk_10mhz <= ~clk_10mhz;
        end else begin
            count <= count + 3'd1;
        end
    end
endmodule
