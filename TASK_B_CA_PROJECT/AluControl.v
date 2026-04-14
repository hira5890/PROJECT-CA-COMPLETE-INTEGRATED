`timescale 1ns / 1ps
// =============================================================================
// ALUControl - consistent encoding
//
// 4'b0000 = AND
// 4'b0001 = OR
// 4'b0010 = ADD
// 4'b0110 = SUB
// 4'b0111 = SLT (signed)
// 4'b1000 = SLL
// 4'b1001 = SRL
// 4'b1010 = XOR
// 4'b1011 = SLTU (unsigned less than)
// 4'b1100 = PASS_B (for LUI - passes immediate straight through)
// =============================================================================
module ALUControl (
    input  [6:0] opcode,
    input  [1:0] ALUOp,
    input  [2:0] funct3,
    input  [6:0] funct7,
    output reg [3:0] ALUControl
);
    always @(*) begin
        ALUControl = 4'b0010; // default ADD

        case (ALUOp)

            2'b00: begin
                // Load, Store, JAL, JALR all just need ADD for address calc.
                // LUI is special: we want to pass the immediate through unchanged.
                // MainControl sends ALUOp=00 for LUI too, so we disambiguate
                // via opcode here.
                if (opcode == 7'b0110111)
                    ALUControl = 4'b1100; // PASS_B for LUI
                else
                    ALUControl = 4'b0010; // ADD
            end

            2'b01: begin
                // Branch - always SUB so Zero flag indicates equality.
                // BLT/BGE/BLTU/BGEU also use SUB; the top-level branch logic
                // uses the sign of the result, not just Zero.
                ALUControl = 4'b0110; // SUB
            end

            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (opcode == 7'b0110011 && funct7 == 7'b0100000)
                            ALUControl = 4'b0110; // SUB (R-type only)
                        else
                            ALUControl = 4'b0010; // ADD / ADDI
                    end
                    3'b001: ALUControl = 4'b1000; // SLL
                    3'b010: ALUControl = 4'b0111; // SLT / SLTI (signed)
                    3'b011: ALUControl = 4'b1011; // SLTU / SLTIU (unsigned)
                    3'b100: ALUControl = 4'b1010; // XOR
                    3'b101: ALUControl = 4'b1001; // SRL
                    3'b110: ALUControl = 4'b0001; // OR
                    3'b111: ALUControl = 4'b0000; // AND
                    default: ALUControl = 4'b0010;
                endcase
            end

            default: ALUControl = 4'b0010;
        endcase
    end
endmodule
