`timescale 1ns / 1ps
// =============================================================================
// instruction_mem_blt
//
// Demonstrates BLT (Branch if Less Than) - a real RISC-V instruction.
// funct3=100, opcode=1100011
//
// PROGRAM:
//   0x00: ADDI x10, x0,  0    x10 = 0  (counter)
//   0x04: ADDI x11, x0,  3    x11 = 3  (limit)
//   0x08: ADDI x5,  x0,  512  x5  = 0x200 (LED address)
//   0x0C: ADDI x10, x10, 1    x10++     <-- LOOP TOP
//   0x10: BLT  x10, x11, -4   if x10 < x11, branch back to 0x0C
//   0x14: SW   x10, 0(x5)     write final value (3) to LED
//   0x18: JAL  x0,  0         HALT
//
// PC SEQUENCE:
//   0000->0004->0008->000C->0010 (taken, x10=1<3) ->
//                    000C->0010 (taken, x10=2<3) ->
//                    000C->0010 (NOT taken, x10=3=3) ->
//   0014->0018 (halts)
// =============================================================================
module instruction_mem_blt #(
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

        // 0x00: ADDI x10, x0, 0   (x10 = 0)
        // encoding: 0x00000513
        memory[3]=8'h00; memory[2]=8'h00; memory[1]=8'h05; memory[0]=8'h13;

        // 0x04: ADDI x11, x0, 3   (x11 = 3)
        // encoding: 0x00300593
        memory[7]=8'h00; memory[6]=8'h30; memory[5]=8'h05; memory[4]=8'h93;

        // 0x08: ADDI x5, x0, 512  (x5 = 0x200, LED address)
        // encoding: 0x20000293
        memory[11]=8'h20; memory[10]=8'h00; memory[9]=8'h02; memory[8]=8'h93;

        // 0x0C: ADDI x10, x10, 1  (x10++)   LOOP TOP
        // encoding: 0x00150513
        memory[15]=8'h00; memory[14]=8'h15; memory[13]=8'h05; memory[12]=8'h13;

        // 0x10: BLT x10, x11, -4
        // Real RISC-V BLT: branch if signed(x10) < signed(x11)
        // offset=-4 -> PC = 0x10 + (-4) = 0x0C
        // B-type: imm=-4, rs2=x11(01011), rs1=x10(01010), funct3=100, op=1100011
        // encoding: 0xFEB54EE3
        memory[19]=8'hFE; memory[18]=8'hB5; memory[17]=8'h4E; memory[16]=8'hE3;

        // 0x14: SW x10, 0(x5)   (write x10=3 to address 0x200 -> LEDs)
        // encoding: 0x00A2A023
        memory[23]=8'h00; memory[22]=8'hA2; memory[21]=8'hA0; memory[20]=8'h23;

        // 0x18: JAL x0, 0   (HALT)
        // encoding: 0x0000006F
        memory[27]=8'h00; memory[26]=8'h00; memory[25]=8'h00; memory[24]=8'h6F;
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
