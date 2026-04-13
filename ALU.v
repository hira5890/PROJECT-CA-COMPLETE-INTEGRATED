// =============================================================================
// Module      : ALUControl
// Description : RISC-V ALU control unit.  Combines the 2-bit ALUOp signal
//               from MainControl with the funct3 and funct7 fields (and the
//               opcode for R-type SUB disambiguation) to produce a 4-bit
//               ALU operation code.
//
//               ALUOp encoding:
//               ????????????????????????????????????????????????????????????
//               ? ALUOp   ? Instruction class                               ?
//               ????????????????????????????????????????????????????????????
//               ?  2'b00  ? Load / Store  - always ADD (address calc)       ?
//               ?  2'b01  ? Branch (BEQ)  - always SUB (zero-flag compare)  ?
//               ?  2'b10  ? R-type / I-type ALU - decoded via funct3/funct7 ?
//               ????????????????????????????????????????????????????????????
//
//               ALUControl 4-bit encoding:
//               ???????????????????????????????????????????????????
//               ? 4'b0000  ? AND                                   ?
//               ? 4'b0001  ? OR                                    ?
//               ? 4'b0010  ? ADD                                   ?
//               ? 4'b0011  ? XOR                                   ?
//               ? 4'b0100  ? SLL (shift left logical)              ?
//               ? 4'b0101  ? SRL (shift right logical)             ?
//               ? 4'b0110  ? SUB                                   ?
//               ? 4'b0111  ? SLT (set less than)                   ?
//               ???????????????????????????????????????????????????
// =============================================================================

`timescale 1ns / 1ps

module ALUControl (
    input  [6:0] opcode,        // Full opcode - needed to distinguish SUB vs ADD
    input  [1:0] ALUOp,         // 2-bit selector from MainControl
    input  [2:0] funct3,        // funct3 field from the instruction word
    input  [6:0] funct7,        // funct7 field from the instruction word
    output reg [3:0] ALUControl // 4-bit ALU operation code sent to the ALU
);

    // -------------------------------------------------------------------------
    // Combinational decode block
    // -------------------------------------------------------------------------
    always @(*) begin

        // Default: ADD (safe fallback for any unrecognised combination)
        ALUControl = 4'b0010;

        case (ALUOp)

            // -----------------------------------------------------------------
            // ALUOp = 00 - Load / Store instructions
            //   The ALU only needs to compute  base + offset,  so always ADD.
            // -----------------------------------------------------------------
            2'b00: begin
                ALUControl = 4'b0010;   // ADD - effective address calculation
            end

            // -----------------------------------------------------------------
            // ALUOp = 01 - Branch instructions (BEQ)
            //   The ALU subtracts rs1 - rs2 and the zero flag decides the branch.
            // -----------------------------------------------------------------
            2'b01: begin
                ALUControl = 4'b0110;   // SUB - drives zero flag for BEQ
            end

            // -----------------------------------------------------------------
            // ALUOp = 10 - R-type and I-type ALU instructions
            //   funct3 selects the operation; for funct3=000 the funct7 bit
            //   distinguishes ADD/ADDI from SUB (R-type only).
            // -----------------------------------------------------------------
            2'b10: begin
                case (funct3)

                    // funct3 = 000 : ADD, ADDI, or SUB
                    3'b000: begin
                        // SUB only exists in R-type (opcode 0110011) and is
                        // identified by funct7[5] = 1  (full funct7 = 0100000).
                        if (opcode == 7'b0110011 && funct7 == 7'b0100000)
                            ALUControl = 4'b0110;   // SUB
                        else
                            ALUControl = 4'b0010;   // ADD / ADDI
                    end

                    // funct3 = 001 : SLL - Shift Left Logical
                    3'b001: ALUControl = 4'b0100;

                    // funct3 = 010 : SLT (I-type SLTI) or default ADD
                    3'b010: begin
                        if (opcode == 7'b0010011)
                            ALUControl = 4'b0111;   // SLT (A < B ? 1 : 0)
                        else
                            ALUControl = 4'b0010;   // default ADD
                    end

                    // funct3 = 011 : SLTU - Set Less Than Unsigned
                    //   Not fully implemented; mapped to ADD as placeholder.
                    3'b011: ALUControl = 4'b0010;

                    // funct3 = 100 : XOR
                    3'b100: ALUControl = 4'b0011;

                    // funct3 = 101 : SRL - Shift Right Logical
                    3'b101: ALUControl = 4'b0101;

                    // funct3 = 110 : OR
                    3'b110: ALUControl = 4'b0001;

                    // funct3 = 111 : AND
                    3'b111: ALUControl = 4'b0000;

                    // Catch-all: default to ADD
                    default: ALUControl = 4'b0010;

                endcase
            end

            // -----------------------------------------------------------------
            // Default: unrecognised ALUOp - ADD (safe fallback)
            // -----------------------------------------------------------------
            default: ALUControl = 4'b0010;

        endcase
    end

endmodule
