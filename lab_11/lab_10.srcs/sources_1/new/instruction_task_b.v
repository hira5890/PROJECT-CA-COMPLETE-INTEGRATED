`timescale 1ns / 1ps
// =============================================================================
// Module      : instruction_task_b_fib
// Description : Recursive Fibonacci using hardware stack.
//               Computes fib(0) through fib(6) = 0,1,1,2,3,5,8
//               Displays each result on the LED/seven-segment with ~0.8s delay.
//
// ONLY CHANGE from fib(5) version:
//   0x0C: addi x21, x0, 7    (was 6) -> limit=7 shows fib(0)..fib(6)
//   memory[14] = 8'h70        (was 8'h60)
//
// Display sequence: 0 -> 1 -> 1 -> 2 -> 3 -> 5 -> 8 (holds on 8)
// =============================================================================
module instruction_task_b_fib #(
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
        // INIT (0x00 - 0x0F)
        // =====================================================================
        // 0x00: addi x2, x0, 128        SP = 0x80
        memory[3] =8'h08; memory[2] =8'h00; memory[1] =8'h01; memory[0] =8'h13;
        // 0x04: addi x5, x0, 512        x5 = 0x200 (LED address)
        memory[7] =8'h20; memory[6] =8'h00; memory[5] =8'h02; memory[4] =8'h93;
        // 0x08: addi x20, x0, 0         i = 0
        memory[11]=8'h00; memory[10]=8'h00; memory[9] =8'h0A; memory[8] =8'h13;
        // 0x0C: addi x21, x0, 7         limit = 7 (show fib(0)..fib(6)) <-- ONLY CHANGE
        memory[15]=8'h00; memory[14]=8'h70; memory[13]=8'h0A; memory[12]=8'h93;

        // =====================================================================
        // OUTER LOOP (0x10 - 0x2F)
        // =====================================================================
        // 0x10: add x10, x20, x0
        memory[19]=8'h00; memory[18]=8'h0A; memory[17]=8'h05; memory[16]=8'h33;
        // 0x14: jal x1, fib  (+60 -> 0x50)
        memory[23]=8'h03; memory[22]=8'hC0; memory[21]=8'h00; memory[20]=8'hEF;
        // 0x18: sw x10, 0(x5)
        memory[27]=8'h00; memory[26]=8'hA2; memory[25]=8'hA0; memory[24]=8'h23;
        // 0x1C: jal x1, delay  (+20 -> 0x30)
        memory[31]=8'h01; memory[30]=8'h40; memory[29]=8'h00; memory[28]=8'hEF;
        // 0x20: addi x20, x20, 1
        memory[35]=8'h00; memory[34]=8'h1A; memory[33]=8'h0A; memory[32]=8'h13;
        // 0x24: bne x20, x21, loop  (-20 -> 0x10)
        memory[39]=8'hFF; memory[38]=8'h5A; memory[37]=8'h16; memory[36]=8'hE3;
        // 0x28: nop
        memory[43]=8'h00; memory[42]=8'h00; memory[41]=8'h00; memory[40]=8'h13;
        // 0x2C: jal x0, -4  (halt)
        memory[47]=8'hFF; memory[46]=8'hDF; memory[45]=8'hF0; memory[44]=8'h6F;

        // =====================================================================
        // DELAY SUBROUTINE (0x30 - 0x4F)  ~0.8s @ 10MHz
        // =====================================================================
        // 0x30: addi x6, x0, 2000
        memory[51]=8'h7D; memory[50]=8'h00; memory[49]=8'h03; memory[48]=8'h13;
        // 0x34: addi x7, x0, 2000
        memory[55]=8'h7D; memory[54]=8'h00; memory[53]=8'h03; memory[52]=8'h93;
        // 0x38: addi x7, x7, -1
        memory[59]=8'hFF; memory[58]=8'hF3; memory[57]=8'h83; memory[56]=8'h93;
        // 0x3C: bne x7, x0, -4
        memory[63]=8'hFE; memory[62]=8'h03; memory[61]=8'h9E; memory[60]=8'hE3;
        // 0x40: addi x6, x6, -1
        memory[67]=8'hFF; memory[66]=8'hF3; memory[65]=8'h03; memory[64]=8'h13;
        // 0x44: bne x6, x0, -16
        memory[71]=8'hFE; memory[70]=8'h03; memory[69]=8'h18; memory[68]=8'hE3;
        // 0x48: jalr x0, x1, 0
        memory[75]=8'h00; memory[74]=8'h00; memory[73]=8'h80; memory[72]=8'h67;
        // 0x4C: nop
        memory[79]=8'h00; memory[78]=8'h00; memory[77]=8'h00; memory[76]=8'h13;

        // =====================================================================
        // FIB FUNCTION (0x50 - 0x93)
        // =====================================================================
        // 0x50: addi x2, x2, -16
        memory[83]=8'hFF; memory[82]=8'h01; memory[81]=8'h01; memory[80]=8'h13;
        // 0x54: sw x1, 12(x2)
        memory[87]=8'h00; memory[86]=8'h11; memory[85]=8'h26; memory[84]=8'h23;
        // 0x58: sw x10, 8(x2)
        memory[91]=8'h00; memory[90]=8'hA1; memory[89]=8'h24; memory[88]=8'h23;
        // 0x5C: beq x10, x0, base0  (+56 -> 0x94)
        memory[95]=8'h02; memory[94]=8'h05; memory[93]=8'h0C; memory[92]=8'h63;
        // 0x60: addi x6, x0, 1
        memory[99]=8'h00; memory[98]=8'h10; memory[97]=8'h03; memory[96]=8'h13;
        // 0x64: beq x10, x6, base1  (+64 -> 0xA4)
        memory[103]=8'h04; memory[102]=8'h65; memory[101]=8'h00; memory[100]=8'h63;
        // 0x68: addi x10, x10, -1
        memory[107]=8'hFF; memory[106]=8'hF5; memory[105]=8'h05; memory[104]=8'h13;
        // 0x6C: jal x1, fib  (-28 -> 0x50)
        memory[111]=8'hFE; memory[110]=8'h5F; memory[109]=8'hF0; memory[108]=8'hEF;
        // 0x70: sw x10, 4(x2)
        memory[115]=8'h00; memory[114]=8'hA1; memory[113]=8'h22; memory[112]=8'h23;
        // 0x74: lw x10, 8(x2)
        memory[119]=8'h00; memory[118]=8'h81; memory[117]=8'h25; memory[116]=8'h03;
        // 0x78: addi x10, x10, -2
        memory[123]=8'hFF; memory[122]=8'hE5; memory[121]=8'h05; memory[120]=8'h13;
        // 0x7C: jal x1, fib  (-44 -> 0x50)
        memory[127]=8'hFD; memory[126]=8'h5F; memory[125]=8'hF0; memory[124]=8'hEF;
        // 0x80: lw x6, 4(x2)
        memory[131]=8'h00; memory[130]=8'h41; memory[129]=8'h23; memory[128]=8'h03;
        // 0x84: add x10, x10, x6
        memory[135]=8'h00; memory[134]=8'h65; memory[133]=8'h05; memory[132]=8'h33;
        // 0x88: lw x1, 12(x2)
        memory[139]=8'h00; memory[138]=8'hC1; memory[137]=8'h20; memory[136]=8'h83;
        // 0x8C: addi x2, x2, 16
        memory[143]=8'h01; memory[142]=8'h01; memory[141]=8'h01; memory[140]=8'h13;
        // 0x90: jalr x0, x1, 0
        memory[147]=8'h00; memory[146]=8'h00; memory[145]=8'h80; memory[144]=8'h67;

        // =====================================================================
        // BASE CASE 0 (0x94): return 0
        // =====================================================================
        // 0x94: addi x10, x0, 0
        memory[151]=8'h00; memory[150]=8'h00; memory[149]=8'h05; memory[148]=8'h13;
        // 0x98: lw x1, 12(x2)
        memory[155]=8'h00; memory[154]=8'hC1; memory[153]=8'h20; memory[152]=8'h83;
        // 0x9C: addi x2, x2, 16
        memory[159]=8'h01; memory[158]=8'h01; memory[157]=8'h01; memory[156]=8'h13;
        // 0xA0: jalr x0, x1, 0
        memory[163]=8'h00; memory[162]=8'h00; memory[161]=8'h80; memory[160]=8'h67;

        // =====================================================================
        // BASE CASE 1 (0xA4): return 1
        // =====================================================================
        // 0xA4: addi x10, x0, 1
        memory[167]=8'h00; memory[166]=8'h10; memory[165]=8'h05; memory[164]=8'h13;
        // 0xA8: lw x1, 12(x2)
        memory[171]=8'h00; memory[170]=8'hC1; memory[169]=8'h20; memory[168]=8'h83;
        // 0xAC: addi x2, x2, 16
        memory[175]=8'h01; memory[174]=8'h01; memory[173]=8'h01; memory[172]=8'h13;
        // 0xB0: jalr x0, x1, 0
        memory[179]=8'h00; memory[178]=8'h00; memory[177]=8'h80; memory[176]=8'h67;
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