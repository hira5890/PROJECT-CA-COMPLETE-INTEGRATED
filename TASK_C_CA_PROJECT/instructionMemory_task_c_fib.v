`timescale 1ns / 1ps
// =============================================================================
// Module      : instruction_task_b_fib
// Description : Recursive Fibonacci using hardware stack.
//               n is read from switches (SW[2:0]) at address 0x300.
//               Computes fib(0) through fib(n) sequentially on 7-seg.
//               Max useful n = 6 (fib(6)=8, fits on one 7-seg digit).
// =============================================================================
module instruction_task_c_fib #(
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
        // INIT (0x00 - 0x17)
        // =====================================================================
        // 0x00: addi x2, x0, 128        SP = 0x80
        memory[3] =8'h08; memory[2] =8'h00; memory[1] =8'h01; memory[0] =8'h13;
        // 0x04: addi x5, x0, 512        x5 = 0x200 (LED address)
        memory[7] =8'h20; memory[6] =8'h00; memory[5] =8'h02; memory[4] =8'h93;
        // 0x08: addi x3, x0, 768        x3 = 0x300 (switch address)
        memory[11]=8'h30; memory[10]=8'h00; memory[9] =8'h01; memory[8] =8'h93;
        // 0x0C: lw x21, 0(x3)           x21 = switch_in (user's n)
        memory[15]=8'h00; memory[14]=8'h01; memory[13]=8'hAA; memory[12]=8'h83;
        // 0x10: addi x21, x21, 1        limit = n+1 (loop i=0..n)
        memory[19]=8'h00; memory[18]=8'h1A; memory[17]=8'h8A; memory[16]=8'h93;
        // 0x14: addi x20, x0, 0         i = 0
        memory[23]=8'h00; memory[22]=8'h00; memory[21]=8'h0A; memory[20]=8'h13;

        // =====================================================================
        // OUTER LOOP (0x18 - 0x37)
        // =====================================================================
        // 0x18: add x10, x20, x0        a0 = i
        memory[27]=8'h00; memory[26]=8'h0A; memory[25]=8'h05; memory[24]=8'h33;
        // 0x1C: jal x1, fib             call fib (fib at 0x58, offset=+60)
        memory[31]=8'h03; memory[30]=8'hC0; memory[29]=8'h00; memory[28]=8'hEF;
        // 0x20: sw x10, 0(x5)           LED = fib(i)
        memory[35]=8'h00; memory[34]=8'hA2; memory[33]=8'hA0; memory[32]=8'h23;
        // 0x24: jal x1, delay           call delay (delay at 0x38, offset=+20)
        memory[39]=8'h01; memory[38]=8'h40; memory[37]=8'h00; memory[36]=8'hEF;
        // 0x28: addi x20, x20, 1        i++
        memory[43]=8'h00; memory[42]=8'h1A; memory[41]=8'h0A; memory[40]=8'h13;
        // 0x2C: bne x20, x21, loop      if i != limit goto 0x18 (offset=-20)
        memory[47]=8'hFF; memory[46]=8'h5A; memory[45]=8'h16; memory[44]=8'hE3;
        // 0x30: nop
        memory[51]=8'h00; memory[50]=8'h00; memory[49]=8'h00; memory[48]=8'h13;
        // 0x34: jal x0, -4              halt (infinite loop)
        memory[55]=8'hFF; memory[54]=8'hDF; memory[53]=8'hF0; memory[52]=8'h6F;

        // =====================================================================
        // DELAY SUBROUTINE (0x38 - 0x57)  ~0.8s @ 10MHz
        // =====================================================================
        // 0x38: addi x6, x0, 2000
        memory[59]=8'h7D; memory[58]=8'h00; memory[57]=8'h03; memory[56]=8'h13;
        // 0x3C: addi x7, x0, 2000
        memory[63]=8'h7D; memory[62]=8'h00; memory[61]=8'h03; memory[60]=8'h93;
        // 0x40: addi x7, x7, -1
        memory[67]=8'hFF; memory[66]=8'hF3; memory[65]=8'h83; memory[64]=8'h93;
        // 0x44: bne x7, x0, -4
        memory[71]=8'hFE; memory[70]=8'h03; memory[69]=8'h9E; memory[68]=8'hE3;
        // 0x48: addi x6, x6, -1
        memory[75]=8'hFF; memory[74]=8'hF3; memory[73]=8'h03; memory[72]=8'h13;
        // 0x4C: bne x6, x0, -16
        memory[79]=8'hFE; memory[78]=8'h03; memory[77]=8'h18; memory[76]=8'hE3;
        // 0x50: jalr x0, x1, 0
        memory[83]=8'h00; memory[82]=8'h00; memory[81]=8'h80; memory[80]=8'h67;
        // 0x54: nop
        memory[87]=8'h00; memory[86]=8'h00; memory[85]=8'h00; memory[84]=8'h13;

        // =====================================================================
        // FIB FUNCTION (0x58 - 0x9B)
        // =====================================================================
        // 0x58: addi x2, x2, -16
        memory[91] =8'hFF; memory[90] =8'h01; memory[89] =8'h01; memory[88] =8'h13;
        // 0x5C: sw x1, 12(x2)
        memory[95] =8'h00; memory[94] =8'h11; memory[93] =8'h26; memory[92] =8'h23;
        // 0x60: sw x10, 8(x2)
        memory[99] =8'h00; memory[98] =8'hA1; memory[97] =8'h24; memory[96] =8'h23;
        // 0x64: beq x10, x0, base0      if n==0 goto 0x9C (offset=+56)
        memory[103]=8'h02; memory[102]=8'h05; memory[101]=8'h0C; memory[100]=8'h63;
        // 0x68: addi x6, x0, 1
        memory[107]=8'h00; memory[106]=8'h10; memory[105]=8'h03; memory[104]=8'h13;
        // 0x6C: beq x10, x6, base1      if n==1 goto 0xAC (offset=+64)
        memory[111]=8'h04; memory[110]=8'h65; memory[109]=8'h00; memory[108]=8'h63;
        // 0x70: addi x10, x10, -1
        memory[115]=8'hFF; memory[114]=8'hF5; memory[113]=8'h05; memory[112]=8'h13;
        // 0x74: jal x1, fib             fib(n-1)  (offset=-28 -> 0x58)
        memory[119]=8'hFE; memory[118]=8'h5F; memory[117]=8'hF0; memory[116]=8'hEF;
        // 0x78: sw x10, 4(x2)           save fib(n-1)
        memory[123]=8'h00; memory[122]=8'hA1; memory[121]=8'h22; memory[120]=8'h23;
        // 0x7C: lw x10, 8(x2)           restore n
        memory[127]=8'h00; memory[126]=8'h81; memory[125]=8'h25; memory[124]=8'h03;
        // 0x80: addi x10, x10, -2       n-2
        memory[131]=8'hFF; memory[130]=8'hE5; memory[129]=8'h05; memory[128]=8'h13;
        // 0x84: jal x1, fib             fib(n-2)  (offset=-44 -> 0x58)
        memory[135]=8'hFD; memory[134]=8'h5F; memory[133]=8'hF0; memory[132]=8'hEF;
        // 0x88: lw x6, 4(x2)            load fib(n-1)
        memory[139]=8'h00; memory[138]=8'h41; memory[137]=8'h23; memory[136]=8'h03;
        // 0x8C: add x10, x10, x6        fib(n) = fib(n-1)+fib(n-2)
        memory[143]=8'h00; memory[142]=8'h65; memory[141]=8'h05; memory[140]=8'h33;
        // 0x90: lw x1, 12(x2)
        memory[147]=8'h00; memory[146]=8'hC1; memory[145]=8'h20; memory[144]=8'h83;
        // 0x94: addi x2, x2, 16
        memory[151]=8'h01; memory[150]=8'h01; memory[149]=8'h01; memory[148]=8'h13;
        // 0x98: jalr x0, x1, 0
        memory[155]=8'h00; memory[154]=8'h00; memory[153]=8'h80; memory[152]=8'h67;

        // =====================================================================
        // BASE CASE 0 (0x9C): return 0
        // =====================================================================
        // 0x9C: addi x10, x0, 0
        memory[159]=8'h00; memory[158]=8'h00; memory[157]=8'h05; memory[156]=8'h13;
        // 0xA0: lw x1, 12(x2)
        memory[163]=8'h00; memory[162]=8'hC1; memory[161]=8'h20; memory[160]=8'h83;
        // 0xA4: addi x2, x2, 16
        memory[167]=8'h01; memory[166]=8'h01; memory[165]=8'h01; memory[164]=8'h13;
        // 0xA8: jalr x0, x1, 0
        memory[171]=8'h00; memory[170]=8'h00; memory[169]=8'h80; memory[168]=8'h67;

        // =====================================================================
        // BASE CASE 1 (0xAC): return 1
        // =====================================================================
        // 0xAC: addi x10, x0, 1
        memory[175]=8'h00; memory[174]=8'h10; memory[173]=8'h05; memory[172]=8'h13;
        // 0xB0: lw x1, 12(x2)
        memory[179]=8'h00; memory[178]=8'hC1; memory[177]=8'h20; memory[176]=8'h83;
        // 0xB4: addi x2, x2, 16
        memory[183]=8'h01; memory[182]=8'h01; memory[181]=8'h01; memory[180]=8'h13;
        // 0xB8: jalr x0, x1, 0
        memory[187]=8'h00; memory[186]=8'h00; memory[185]=8'h80; memory[184]=8'h67;
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
