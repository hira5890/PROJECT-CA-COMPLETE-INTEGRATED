`timescale 1ns / 1ps
// =============================================================================
// instruction_mem_bgt
//
// Demonstrates BGT (Branch if Greater Than).
//
// RISC-V has no BGT opcode in the ISA.  BGT is a pseudo-instruction
// implemented as BLT with the two source registers swapped:
//   BGT rs1, rs2, offset  =  BLT rs2, rs1, offset
// funct3 = 100 (BLT), opcode = 1100011 (branch).
//
// Program counts x10 from 0 up to 3, branching back each time x10 < x11.
// The branch condition written as BGT is: "branch if x11 > x10",
// encoded as: BLT x10, x11, offset (branch if x10 < x11).
//
// PROGRAM FLOW:
//   0x00: ADDI x10, x0,  0   x10 = 0  (counter, starts at 0)
//   0x04: ADDI x11, x0,  3   x11 = 3  (loop limit)
//   0x08: ADDI x5,  x0, 512  x5  = 0x200  (LED address)
//   0x0C: ADDI x10, x10, 1   x10++        <-- LOOP top
//   0x10: BLT  x10, x11, -4  BGT x11,x10: if x10 < x11 branch back to 0x0C
//   0x14: SW   x10, 0(x5)    mem[0x200] = 3  (loop exit value)
//   0x18: JAL  x0,  0        HALT
//
// WHAT TO OBSERVE ON THE FPGA:
//   PC sequence:
//     0000 -> 0004 -> 0008 -> 000C -> 0010 (branch taken, x10=1 < 3)
//                          -> 000C -> 0010 (branch taken, x10=2 < 3)
//                          -> 000C -> 0010 (branch NOT taken, x10=3 = 3)
//                          -> 0014 -> 0018 (halts)
//
//   BGT (BLT) fires at PC = 0010 on every loop iteration.
//   LEDs latch when PC = 0010 showing:
//     Branch=1, ALUOp=01, RegWrite=0, ALUSrc=0
//     Jump=0, MemRead=0, MemWrite=0, MemtoReg=0
//   Final halt at 0018.
//
// REGISTER MAP:
//   x5  = 0x200  (LED address)
//   x10 = loop counter  (0 -> 1 -> 2 -> 3, then stored)
//   x11 = 3  (loop limit)
// =============================================================================
module instruction_mem_bgt #(
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

        // 0x00: ADDI x10, x0, 0
        //   x10 = 0  (initialise counter)
        //   = 0x00000513
        memory[3]  = 8'h00; memory[2]  = 8'h00; memory[1]  = 8'h05; memory[0]  = 8'h13;

        // 0x04: ADDI x11, x0, 3
        //   x11 = 3  (loop will run while x10 < 3)
        //   = 0x00300593
        memory[7]  = 8'h00; memory[6]  = 8'h30; memory[5]  = 8'h05; memory[4]  = 8'h93;

        // 0x08: ADDI x5, x0, 512
        //   x5 = 0x200
        //   = 0x20000293
        memory[11] = 8'h20; memory[10] = 8'h00; memory[9]  = 8'h02; memory[8]  = 8'h93;

        // 0x0C: ADDI x10, x10, 1      <-- LOOP TOP
        //   x10 = x10 + 1
        //   = 0x00150513
        memory[15] = 8'h00; memory[14] = 8'h15; memory[13] = 8'h05; memory[12] = 8'h13;

        // 0x10: BLT x10, x11, -4
        //   *** BGT PSEUDO-INSTRUCTION ***
        //   BGT x11, x10, -4  means "branch if x11 > x10"
        //   Encoded as BLT rs1=x10, rs2=x11, offset=-4
        //   (RISC-V BGT = BLT with operands swapped)
        //   If x10 < x11 (i.e. counter has not reached limit):
        //     PC = 0x10 + (-4) = 0x0C  (back to LOOP TOP)
        //   Else fall through to 0x14.
        //   B-type: imm=-4, rs2=x11=01011, rs1=x10=01010, funct3=100, op=1100011
        //   = 0xFEB54EE3
        memory[19] = 8'hFE; memory[18] = 8'hB5; memory[17] = 8'h4E; memory[16] = 8'hE3;

        // 0x14: SW x10, 0(x5)
        //   mem[0x200] = x10 = 3  (loop exit value)
        //   = 0x00A2A023
        memory[23] = 8'h00; memory[22] = 8'hA2; memory[21] = 8'hA0; memory[20] = 8'h23;

        // 0x18: JAL x0, 0   (true self-loop HALT)
        //   = 0x0000006F
        memory[27] = 8'h00; memory[26] = 8'h00; memory[25] = 8'h00; memory[24] = 8'h6F;
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
