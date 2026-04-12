`timescale 1ns / 1ps
// =============================================================================
// instruction_mem_taskb_simple
//
// Simple Task B demonstration program.
// No data memory required - all values computed in registers.
//
// NEW INSTRUCTIONS DEMONSTRATED:
//   LUI  (U-type) at 0x00 - loads immediate into upper 20 bits of x10
//   BNE  (B-type) at 0x14 - loops until x10 reaches limit of 3
//   JALR (I-type) at 0x20 - indirect call to display subroutine via x6
//   JALR (I-type) at 0x38 - return from subroutine via x1
//
// PROGRAM FLOW:
//   1. LUI x10, 0         x10 = 0 (start of count)
//   2. Set x11 = 3        (loop limit)
//   3. Set x5  = 0x200    (LED address)
//   4. Set x6  = 0x34     (address of display subroutine)
//   5. LOOP: x10++, BNE back while x10 != 3
//      exits with x10 = 3
//   6. x10 = x10 + 4 = 7  (final result)
//   7. JALR to display    (indirect jump via register x6)
//   8. display: SW x10 to LED, JALR return
//
// EXPECTED OUTPUT: 7 on seven-segment display
//
// REGISTER MAP:
//   x1  = return address saved by JALR call (= 0x24)
//   x5  = LED address = 0x200
//   x6  = display subroutine address = 0x34
//   x10 = working value (0 -> 1 -> 2 -> 3 -> 7)
//   x11 = loop limit = 3
//   x12 = constant 4 (added after loop)
//
// ADDRESS MAP:
//   0x00-0x0C : INIT
//   0x10-0x14 : LOOP  (BNE at 0x14 branches to 0x10)
//   0x18-0x28 : POST  (JALR call at 0x20)
//   0x2C-0x30 : HALT region
//   0x34-0x3C : display subroutine (JALR return at 0x38)
// =============================================================================
module instruction_mem_taskb_simple #(
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

        // =====================================================================
        // INIT (0x00 - 0x0C)
        // =====================================================================

        // 0x00: LUI x10, 0
        //       *** NEW INSTRUCTION: LUI ***
        //       x10 = 0x00000000  (upper 20 bits = 0, lower 12 = 0)
        //       This initialises our counter to 0 via LUI, not ADDI.
        //       Without LUI working, x10 would be garbage and BNE
        //       loop would run wrong number of times giving wrong result.
        //       U-type: imm[31:12]=0, rd=x10=01010, opcode=0110111
        //       = 0x00000537
        memory[3]  = 8'h00; memory[2]  = 8'h00; memory[1]  = 8'h05; memory[0]  = 8'h37;

        // 0x04: ADDI x11, x0, 3
        //       x11 = 3  (loop will run until x10 reaches this value)
        //       = 0x00300593
        memory[7]  = 8'h00; memory[6]  = 8'h30; memory[5]  = 8'h05; memory[4]  = 8'h93;

        // 0x08: ADDI x5, x0, 512
        //       x5 = 0x200  (LED / 7-seg output address)
        //       = 0x20000293
        memory[11] = 8'h20; memory[10] = 8'h00; memory[9]  = 8'h02; memory[8]  = 8'h93;

        // 0x0C: ADDI x6, x0, 52
        //       x6 = 52 = 0x34  (byte address of display subroutine)
        //       This register holds the jump target for JALR below.
        //       = 0x03400313
        memory[15] = 8'h03; memory[14] = 8'h40; memory[13] = 8'h03; memory[12] = 8'h13;

        // =====================================================================
        // LOOP (0x10 - 0x14)
        // Counts x10 from 0 up to 3 using BNE to loop back
        // =====================================================================

        // 0x10: ADDI x10, x10, 1
        //       x10 = x10 + 1  (increment counter)
        //       = 0x00150513
        memory[19] = 8'h00; memory[18] = 8'h15; memory[17] = 8'h05; memory[16] = 8'h13;

        // 0x14: BNE x10, x11, -4
        //       *** NEW INSTRUCTION: BNE ***
        //       If x10 != x11 (i.e. x10 != 3), branch back to 0x10
        //       offset = 0x10 - 0x14 = -4
        //       -4 mod 8192 = 8188 = 0x1FFC
        //       imm[12]=1,imm[11]=1,imm[10:5]=111111,imm[4:1]=1110
        //       rs1=x10=01010, rs2=x11=01011, funct3=001, op=1100011
        //       = 0xFEB51EE3
        memory[23] = 8'hFE; memory[22] = 8'hB5; memory[21] = 8'h1E; memory[20] = 8'hE3;

        // =====================================================================
        // POST-LOOP (0x18 - 0x28)
        // x10 = 3 here. Add 4 to get 7, then JALR to display.
        // =====================================================================

        // 0x18: ADDI x12, x0, 4
        //       x12 = 4  (value to add to counter result)
        //       = 0x00400613
        memory[27] = 8'h00; memory[26] = 8'h40; memory[25] = 8'h06; memory[24] = 8'h13;

        // 0x1C: ADD x10, x10, x12
        //       x10 = 3 + 4 = 7  (final display value)
        //       rs2=x12=01100,rs1=x10=01010,funct3=0,rd=x10=01010,op=0110011
        //       = 0x00C50533
        memory[31] = 8'h00; memory[30] = 8'hC5; memory[29] = 8'h05; memory[28] = 8'h33;

        // 0x20: JALR x1, x6, 0
        //       *** NEW INSTRUCTION: JALR (indirect call) ***
        //       PC = x6 + 0 = 0x34  (jump to display subroutine)
        //       x1 = PC+4 = 0x24    (save return address)
        //       Why JALR and not JAL: target is in register x6 (computed address)
        //       This is the defining use case for JALR - register-indirect jump.
        //       imm=0, rs1=x6=00110, funct3=000, rd=x1=00001, op=1100111
        //       = 0x000300E7
        memory[35] = 8'h00; memory[34] = 8'h03; memory[33] = 8'h00; memory[32] = 8'hE7;

        // 0x24: NOP  (execution returns here from display subroutine)
        //       = 0x00000013
        memory[39] = 8'h00; memory[38] = 8'h00; memory[37] = 8'h00; memory[36] = 8'h13;

        // 0x28: NOP
        memory[43] = 8'h00; memory[42] = 8'h00; memory[41] = 8'h00; memory[40] = 8'h13;

        // =====================================================================
        // HALT (0x2C - 0x30)
        // =====================================================================

        // 0x2C: JAL x0, -4  (infinite self-loop = halt)
        //       = 0xFFDFF06F
        memory[47] = 8'hFF; memory[46] = 8'hDF; memory[45] = 8'hF0; memory[44] = 8'h6F;

        // 0x30: NOP padding
        memory[51] = 8'h00; memory[50] = 8'h00; memory[49] = 8'h00; memory[48] = 8'h13;

        // =====================================================================
        // display SUBROUTINE (0x34 - 0x3C)
        // Argument  : x10 = value to show (= 7)
        // Action    : SW x10 to LED address in x5
        // Returns   : JALR x0, x1, 0  back to 0x24
        // =====================================================================

        // 0x34: SW x10, 0(x5)
        //       Writes x10 (=7) to address 0x200, driving LEDs and 7-seg
        //       rs2=x10=01010, rs1=x5=00101, funct3=010, imm=0, op=0100011
        //       = 0x00A2A023
        memory[55] = 8'h00; memory[54] = 8'hA2; memory[53] = 8'hA0; memory[52] = 8'h23;

        // 0x38: JALR x0, x1, 0
        //       *** NEW INSTRUCTION: JALR (return) ***
        //       PC = x1 + 0 = 0x24  (return to caller)
        //       x0 = discarded      (no link register needed for return)
        //       imm=0, rs1=x1=00001, funct3=000, rd=x0=00000, op=1100111
        //       = 0x00008067
        memory[59] = 8'h00; memory[58] = 8'h00; memory[57] = 8'h80; memory[56] = 8'h67;

        // 0x3C: NOP padding
        memory[63] = 8'h00; memory[62] = 8'h00; memory[61] = 8'h00; memory[60] = 8'h13;

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