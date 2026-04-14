`timescale 1ns / 1ps
// =============================================================================
// instruction_mem_jalr  (fixed)
//
// FIX: halt was JAL x0, -4 which from 0x24 jumps to 0x20 (the NOP),
// creating a 0x20->0x24->0x20 ping-pong loop instead of halting.
// Changed to JAL x0, 0 = 0x0000006F which is a true self-loop:
// PC stays at 0x24 forever.
//
// PROGRAM FLOW:
//   0x00: ADDI x10, x0, 42    x10 = 42  (value to display)
//   0x04: ADDI x5,  x0, 512   x5  = 0x200 (LED/7-seg address)
//   0x08: ADDI x6,  x0, 44    x6  = 0x2C  (subroutine byte address)
//   0x0C: ADDI x11, x0, 5     x11 = 5
//   0x10: NOP
//   0x14: NOP
//   0x18: NOP
//   0x1C: JALR x1, x6, 0      PC=0x2C, x1=0x20  *** JALR call ***
//   0x20: NOP                  return landing
//   0x24: JAL  x0, 0           *** TRUE SELF-LOOP HALT ***  PC stays 0x24
//   0x28: NOP                  (never reached)
//   0x2C: SW   x10, 0(x5)      mem[0x200] = 42
//   0x30: ADD  x10, x10, x11   x10 = 47
//   0x34: JALR x0, x1, 0       PC=0x20          *** JALR return ***
//   0x38: NOP
// =============================================================================
module instruction_mem_jalr #(
    parameter OPERAND_LENGTH = 31
)(
    input  [OPERAND_LENGTH:0] instAddress,
    output reg [31:0]         instruction
);
    reg [7:0] memory [0:511];
    integer j;

    initial begin
        for (j = 0; j < 512; j = j + 1)
            memory[j] = 8'h00;

        // 0x00: ADDI x10, x0, 42  (= 0x02A00513)
        memory[3]  = 8'h02; memory[2]  = 8'hA0; memory[1]  = 8'h05; memory[0]  = 8'h13;

        // 0x04: ADDI x5, x0, 512  (= 0x20000293)
        memory[7]  = 8'h20; memory[6]  = 8'h00; memory[5]  = 8'h02; memory[4]  = 8'h93;

        // 0x08: ADDI x6, x0, 44   (= 0x02C00313)  x6 = 0x2C subroutine addr
        memory[11] = 8'h02; memory[10] = 8'hC0; memory[9]  = 8'h03; memory[8]  = 8'h13;

        // 0x0C: ADDI x11, x0, 5   (= 0x00500593)
        memory[15] = 8'h00; memory[14] = 8'h50; memory[13] = 8'h05; memory[12] = 8'h93;

        // 0x10: NOP  (= 0x00000013)
        memory[19] = 8'h00; memory[18] = 8'h00; memory[17] = 8'h00; memory[16] = 8'h13;

        // 0x14: NOP
        memory[23] = 8'h00; memory[22] = 8'h00; memory[21] = 8'h00; memory[20] = 8'h13;

        // 0x18: NOP
        memory[27] = 8'h00; memory[26] = 8'h00; memory[25] = 8'h00; memory[24] = 8'h13;

        // 0x1C: JALR x1, x6, 0  (= 0x000300E7)
        //   PC = x6 + 0 = 0x2C,  x1 = 0x20
        memory[31] = 8'h00; memory[30] = 8'h03; memory[29] = 8'h00; memory[28] = 8'hE7;

        // 0x20: NOP  - return landing point
        memory[35] = 8'h00; memory[34] = 8'h00; memory[33] = 8'h00; memory[32] = 8'h13;

        // 0x24: JAL x0, 0  (= 0x0000006F)  TRUE self-loop: PC = 0x24 + 0 = 0x24
        //   FIX: was 0xFFDFF06F (JAL x0,-4) which jumped to 0x20 instead of halting
        memory[39] = 8'h00; memory[38] = 8'h00; memory[37] = 8'h00; memory[36] = 8'h6F;

        // 0x28: NOP  (never reached)
        memory[43] = 8'h00; memory[42] = 8'h00; memory[41] = 8'h00; memory[40] = 8'h13;

        // 0x2C: SW x10, 0(x5)  (= 0x00A2A023)  mem[0x200] = x10 = 42
        memory[47] = 8'h00; memory[46] = 8'hA2; memory[45] = 8'hA0; memory[44] = 8'h23;

        // 0x30: ADD x10, x10, x11  (= 0x00B50533)  x10 = 42+5 = 47
        memory[51] = 8'h00; memory[50] = 8'hB5; memory[49] = 8'h05; memory[48] = 8'h33;

        // 0x34: JALR x0, x1, 0  (= 0x00008067)  PC = x1 = 0x20
        memory[55] = 8'h00; memory[54] = 8'h00; memory[53] = 8'h80; memory[52] = 8'h67;

        // 0x38: NOP
        memory[59] = 8'h00; memory[58] = 8'h00; memory[57] = 8'h00; memory[56] = 8'h13;
    end

    always @(*) begin
        instruction = {
            memory[instAddress + 3],
            memory[instAddress + 2],
            memory[instAddress + 1],
            memory[instAddress + 0]
        };
    end

endmodule
