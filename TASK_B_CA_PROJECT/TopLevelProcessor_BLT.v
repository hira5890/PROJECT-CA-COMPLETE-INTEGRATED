`timescale 1ns / 1ps
// =============================================================================
// TopLevelProcessor_blt
//
// LED MAP (16-bit, latched when BLT instruction is executing at 0x10):
//
//   [15]    = 1 always (sentinel: "a BLT was captured")
//   [14]    = Jump        (expected 0 - BLT is not a jump)
//   [13]    = RegWrite    (expected 0 - BLT does not write a register)
//   [12]    = ALUSrc      (expected 0 - BLT compares two registers, not imm)
//   [11]    = ALUOp[1]    (expected 0)
//   [10]    = ALUOp[0]    (expected 1  -> ALUOp = 2'b01 for all branches)
//   [9]     = MemtoReg    (expected 0)
//   [8]     = MemRead     (expected 0)
//   [7]     = MemWrite    (expected 0)
//   [6]     = Branch      (expected 1)
//   [5:2]   = ALUCtrl     (expected 4'b0110 = SUB)
//   [1:0]   = BranchTaken history: bit1=2nd iteration, bit0=1st iteration
//             (both should be 1 since branch is taken on x10=1 and x10=2)
//
// Expected LED = 16'b1_0_0_0_0_1_0_0_0_1_0110_11 = 0x8453
//   [15]=1 [14]=0 [13]=0 [12]=0 [11]=0 [10]=1
//   [9]=0  [8]=0  [7]=0  [6]=1  [5:2]=0110  [1:0]=11
//
// SEVEN SEGMENT: shows live PC value (4 hex digits)
//   You will see: 0000 0004 0008 000C 0010 000C 0010 000C 0010 0014 0018
// =============================================================================
module TopLevelProcessor_blt (
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

    // Instruction type decode
    wire is_jal  = (opcode == 7'b1101111);
    wire is_jalr = (opcode == 7'b1100111);
    wire is_blt  = (opcode == 7'b1100011) && (funct3 == 3'b100);
    wire is_beq  = (funct3 == 3'b000);
    wire is_bne  = (funct3 == 3'b001);

    // BLT branch taken: ALU computes rs1-rs2 (SUB).
    // Result is negative (bit 31 = 1) when rs1 < rs2 signed,
    // AND result is not zero (not equal).
    wire blt_taken   = is_blt & ALUResult[31] & ~Zero;
    wire BranchTaken = Branch & (
        (is_beq & Zero)   |
        (is_bne & ~Zero)  |
        blt_taken
    );

    // PC next logic
wire [31:0] jalr_sum;
assign jalr_sum = ReadData1 + Imm;

wire [31:0] jalr_target = {jalr_sum[31:1], 1'b0};    assign PC_Next =
        is_jal      ? (PC + Imm)      :
        is_jalr     ? jalr_target     :
        BranchTaken ? Branch_Target   :
                      PC_Plus4;

    // Write-back source
    assign WriteBackData =
        (is_jal | is_jalr) ? PC_Plus4        :
        MemtoReg           ? MemOrSwitchData : ALUResult;

    // =========================================================================
    // Module instantiations
    // =========================================================================
    ProgramCounter u_PC (
        .clk(clk), .reset(reset), .PC_Next(PC_Next), .PC(PC)
    );
    pcAdder u_pcAdder (
        .PC(PC), .PC_Plus4(PC_Plus4)
    );
    instruction_mem_blt u_iMem (
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
    assign led_write_en    = LEDWrite_en;

    // =========================================================================
    // LED register - two purposes, switched by whether BLT is active:
    //
    // WHILE BLT IS EXECUTING (PC=0x10):
    //   Shows control unit signals so you can verify BLT is decoded correctly.
    //   Latches on every clock edge where is_blt is high.
    //   Also accumulates BranchTaken history in [1:0].
    //
    // AFTER SW EXECUTES (PC=0x14, LEDWrite_en high):
    //   The SW instruction writes x10=3 to address 0x200.
    //   AddressDecoder asserts LEDWrite_en.
    //   This overwrites the control signal display with the final count value.
    //   So LEDs end up showing 0x0003 when the program halts.
    //   This gives you two observable outputs:
    //     - During loop: control signals (verify BLT decoding)
    //     - After loop: final counter value (verify correct loop count)
    // =========================================================================
    reg [15:0] led_reg;
    reg [1:0]  branch_history; // tracks taken status across iterations

    always @(posedge clk) begin
        if (reset) begin
            led_reg        <= 16'h0000;
            branch_history <= 2'b00;
        end
        else if (is_blt) begin
            // Shift in this iteration's taken result
            branch_history <= {branch_history[0], blt_taken};

            // Latch control signals
            led_reg[15]  <= 1'b1;           // sentinel
            led_reg[14]  <= Jump;           // expect 0
            led_reg[13]  <= RegWrite;       // expect 0
            led_reg[12]  <= ALUSrc;         // expect 0
            led_reg[11]  <= ALUOp[1];       // expect 0
            led_reg[10]  <= ALUOp[0];       // expect 1
            led_reg[9]   <= MemtoReg;       // expect 0
            led_reg[8]   <= MemRead;        // expect 0
            led_reg[7]   <= MemWrite;       // expect 0
            led_reg[6]   <= Branch;         // expect 1
            led_reg[5:2] <= ALUCtrl;        // expect 0110 (SUB)
            led_reg[1:0] <= {branch_history[0], blt_taken}; // taken history
        end
        else if (LEDWrite_en) begin
            // SW writes final value - overwrite with counter result
            // After halt you'll see 0x0003 on LEDs
            led_reg <= {10'b0, ReadData2[5:0]};
        end
    end

    assign led_out = led_reg;

    // =========================================================================
    // Seven segment - shows PC as 4 hex digits
    // You will observe the PC sequence:
    //   0000 -> 0004 -> 0008 -> 000C -> 0010 -> 000C (taken) ->
    //   0010 -> 000C (taken) -> 0010 -> 0014 -> 0018 (halt)
    // =========================================================================
    sevenseg_basys3_4digit u_7seg (
        .sys_clk (clk_fast),
        .sys_rst (reset),
        .val_in  (PC[15:0]),
        .seg     (seg),
        .an      (an)
    );

endmodule
