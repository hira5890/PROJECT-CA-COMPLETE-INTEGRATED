`timescale 1ns / 1ps

module instructionMemory #(
    parameter OPERAND_LENGTH = 31
)(
    input  [OPERAND_LENGTH:0] instAddress,
    output reg [31:0] instruction
);

    reg [7:0] memory [0:255];

    always @(*) begin
        instruction = { memory[instAddress + 3],
                        memory[instAddress + 2],
                        memory[instAddress + 1],
                        memory[instAddress] };
    end

    initial begin
        // =========================
        // MAIN PROGRAM
        // =========================

        // 0x00: addi x2, x0, 511
        memory[3]=8'h1F; memory[2]=8'hF0; memory[1]=8'h01; memory[0]=8'h13;

        // 0x04: addi x6, x0, 512
        memory[7]=8'h20; memory[6]=8'h00; memory[5]=8'h03; memory[4]=8'h13;

        // 0x08: addi x10, x0, 5
        memory[11]=8'h00; memory[10]=8'h50; memory[9]=8'h05; memory[8]=8'h13;

        // 0x0C: jal x1, RUN_COUNTER (+8)
        memory[15]=8'h00; memory[14]=8'h80; memory[13]=8'h00; memory[12]=8'hEF;

        // 0x10: HALT
        memory[19]=8'h00; memory[18]=8'h00; memory[17]=8'h00; memory[16]=8'h63;

        // =========================
        // RUN_COUNTER FUNCTION
        // =========================

        // 0x14: addi x2, x2, -8
        memory[23]=8'hFF; memory[22]=8'h81; memory[21]=8'h01; memory[20]=8'h13;

        // 0x18: sw x1, 4(x2)
        memory[27]=8'h00; memory[26]=8'h11; memory[25]=8'h22; memory[24]=8'h23;

        // 0x1C: sw x12, 0(x2)
        memory[31]=8'h00; memory[30]=8'hC1; memory[29]=8'h20; memory[28]=8'h23;

        // 0x20: add x12, x10, x0
        memory[35]=8'h00; memory[34]=8'h05; memory[33]=8'h06; memory[32]=8'h33;

        // 0x24: sw x12, 0(x6)
        memory[39]=8'h00; memory[38]=8'hC3; memory[37]=8'h20; memory[36]=8'h23;

        // 0x28: beq x12, x0, EXIT (+12)
        memory[43]=8'h00; memory[42]=8'h06; memory[41]=8'h06; memory[40]=8'h63;

        // 0x2C: addi x12, x12, -1
        memory[47]=8'hFF; memory[46]=8'hF6; memory[45]=8'h06; memory[44]=8'h13;

        // 0x30: beq x0, x0, DECREMENT (-12)
        memory[51]=8'hFE; memory[50]=8'h00; memory[49]=8'h0A; memory[48]=8'hE3;

        // =========================
        // EXIT
        // =========================

        // 0x34: lw x12, 0(x2)
        memory[55]=8'h00; memory[54]=8'h01; memory[53]=8'h26; memory[52]=8'h03;

        // 0x38: lw x1, 4(x2)
        memory[59]=8'h00; memory[58]=8'h41; memory[57]=8'h20; memory[56]=8'h83;

        // 0x3C: addi x2, x2, 8
        memory[63]=8'h00; memory[62]=8'h81; memory[61]=8'h01; memory[60]=8'h13;

        // 0x40: jalr x0, x1, 0
        memory[67]=8'h00; memory[66]=8'h00; memory[65]=8'h80; memory[64]=8'h67;

    end

endmodule