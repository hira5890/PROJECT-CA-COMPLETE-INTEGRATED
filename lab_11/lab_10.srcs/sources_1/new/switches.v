`timescale 1ns / 1ps

module switches(
    input clk,
    input rst,
    input [31:0] writeData,
    input writeEnable,
    input readEnable,
    input [29:0] memAddress,
    input [15:0] sw, 
    output reg [31:0] readData,
    output reg [15:0] leds
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        readData <= 32'b0;
        leds <= 16'b0;
    end
    else begin
        if (readEnable)
            readData <= {16'b0, sw};
        else
            readData <= 32'b0;
    end
end

endmodule