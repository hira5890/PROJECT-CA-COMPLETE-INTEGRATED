`timescale 1ns / 1ps
// =============================================================================
// TopLevelProcessor_bgt
//
// Identical structure to TopLevelProcessor_jalr.
// Swaps in instruction_mem_bgt and latches LEDs when the BGT (BLT) branch
// instruction is the active instruction (opcode=1100011, funct3=100).
//
// LED MAP (latched, holds after last BGT executes):
//   [15] = 1  "a BGT was executed" sentinel
//   [14] = Jump        (expected 0)
//   [13] = RegWrite    (expected 0  - branch does not write a register)
//   [12] = ALUSrc      (expected 0  - branch compares two registers)
//   [11] = ALUOp[1]    (expected 0)
//   [10] = ALUOp[0]    (expected 1  - ALUOp=01 for branch)
//   [9]  = MemtoReg    (expected 0)
//   [8]  = MemRead     (expected 0)
//   [7]  = MemWrite    (expected 0)
//   [6]  = Branch      (expected 1)
//   [5:2]= ALUCtrl     (expected 0110 = SUB, used to set zero flag)
//   [1:0]= PC[3:2] at last capture (BGT at 0x10 -> PC[3:2]=2'b00)
//
// Expected LED value = 16'b1000_0100_0101_1000 = 0x8458 ... let's compute:
//   [15]=1 [14]=0 [13]=0 [12]=0 [11]=0 [10]=1 [9]=0 [8]=0
//   [7]=0  [6]=1  [5:2]=0110    [1:0]=00
//   = 1000_0100_0101_1000 = 0x8458  -- but check ALUOp mapping carefully:
//   ALUOp=01 for branch means ALUCtrl will be SUB=0110.
//   Note: your ALUControl uses ALUOp=2'b01 -> SUB for all branches.
//   BGT is encoded as BLT (funct3=100) but MainControl still sees
//   opcode=1100011 (branch) and asserts Branch=1, ALUOp=01.
//
// SEVEN-SEG: shows live PC.
//   Steps: 0000 -> 0004 -> 0008
//          000C -> 0010 -> 000C (x10=1, branch taken)
//          000C -> 0010 -> 000C (x10=2, branch taken)
//          000C -> 0010 -> 0014 (x10=3, branch NOT taken)
//          0018 (halts)
//   BGT fires at 0010 on every pass through the loop.
// =============================================================================
module TopLevelProcessor_bgt (
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

    wire is_jal   = (opcode == 7'b1101111);
    wire is_jalr  = (opcode == 7'b1100111);
    // BGT is encoded as BLT: opcode=branch, funct3=100
    wire is_bgt   = (opcode == 7'b1100011) && (funct3 == 3'b100);
    wire is_beq   = (funct3 == 3'b000);
    wire is_bne   = (funct3 == 3'b001);
    wire is_blt   = (funct3 == 3'b100);  // BLT / BGT share funct3=100

    // BranchTaken: extend the existing BEQ/BNE logic with BLT
    // BLT: branch if signed(rs1) < signed(rs2)
    // ALU computes rs1-rs2; for signed less-than we need the sign bit of result
    // However your ALU already handles BLT via ALUOp=01->SUB; the zero flag
    // only covers BEQ.  For BLT we use the ALU SLT output instead.
    // Simplest compatible approach: add BLT using the ALUResult[0] (SLT bit)
    // when ALUOp drives SUB and funct3=100.
    // Actually: to keep compatibility with your existing ALUControl which maps
    // ALUOp=01 -> SUB, we handle BLT branch taken as: ALUResult is negative
    // (signed comparison).  ALUResult[31]=1 means rs1 < rs2 (signed).
    wire branch_blt_taken = is_blt & ALUResult[31];
    wire BranchTaken = Branch & (
        (is_beq & Zero)         |   // BEQ
        (is_bne & ~Zero)        |   // BNE
        branch_blt_taken            // BLT / BGT
    );

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
    instruction_mem_bgt u_iMem (
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

    // Latch control signals when BGT (BLT) is the active instruction
    reg [15:0] bgt_led_reg;
    always @(posedge clk) begin
        if (reset) begin
            bgt_led_reg <= 16'h0000;
        end else if (is_bgt) begin
            bgt_led_reg[15]  <= 1'b1;       // sentinel
            bgt_led_reg[14]  <= Jump;
            bgt_led_reg[13]  <= RegWrite;
            bgt_led_reg[12]  <= ALUSrc;
            bgt_led_reg[11]  <= ALUOp[1];
            bgt_led_reg[10]  <= ALUOp[0];
            bgt_led_reg[9]   <= MemtoReg;
            bgt_led_reg[8]   <= MemRead;
            bgt_led_reg[7]   <= MemWrite;
            bgt_led_reg[6]   <= Branch;
            bgt_led_reg[5:2] <= ALUCtrl[3:0];
            bgt_led_reg[1:0] <= PC[3:2];
        end
    end
    assign led_out = bgt_led_reg;

    sevenseg_basys3_4digit u_7seg (
        .sys_clk (clk_fast),
        .sys_rst (reset),
        .val_in  (PC[15:0]),
        .seg     (seg),
        .an      (an)
    );

endmodule
