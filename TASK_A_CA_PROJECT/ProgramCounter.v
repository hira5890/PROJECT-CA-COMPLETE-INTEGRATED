// ============================================================
//  ProgramCounter.v
//  PC register with synchronous reset.
//  Initial value set to 0 so simulation shows clean zeros
//  instead of X before the first clock edge.
// ============================================================
`timescale 1ns/1ps

module ProgramCounter (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] PC_Next,
    output reg  [31:0] PC
);
    // initial block gives PC a known value at time 0
    // so combinational outputs (PC+4, branch target) are
    initial PC = 32'h00000000; //initial value

    always @(posedge clk) begin
        if (reset)
            PC <= 32'h00000000; //if reset then 0
        else
            PC <= PC_Next; //move on to pc next which can be either Pc+4 or branch target adddress
    end

endmodule
