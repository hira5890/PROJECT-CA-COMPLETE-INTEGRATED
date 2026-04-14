`timescale 1ns / 1ps
// =============================================================================
// RISCVALU - consistent with ALUControl encoding above
// =============================================================================
module RISCVALU (
    input  [3:0]  ALUctl,
    input  [31:0] A, B,
    output reg [31:0] ALUout,
    output wire Zero,
    output wire Negative    // NEW: needed for BLT/BGE
);
    assign Zero     = (ALUout == 32'b0);
    assign Negative = ALUout[31]; // sign bit of result, used for BLT/BGE

    always @(*) begin
        case (ALUctl)
            4'b0000: ALUout = A & B;                         // AND
            4'b0001: ALUout = A | B;                         // OR
            4'b0010: ALUout = A + B;                         // ADD
            4'b0110: ALUout = A - B;                         // SUB
            4'b0111: ALUout = ($signed(A) < $signed(B))      // SLT signed
                               ? 32'd1 : 32'd0;
            4'b1000: ALUout = A << B[4:0];                   // SLL
            4'b1001: ALUout = A >> B[4:0];                   // SRL
            4'b1010: ALUout = A ^ B;                         // XOR
            4'b1011: ALUout = (A < B) ? 32'd1 : 32'd0;      // SLTU unsigned
            4'b1100: ALUout = B;                             // PASS_B for LUI
            default: ALUout = 32'b0;
        endcase
    end
endmodule
