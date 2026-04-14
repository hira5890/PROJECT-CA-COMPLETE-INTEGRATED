`timescale 1ns / 1ps
// =============================================================================
// MainControl - includes BLT/BGE (covers BGT idiom), JAL, JALR, LUI
// Jump output kept for documentation but top-level uses is_jal/is_jalr wires
// =============================================================================
module MainControl (
    input  [6:0] opcode,
    output reg        RegWrite,
    output reg [1:0]  ALUOp,
    output reg        MemRead,
    output reg        MemWrite,
    output reg        ALUSrc,
    output reg        MemtoReg,
    output reg        Branch,
    output reg        Jump
);
    always @(*) begin
        RegWrite = 1'b0;
        ALUOp    = 2'b00;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        ALUSrc   = 1'b0;
        MemtoReg = 1'b0;
        Branch   = 1'b0;
        Jump     = 1'b0;

        case (opcode)
            7'b0110011: begin // R-type (ADD, SUB, AND, OR, XOR, SLL, SRL, SLT)
                RegWrite = 1'b1;
                ALUOp    = 2'b10;
            end

            7'b0010011: begin // I-type ALU (ADDI, ANDI, ORI, XORI, SLLI, SRLI, SLTI, SLTIU)
                RegWrite = 1'b1;
                ALUOp    = 2'b10;
                ALUSrc   = 1'b1;
            end

            7'b0000011: begin // Load (LW, LB, LH etc.)
                RegWrite = 1'b1;
                ALUOp    = 2'b00;
                MemRead  = 1'b1;
                ALUSrc   = 1'b1;
                MemtoReg = 1'b1;
            end

            7'b0100011: begin // Store (SW, SB, SH)
                ALUOp    = 2'b00;
                MemWrite = 1'b1;
                ALUSrc   = 1'b1;
            end

            7'b1100011: begin // Branch (BEQ, BNE, BLT, BGE, BLTU, BGEU)
                ALUOp    = 2'b01; // SUB - top-level uses Zero and Negative
                Branch   = 1'b1;
                // ALUSrc stays 0: compare rs1 vs rs2
            end

            7'b1101111: begin // JAL
                RegWrite = 1'b1;
                ALUOp    = 2'b00; // ALU computes PC+imm for target (via branchAdder)
                ALUSrc   = 1'b1;
                Jump     = 1'b1;
            end

            7'b1100111: begin // JALR
                RegWrite = 1'b1;
                ALUOp    = 2'b00; // ALU computes rs1+imm for target
                ALUSrc   = 1'b1;
                Jump     = 1'b1;
            end

            7'b0110111: begin // LUI
                RegWrite = 1'b1;
                ALUOp    = 2'b00; // ALUControl will see LUI opcode and send PASS_B
                ALUSrc   = 1'b1;  // B input = upper immediate from ImmGen
            end

            default: begin end
        endcase
    end
endmodule
