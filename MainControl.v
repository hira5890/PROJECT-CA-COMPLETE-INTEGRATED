`timescale 1ns / 1ps

module MainControl (
    input  [6:0] opcode,
    output reg        RegWrite,
    output reg [1:0]  ALUOp,
    output reg        MemRead,
    output reg        MemWrite,
    output reg        ALUSrc,
    output reg        MemtoReg,
    output reg        Branch,
    output reg        Jump        // FIX: added Jump output port
);
    always @(*) begin
        // Safe defaults
        RegWrite = 1'b0;
        ALUOp    = 2'b00;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        ALUSrc   = 1'b0;
        MemtoReg = 1'b0;
        Branch   = 1'b0;
        Jump     = 1'b0;    // FIX: default added

        case (opcode)

            7'b0110011: begin // R-type
                RegWrite = 1'b1;
                ALUOp    = 2'b10;
                ALUSrc   = 1'b0;
                MemtoReg = 1'b0;
            end

            7'b0010011: begin // I-type ALU (ADDI etc.)
                RegWrite = 1'b1;
                ALUOp    = 2'b10;
                ALUSrc   = 1'b1;
                MemtoReg = 1'b0;
            end

            7'b0000011: begin // Load (LW)
                RegWrite = 1'b1;
                ALUOp    = 2'b00;
                MemRead  = 1'b1;
                ALUSrc   = 1'b1;
                MemtoReg = 1'b1;
            end

            7'b0100011: begin // Store (SW)
                RegWrite = 1'b0;
                ALUOp    = 2'b00;
                MemWrite = 1'b1;
                ALUSrc   = 1'b1;
            end

            7'b1100011: begin // Branch (BEQ/BNE)
                RegWrite = 1'b0;
                ALUOp    = 2'b01;
                Branch   = 1'b1;
                ALUSrc   = 1'b0;
            end

            7'b1101111: begin // JAL
                RegWrite = 1'b1;
                ALUOp    = 2'b00;
                ALUSrc   = 1'b1;
                Jump     = 1'b1;    // FIX: assert Jump
            end

            7'b1100111: begin // JALR
                RegWrite = 1'b1;
                ALUOp    = 2'b00;
                ALUSrc   = 1'b1;
                Jump     = 1'b1;    // FIX: assert Jump
            end

            7'b0110111: begin // LUI
                RegWrite = 1'b1;
                ALUOp    = 2'b00;
                ALUSrc   = 1'b1;
                MemtoReg = 1'b0;
            end

            default: begin
                /* safe defaults already set above */
            end

        endcase
    end

endmodule
