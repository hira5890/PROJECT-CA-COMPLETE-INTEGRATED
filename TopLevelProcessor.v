`timescale 1ns / 1ps
module TopLevelProcessor (
    input  wire        clk,
    input  wire        reset,
    input  wire [5:0]  switch_in,
    output wire [5:0]  led_out,
    output wire        led_write_en,
    output wire [6:0]  seg,
    output wire [3:0]  an
);

    wire [31:0] PC, PC_Plus4, PC_Next, instruction;

    wire [6:0] opcode  = instruction[6:0];
    wire [4:0] rd      = instruction[11:7];
    wire [2:0] funct3  = instruction[14:12];
    wire [4:0] rs1     = instruction[19:15];
    wire [4:0] rs2     = instruction[24:20];
    wire [6:0] funct7  = instruction[31:25];

    wire        RegWrite, MemRead, MemWrite, ALUSrc, MemtoReg, Branch;
    wire [1:0]  ALUOp;
    wire [31:0] ReadData1, ReadData2, WriteBackData;
    wire [31:0] Imm;
    wire [31:0] ALU_SrcB;
    wire [3:0]  ALUCtrl;
    wire [31:0] ALUResult;
    wire        Zero;
    wire [31:0] Branch_Target;
    wire        DataMemWrite_en, DataMemRead_en, LEDWrite_en, SwitchReadEnable;
    wire [31:0] MemReadData, MemOrSwitchData;

    // Jump / branch decode
    wire is_jal  = (opcode == 7'b1101111);
    wire is_jalr = (opcode == 7'b1100111);
    wire is_beq  = (funct3 == 3'b000);
    wire is_bne  = (funct3 == 3'b001);
    wire BranchTaken = Branch & ((is_beq & Zero) | (is_bne & ~Zero));

    // =========================================================================
    // PC next:
    //   JALR  -> ALUResult (rs1 + imm), bit[0] cleared
    //   JAL   -> Branch_Target (PC + J-imm)
    //   Branch taken -> Branch_Target (PC + B-imm)
    //   Sequential -> PC + 4
    // =========================================================================
wire [31:0] jal_target  = PC + Imm;
wire [31:0] jalr_target = (ReadData1 + Imm) & 32'hFFFFFFFE;

assign PC_Next =
    is_jal  ? jal_target  :
    is_jalr ? jalr_target :
    BranchTaken ? Branch_Target :
    PC_Plus4;

    // Write-back: JAL/JALR write PC+4 (return address) into rd
    assign WriteBackData = (is_jal | is_jalr) ? PC_Plus4        :
                            MemtoReg           ? MemOrSwitchData : ALUResult;

    // =========================================================================
    // Instantiations
    // =========================================================================
    ProgramCounter u_PC (
        .clk(clk), .reset(reset), .PC_Next(PC_Next), .PC(PC)
    );
    pcAdder u_pcAdder (
        .PC(PC), .PC_Plus4(PC_Plus4)
    );
    instruction_task_b_fib u_iMem (
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
        .Branch(Branch)
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

    // LED register
    reg [5:0] led_reg;
    always @(posedge clk) begin
        if (reset)            led_reg <= 6'b0;
        else if (LEDWrite_en) led_reg <= ReadData2[5:0];
    end
    assign led_out      = led_reg;
    assign led_write_en = LEDWrite_en;

    // Seven segment
    wire [15:0] countdown_val = {10'b0, led_reg};
    sevenseg_basys3 u7seg (
        .sys_clk(clk), .sys_rst(reset),
        .val_in(countdown_val),
        .seg(seg), .an(an)
    );

endmodule