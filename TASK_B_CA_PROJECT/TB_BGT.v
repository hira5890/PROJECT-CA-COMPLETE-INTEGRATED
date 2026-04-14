`timescale 1ns / 1ps
// =============================================================================
// tb_TopLevelProcessor_bgt
//
// Tests the BGT processor (BGT encoded as BLT with swapped operands).
//
// Program:
//   0x00: ADDI x10, x0, 0      x10 = 0
//   0x04: ADDI x11, x0, 3      x11 = 3
//   0x08: ADDI x5,  x0, 512    x5  = 0x200
//   0x0C: ADDI x10, x10, 1     x10++ (LOOP TOP)
//   0x10: BLT  x10, x11, -4    BGT: if x10 < x11, PC = 0x0C
//   0x14: SW   x10, 0(x5)      mem[0x200] = 3
//   0x18: JAL  x0,  0          HALT
//
// Expected PC sequence:
//   0x00->0x04->0x08->0x0C->0x10->(branch)->0x0C->0x10->(branch)->
//   0x0C->0x10->(no branch)->0x14->0x18 (halts)
//
// BGT (BLT funct3=100) control: Branch=1, ALUOp=01, RegWrite=0,
//   ALUSrc=0, Jump=0, MemRead=0, MemWrite=0, MemtoReg=0
// Branch taken when ALUResult[31]=1 (rs1 signed < rs2)
// =============================================================================
module tb_TopLevelProcessor_bgt;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg         clk;
    reg         clk_fast;
    reg         reset;
    reg  [5:0]  switch_in;
    wire [15:0] led_out;
    wire        led_write_en;
    wire [6:0]  seg;
    wire [3:0]  an;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    TopLevelProcessor_bgt dut (
        .clk         (clk),
        .clk_fast    (clk_fast),
        .reset       (reset),
        .switch_in   (switch_in),
        .led_out     (led_out),
        .led_write_en(led_write_en),
        .seg         (seg),
        .an          (an)
    );

    // -------------------------------------------------------------------------
    // Clocks
    // -------------------------------------------------------------------------
    initial clk      = 0;
    initial clk_fast = 0;
    always #5  clk      = ~clk;
    always #2  clk_fast = ~clk_fast;

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------
    task tick;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
            #1;
        end
    endtask

    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input [255:0] name;
        input         got;
        input         expected;
        begin
            if (got === expected) begin
                $display("  PASS  %0s", name);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %0s  got=%0b expected=%0b", name, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_val;
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  expected;
        begin
            if (got === expected) begin
                $display("  PASS  %0s  (0x%08X)", name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %0s  got=0x%08X expected=0x%08X", name, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Internal signal aliases
    // -------------------------------------------------------------------------
    wire [31:0] PC           = dut.PC;
    wire [31:0] instruction  = dut.instruction;
    wire        RegWrite     = dut.RegWrite;
    wire        MemWrite     = dut.MemWrite;
    wire        MemRead      = dut.MemRead;
    wire        ALUSrc       = dut.ALUSrc;
    wire        Branch       = dut.Branch;
    wire        Jump         = dut.Jump;
    wire [1:0]  ALUOp        = dut.ALUOp;
    wire [3:0]  ALUCtrl      = dut.ALUCtrl;
    wire        MemtoReg     = dut.MemtoReg;
    wire        is_bgt       = dut.is_bgt;
    wire        is_jal       = dut.is_jal;
    wire        BranchTaken  = dut.BranchTaken;
    wire [31:0] ALUResult    = dut.ALUResult;

    // Loop iteration counter for tracking BGT passes
    integer bgt_pass_idx;

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_bgt.vcd");
        $dumpvars(0, tb_TopLevelProcessor_bgt);

        switch_in = 6'b0;
        reset = 1;
        tick(3);
        reset = 0;
        #1;

        $display("\n=== BGT Testbench ===\n");

        // =====================================================================
        // Phase 1: Reset
        // =====================================================================
        $display("--- Phase 1: Reset ---");
        check_val("PC after reset", PC, 32'h00000000);

        // =====================================================================
        // Phase 2: Prologue instructions (3 x ADDI)
        // =====================================================================
        $display("--- Phase 2: Prologue ADDIs (PC 0x00..0x08) ---");

        check_val("PC=0x00 ADDI",    PC, 32'h00000000);
        check    ("ADDI RegWrite",   RegWrite, 1'b1);
        check    ("ADDI MemWrite",   MemWrite, 1'b0);
        check    ("ADDI ALUSrc",     ALUSrc,   1'b1);
        check    ("ADDI Branch",     Branch,   1'b0);
        tick(1);

        check_val("PC=0x04 ADDI",    PC, 32'h00000004);
        check    ("ADDI2 RegWrite",  RegWrite, 1'b1);
        tick(1);

        check_val("PC=0x08 ADDI",    PC, 32'h00000008);
        check    ("ADDI3 RegWrite",  RegWrite, 1'b1);
        tick(1);

        // =====================================================================
        // Phase 3: Loop iterations
        // Each iteration: 0x0C (ADDI x10++) -> 0x10 (BGT/BLT)
        // Iterations 1 & 2: branch taken back to 0x0C
        // Iteration 3: branch NOT taken, falls through to 0x14
        // =====================================================================
        $display("--- Phase 3: Loop (3 iterations) ---");

        // --- Iteration 1 (x10 becomes 1, 1 < 3 -> branch taken) ---
        $display("  Iteration 1:");
        check_val("  PC=0x0C",           PC, 32'h0000000C);
        check    ("  ADDI loop RegWrite",RegWrite, 1'b1);
        tick(1);

        check_val("  PC=0x10 BGT iter1", PC, 32'h00000010);
        check    ("  BGT is_bgt",        is_bgt,   1'b1);
        check    ("  BGT Branch",        Branch,   1'b1);
        check    ("  BGT RegWrite",      RegWrite, 1'b0);
        check    ("  BGT MemWrite",      MemWrite, 1'b0);
        check    ("  BGT ALUSrc",        ALUSrc,   1'b0); // reg-reg compare
        check    ("  BGT Jump",          Jump,     1'b0);
        check    ("  BGT MemRead",       MemRead,  1'b0);
        check    ("  BGT MemtoReg",      MemtoReg, 1'b0);
        check    ("  BGT ALUOp[0]",      ALUOp[0], 1'b1); // ALUOp=01
        check    ("  BGT ALUOp[1]",      ALUOp[1], 1'b0);
        // ALUCtrl should be SUB (0110) for branch comparison
        check    ("  BGT ALUCtrl[3]",    ALUCtrl[3], 1'b0);
        check    ("  BGT ALUCtrl[2]",    ALUCtrl[2], 1'b1);
        check    ("  BGT ALUCtrl[1]",    ALUCtrl[1], 1'b1);
        check    ("  BGT ALUCtrl[0]",    ALUCtrl[0], 1'b0);
        // x10=1 < x11=3, so ALUResult[31] should be 1 (signed: 1-3 = negative)
        check    ("  BGT BranchTaken",   BranchTaken, 1'b1);
        tick(1);

        // After branch: PC should go back to 0x0C
        check_val("  PC after branch1",  PC, 32'h0000000C);

        // --- Iteration 2 (x10 becomes 2, 2 < 3 -> branch taken) ---
        $display("  Iteration 2:");
        check_val("  PC=0x0C iter2",     PC, 32'h0000000C);
        tick(1);

        check_val("  PC=0x10 iter2",     PC, 32'h00000010);
        check    ("  BGT2 is_bgt",       is_bgt,      1'b1);
        check    ("  BGT2 Branch",       Branch,      1'b1);
        check    ("  BGT2 BranchTaken",  BranchTaken, 1'b1);
        tick(1);

        check_val("  PC after branch2",  PC, 32'h0000000C);

        // --- Iteration 3 (x10 becomes 3, 3 NOT < 3 -> fall through) ---
        $display("  Iteration 3:");
        check_val("  PC=0x0C iter3",     PC, 32'h0000000C);
        tick(1);

        check_val("  PC=0x10 iter3",     PC, 32'h00000010);
        check    ("  BGT3 is_bgt",       is_bgt,      1'b1);
        check    ("  BGT3 Branch",       Branch,      1'b1);
        // x10=3, x11=3: 3-3=0, not negative -> BranchTaken should be 0
        check    ("  BGT3 BranchTaken",  BranchTaken, 1'b0);
        tick(1);

        // Fall through to 0x14 (SW)
        check_val("  PC after no-branch",PC, 32'h00000014);

        // =====================================================================
        // Phase 4: SW and HALT
        // =====================================================================
        $display("--- Phase 4: SW and HALT ---");

        check_val("PC=0x14 SW",          PC, 32'h00000014);
        check    ("SW MemWrite",         MemWrite, 1'b1);
        check    ("SW RegWrite",         RegWrite, 1'b0);
        check    ("SW Branch",           Branch,   1'b0);
        tick(1);

        check_val("PC=0x18 JAL halt",    PC, 32'h00000018);
        check    ("HALT is_jal",         is_jal,   1'b1);
        check    ("HALT Jump",           Jump,     1'b1);
        tick(1);

        check_val("PC halted +1cy",      PC, 32'h00000018);
        tick(1);
        check_val("PC halted +2cy",      PC, 32'h00000018);

        // =====================================================================
        // Phase 5: LED register check
        // Sentinel [15]=1, Branch [6]=1, ALUOp[0] [10]=1, ALUCtrl=0110 [5:2]
        // PC[3:2] at BGT (PC=0x10) = 2'b00
        // Expected: 16'b1_0_0_0_0_1_0_0_0_1_0110_00 = 0x8458
        // =====================================================================
        $display("--- Phase 5: LED register ---");
        check    ("LED sentinel [15]",   led_out[15], 1'b1);
        check    ("LED Jump     [14]",   led_out[14], 1'b0);
        check    ("LED RegWrite [13]",   led_out[13], 1'b0);
        check    ("LED ALUSrc   [12]",   led_out[12], 1'b0);
        check    ("LED ALUOp[1] [11]",   led_out[11], 1'b0);
        check    ("LED ALUOp[0] [10]",   led_out[10], 1'b1);
        check    ("LED MemtoReg [9]",    led_out[9],  1'b0);
        check    ("LED MemRead  [8]",    led_out[8],  1'b0);
        check    ("LED MemWrite [7]",    led_out[7],  1'b0);
        check    ("LED Branch   [6]",    led_out[6],  1'b1);
        // ALUCtrl = 0110 (SUB) in bits [5:2]
        check    ("LED ALUCtrl3 [5]",    led_out[5],  1'b0);
        check    ("LED ALUCtrl2 [4]",    led_out[4],  1'b1);
        check    ("LED ALUCtrl1 [3]",    led_out[3],  1'b1);
        check    ("LED ALUCtrl0 [2]",    led_out[2],  1'b0);
        // PC[3:2] at BGT PC=0x10 -> bits[3:2] of 0x10 = 2'b00
        check    ("LED PC[3:2]  [1:0]",  led_out[1:0], 2'b00);

        // Full word
        check_val("LED full word",       {16'b0, led_out}, 32'h00008458);

        // =====================================================================
        // Summary
        // =====================================================================
        $display("\n=== Results: %0d passed, %0d failed ===\n",
                 pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

    // Timeout guard: 300 slow cycles (loop + prologue + epilogue)
    initial begin
        #(300 * 10);
        $display("TIMEOUT");
        $finish;
    end

endmodule
