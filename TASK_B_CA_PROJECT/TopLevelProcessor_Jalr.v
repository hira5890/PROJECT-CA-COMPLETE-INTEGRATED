`timescale 1ns / 1ps
// =============================================================================
// TopLevelProcessor_jalr  (updated - separate fast clock for 7-seg)
//
// CHANGE: added clk_fast input.
//   clk      = slow CPU clock (~2 Hz from ClockDividerSlow)
//   clk_fast = fast 7-seg clock (100 MHz from board)
//
// Everything in the CPU datapath (PC, registers, memory, ALU, control)
// is clocked by clk (slow).
// Only the sevenseg_basys3_4digit instance uses clk_fast so its TDM
// multiplexer runs fast enough for a flicker-free display.
//
// PC is a registered output - stable between slow clock edges - so reading
// it on the fast clock domain is safe (no metastability risk for display).
// =============================================================================
module TopLevelProcessor_jalr (
    input  wire        clk,         // slow CPU clock (~2 Hz)
    input  wire        clk_fast,    // fast 7-seg clock (100 MHz)
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

    // All datapath modules use slow clk
    ProgramCounter u_PC (
        .clk(clk), .reset(reset), .PC_Next(PC_Next), .PC(PC)
    );
    pcAdder u_pcAdder (
        .PC(PC), .PC_Plus4(PC_Plus4)
    );
    instruction_mem_jalr u_iMem (
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

    // JALR control-signal snapshot - clocked by slow CPU clock
    reg [15:0] jalr_led_reg;
    always @(posedge clk) begin
        if (reset) begin
            jalr_led_reg <= 16'h0000;
        end else if (is_jalr) begin
            jalr_led_reg[15]  <= 1'b1;
            jalr_led_reg[14]  <= Jump;
            jalr_led_reg[13]  <= RegWrite;
            jalr_led_reg[12]  <= ALUSrc;
            jalr_led_reg[11]  <= ALUOp[1];
            jalr_led_reg[10]  <= ALUOp[0];
            jalr_led_reg[9]   <= MemtoReg;
            jalr_led_reg[8]   <= MemRead;
            jalr_led_reg[7]   <= MemWrite;
            jalr_led_reg[6]   <= Branch;
            jalr_led_reg[5:2] <= ALUCtrl[3:0];
            jalr_led_reg[1:0] <= PC[3:2];
        end
    end
    assign led_out = jalr_led_reg;

    // 7-seg runs on clk_fast (100 MHz) so TDM is flicker-free
    // PC is stable between slow clock edges - safe to read on fast domain
    sevenseg_basys3_4digit u_7seg (
        .sys_clk (clk_fast),    // <-- fast clock for TDM
        .sys_rst (reset),
        .val_in  (PC[15:0]),
        .seg     (seg),
        .an      (an)
    );

endmodule
