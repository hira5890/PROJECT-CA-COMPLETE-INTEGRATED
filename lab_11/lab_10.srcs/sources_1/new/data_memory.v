`timescale 1ns / 1ps
module DataMemory(
    input clk,
    input MemWrite,
    input MemRead,
    input [7:0] address,
    input [5:0] write_data,
    output reg [5:0] read_data
);
reg [5:0] memory [0:511];
integer i;
initial begin
    for (i = 0; i < 512; i = i + 1)
        memory[i] = 6'b0;
end
always @(posedge clk) begin
    if (MemWrite)
        memory[address] <= write_data;
end
always @(*) begin
    if (MemRead)
        read_data = memory[address];
    else
        read_data = 6'b0;
end
endmodule