`timescale 1ns / 1ps
// =============================================================================
// TopLevelProcessor_lui
//
// Identical structure to TopLevelProcessor_jalr.
// Swaps in instruction_mem_lui and latches LEDs when LUI is the active
// instruction (opcode == 7'b0110111).
//
// LED MAP (latched, holds after LUI executes):
//   [15] = 1  "a LUI was executed" sentinel
//   [14] = Jump        (expected 0)
//   [13] = RegWrite    (expected 1  - LUI writes rd)
//   [12] = ALUSrc      (expected 1  - immediate operand)
//   [11] = ALUOp[1]    (expected 0)
//   [10] = ALUOp[0]    (expected 0)
//   [9]  = MemtoReg    (expected 0)
//   [8]  = MemRead     (expected 0)
//   [7]  = MemWrite    (expected 0)
//   [6]  = Branch      (expected 0)
//   [5:2]= ALUCtrl     (expected 0010 = ADD)
//   [1:0]= PC[3:2] at capture (LUI at 0x00 -> 2'b00)
//
// Expected LED value = 16'b1001_0000_0000_1000 = 0x9008
//   bit15=1(sentinel) bit13=1(RegWrite) bit12=1(ALUSrc) bit3=1(ALUCtrl bit1=ADD)
//
// SEVEN-SEG: shows live PC.
//   Steps: 0000 -> 0004 -> 0008 -> 000C -> 0010 (halts)
//   LUI fires at 0000.
// =============================================================================
module TopLevelProcessor_lui (
    input  wire        clk,
    input  wire        clk_fast,
    input  wire        reset,
    input  wire [5:0]  switch_in,
    output wire [15:0] led_out,
    output wire        led_write_en,
    output wire [6:0]  seg,
    output wire [3:0]  an
);
    wire [31:0] PC, PC_Plus4, PC_Next, instruction;

    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd     = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1    = instruction[19:15];
    wire [4:0] rs2    = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25];

    wire        RegWrite, MemRead, MemWrite, ALUSrc, MemtoReg, Branch, Jump;
    wire [1:0]  ALUOp;
    wire [3:0]  ALUCtrl;
    wire [31:0] ReadData1, ReadData2, WriteBackData, Imm, ALU_SrcB, ALUResult;
    wire        Zero;
    wire [31:0] Branch_Target;
    wire        DataMemWrite_en, DataMemRead_en, LEDWrite_en, SwitchReadEnable;
    wire [31:0] MemReadData, MemOrSwitchData;

    wire is_jal  = (opcode == 7'b1101111);
    wire is_jalr = (opcode == 7'b1100111);
    wire is_lui  = (opcode == 7'b0110111);
    wire is_beq  = (funct3 == 3'b000);
    wire is_bne  = (funct3 == 3'b001);
    wire BranchTaken = Branch & ((is_beq & Zero) | (is_bne & ~Zero));

    wire [31:0] jal_target  = PC + Imm;
    wire [31:0] jalr_target = (ReadData1 + Imm) & 32'hFFFFFFFE;

    assign PC_Next =
        is_jal      ? jal_target   :
        is_jalr     ? jalr_target  :
        BranchTaken ? Branch_Target:
                      PC_Plus4;

    assign WriteBackData =
        (is_jal | is_jalr) ? PC_Plus4        :
        MemtoReg           ? MemOrSwitchData : ALUResult;

    ProgramCounter u_PC (
        .clk(clk), .reset(reset), .PC_Next(PC_Next), .PC(PC)
    );
    pcAdder u_pcAdder (
        .PC(PC), .PC_Plus4(PC_Plus4)
    );
    instruction_mem_lui u_iMem (
        .instAddress(PC), .instruction(instruction)
    );
    immGen u_immGen (
        .inst(instruction), .imm_out(Imm)
    );
    MainControl u_MainCtrl (
        .opcode(opcode),
        .RegWrite(RegWrite), .ALUOp(ALUOp),
        .MemRead(MemRead),   .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),     .MemtoReg(MemtoReg),
        .Branch(Branch),     .Jump(Jump)
    );
    register_file u_regFile (
        .clk(clk), .rst(reset),
        .WriteEnable(RegWrite),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .WriteData(WriteBackData),
        .ReadData1(ReadData1), .ReadData2(ReadData2)
    );
    mux2 u_aluSrcMux (
        .A(ReadData2), .B(Imm), .sel(ALUSrc), .Y(ALU_SrcB)
    );
    ALUControl u_ALUCtrl (
        .opcode(opcode), .ALUOp(ALUOp),
        .funct3(funct3), .funct7(funct7),
        .ALUControl(ALUCtrl)
    );
    RISCVALU u_ALU (
        .ALUctl(ALUCtrl), .A(ReadData1), .B(ALU_SrcB),
        .ALUout(ALUResult), .Zero(Zero)
    );
    branchAdder u_branchAdder (
        .PC(PC), .Imm(Imm), .Branch_Target(Branch_Target)
    );
    AddressDecoder u_addrDec (
        .address(ALUResult),
        .readEnable(MemRead), .writeEnable(MemWrite),
        .DataMemWrite(DataMemWrite_en), .DataMemRead(DataMemRead_en),
        .LEDWrite(LEDWrite_en), .SwitchReadEnable(SwitchReadEnable)
    );
    DataMemory u_dataMem (
        .clk(clk),
        .MemWrite(DataMemWrite_en), .MemRead(DataMemRead_en),
        .address(ALUResult), .write_data(ReadData2),
        .read_data(MemReadData)
    );

    assign MemOrSwitchData = SwitchReadEnable ? {26'b0, switch_in} : MemReadData;

    reg [5:0] led_data_reg;
    always @(posedge clk) begin
        if (reset)            led_data_reg <= 6'b0;
        else if (LEDWrite_en) led_data_reg <= ReadData2[5:0];
    end
    assign led_write_en = LEDWrite_en;

    // Latch control signals when LUI is the active instruction
    reg [15:0] lui_led_reg;
    always @(posedge clk) begin
        if (reset) begin
            lui_led_reg <= 16'h0000;
        end else if (is_lui) begin
            lui_led_reg[15]  <= 1'b1;       // sentinel
            lui_led_reg[14]  <= Jump;
            lui_led_reg[13]  <= RegWrite;
            lui_led_reg[12]  <= ALUSrc;
            lui_led_reg[11]  <= ALUOp[1];
            lui_led_reg[10]  <= ALUOp[0];
            lui_led_reg[9]   <= MemtoReg;
            lui_led_reg[8]   <= MemRead;
            lui_led_reg[7]   <= MemWrite;
            lui_led_reg[6]   <= Branch;
            lui_led_reg[5:2] <= ALUCtrl[3:0];
            lui_led_reg[1:0] <= PC[3:2];
        end
    end
    assign led_out = lui_led_reg;

    sevenseg_basys3_4digit u_7seg (
        .sys_clk (clk_fast),
        .sys_rst (reset),
        .val_in  (PC[15:0]),
        .seg     (seg),
        .an      (an)
    );

endmodule
