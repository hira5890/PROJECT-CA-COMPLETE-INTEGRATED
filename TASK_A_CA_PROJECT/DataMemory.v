`timescale 1ns / 1ps
// =============================================================================
// Module      : DataMemory
// Description : 512-word (2KB) data memory for single-cycle RISC-V processor.
//               Covers both Task A stack (0x1F7-0x1FF) and
//               Task B fib stack (0x20-0x80) with no collision.
//               - Synchronous write on rising clock edge when MemWrite = 1
//               - Asynchronous (combinational) read when MemRead = 1
//               - Word-addressed via address[10:2] (byte address in, word index)
// =============================================================================
module DataMemory (
    input  wire        clk,
    input  wire        MemWrite,
    input  wire        MemRead,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    reg [31:0] memory [0:511];  // 512 x 32-bit words = 2KB
    integer i;
    initial begin
        for (i = 0; i < 512; i = i + 1)
            memory[i] = 32'b0;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (MemWrite)
            memory[address[10:2]] <= write_data;
    end

    // Asynchronous read
    always @(*) begin
        if (MemRead)
            read_data = memory[address[10:2]];
        else
            read_data = 32'b0;
    end
endmodule
