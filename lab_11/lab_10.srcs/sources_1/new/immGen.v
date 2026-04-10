`timescale 1ns / 1ps

module immGen (
    input  wire [31:0] inst,     // 32-bit instruction input
    output reg  [31:0] imm_out   // sign-extended immediate output
);

    // Extract opcode field (bits [6:0])
    wire [6:0] opcode;
    assign opcode = inst[6:0];

    always @(*) begin
        case (opcode)

            // -------------------------------
            // I-TYPE FORMAT
            // Used by: LOAD, OP-IMM, JALR
            // Immediate = bits [31:20], sign-extended
            // -------------------------------
            7'b0000011,   // LOAD instructions
            7'b0010011,   // Arithmetic immediate (ADDI, etc.)
            7'b1100111:   // JALR
                imm_out = { {20{inst[31]}}, inst[31:20] };

            // -------------------------------
            // S-TYPE FORMAT (STORE)
            // Immediate split across two fields:
            // [31:25] and [11:7]
            // -------------------------------
            7'b0100011:
                imm_out = { {20{inst[31]}},
                            inst[31:25],
                            inst[11:7] };

            // -------------------------------
            // B-TYPE FORMAT (BRANCH)
            // Immediate bits arranged as:
            // [12 | 10:5 | 4:1 | 11] << 1
            // Note: LSB is always 0 (implicit shift)
            // -------------------------------
            7'b1100011:
                imm_out = { {19{inst[31]}}, // sign extension
                            inst[31],       // imm[12]
                            inst[7],        // imm[11]
                            inst[30:25],    // imm[10:5]
                            inst[11:8],     // imm[4:1]
                            1'b0 };         // shift left by 1

            // -------------------------------
            // U-TYPE FORMAT (LUI, AUIPC)
            // Upper 20 bits used, lower 12 bits are zero
            // -------------------------------
            7'b0110111,   // LUI
            7'b0010111:   // AUIPC
                imm_out = { inst[31:12], 12'b0 };

            // -------------------------------
            // J-TYPE FORMAT (JAL)
            // Immediate layout:
            // [20 | 10:1 | 11 | 19:12] << 1
            // -------------------------------
            7'b1101111:
                imm_out = { {11{inst[31]}}, // sign extension
                            inst[31],       // imm[20]
                            inst[19:12],    // imm[19:12]
                            inst[20],       // imm[11]
                            inst[30:21],    // imm[10:1]
                            1'b0 };         // shift left by 1

            // -------------------------------
            // DEFAULT CASE
            // No valid immediate
            // -------------------------------
            default:
                imm_out = 32'b0;

        endcase
    end

endmodule