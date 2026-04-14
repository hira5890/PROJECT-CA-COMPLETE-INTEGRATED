`timescale 1ns / 1ps
// =============================================================================
// tb_TopLevelProcessor_lui
//
// Tests the LUI processor:
//   Program: LUI x10,5 / ADDI x10,x10,10 / ADDI x5,x0,512 / SW x10,0(x5) / JAL halt
//   Expected PC sequence: 0x00 -> 0x04 -> 0x08 -> 0x0C -> 0x10 (halts)
//
//   LUI at 0x00:  RegWrite=1, ALUSrc=1, ALUOp=00, MemWrite=0, Branch=0
//   LED expected: 16'b1_0_1_1_0_0_0_0_0_0_0010_00 = 0x9008
//     [15]=1 sentinel, [13]=RegWrite=1, [12]=ALUSrc=1, [3]=ALUCtrl[1]=1 (ADD)
// =============================================================================
module tb_TopLevelProcessor_lui;

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
    TopLevelProcessor_lui dut (
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
    wire [31:0] PC          = dut.PC;
    wire [31:0] instruction = dut.instruction;
    wire        RegWrite    = dut.RegWrite;
    wire        MemWrite    = dut.MemWrite;
    wire        MemRead     = dut.MemRead;
    wire        ALUSrc      = dut.ALUSrc;
    wire        Branch      = dut.Branch;
    wire        Jump        = dut.Jump;
    wire [1:0]  ALUOp       = dut.ALUOp;
    wire [3:0]  ALUCtrl     = dut.ALUCtrl;
    wire        MemtoReg    = dut.MemtoReg;
    wire        is_lui      = dut.is_lui;
    wire        is_jal      = dut.is_jal;

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_lui.vcd");
        $dumpvars(0, tb_TopLevelProcessor_lui);

        switch_in = 6'b0;
        reset = 1;
        tick(3);
        reset = 0;
        #1;

        $display("\n=== LUI Testbench ===\n");

        // =====================================================================
        // Phase 1: Reset
        // =====================================================================
        $display("--- Phase 1: Reset ---");
        check_val("PC after reset", PC, 32'h00000000);

        // =====================================================================
        // Phase 2: LUI at PC=0x00
        // LUI x10, 5  -> x10 = 0x00005000
        // Expected control: RegWrite=1, ALUSrc=1, MemWrite=0, Branch=0,
        //                   Jump=0, MemRead=0, MemtoReg=0, ALUOp=00
        // =====================================================================
        $display("--- Phase 2: LUI instruction at PC=0x00 ---");
        check_val("PC=0x00",            PC,       32'h00000000);
        check    ("LUI is_lui",         is_lui,   1'b1);
        check    ("LUI RegWrite",       RegWrite, 1'b1);
        check    ("LUI ALUSrc",         ALUSrc,   1'b1);  // immediate path
        check    ("LUI MemWrite",       MemWrite, 1'b0);
        check    ("LUI MemRead",        MemRead,  1'b0);
        check    ("LUI Branch",         Branch,   1'b0);
        check    ("LUI Jump",           Jump,     1'b0);
        check    ("LUI MemtoReg",       MemtoReg, 1'b0);
        check    ("LUI ALUOp[1]",       ALUOp[1], 1'b0);
        check    ("LUI ALUOp[0]",       ALUOp[0], 1'b0);
        // ALUCtrl for LUI should be 0010 (ADD — passes immediate through)
        check    ("LUI ALUCtrl[3]",     ALUCtrl[3], 1'b0);
        check    ("LUI ALUCtrl[2]",     ALUCtrl[2], 1'b0);
        check    ("LUI ALUCtrl[1]",     ALUCtrl[1], 1'b1);
        check    ("LUI ALUCtrl[0]",     ALUCtrl[0], 1'b0);
        tick(1);

        // =====================================================================
        // Phase 3: ADDI x10, x10, 10 at PC=0x04
        // =====================================================================
        $display("--- Phase 3: ADDI x10,x10,10 at PC=0x04 ---");
        check_val("PC=0x04",            PC,       32'h00000004);
        check    ("ADDI RegWrite",      RegWrite, 1'b1);
        check    ("ADDI ALUSrc",        ALUSrc,   1'b1);
        check    ("ADDI MemWrite",      MemWrite, 1'b0);
        check    ("ADDI Branch",        Branch,   1'b0);
        tick(1);

        // =====================================================================
        // Phase 4: ADDI x5, x0, 512 at PC=0x08
        // =====================================================================
        $display("--- Phase 4: ADDI x5,x0,512 at PC=0x08 ---");
        check_val("PC=0x08",            PC,       32'h00000008);
        check    ("ADDI2 RegWrite",     RegWrite, 1'b1);
        check    ("ADDI2 MemWrite",     MemWrite, 1'b0);
        tick(1);

        // =====================================================================
        // Phase 5: SW x10, 0(x5) at PC=0x0C
        // MemWrite=1, RegWrite=0, ALUSrc=1
        // =====================================================================
        $display("--- Phase 5: SW at PC=0x0C ---");
        check_val("PC=0x0C",            PC,       32'h0000000C);
        check    ("SW MemWrite",        MemWrite, 1'b1);
        check    ("SW RegWrite",        RegWrite, 1'b0);
        check    ("SW ALUSrc",          ALUSrc,   1'b1);
        check    ("SW Branch",          Branch,   1'b0);
        check    ("SW MemRead",         MemRead,  1'b0);
        tick(1);

        // =====================================================================
        // Phase 6: JAL x0,0 (self-loop HALT) at PC=0x10
        // =====================================================================
        $display("--- Phase 6: JAL halt at PC=0x10 ---");
        check_val("PC=0x10",            PC,       32'h00000010);
        check    ("HALT is_jal",        is_jal,   1'b1);
        check    ("HALT Jump",          Jump,     1'b1);
        check    ("HALT MemWrite",      MemWrite, 1'b0);
        check    ("HALT Branch",        Branch,   1'b0);
        tick(1);

        // Stays halted
        check_val("PC halted +1cy",     PC,       32'h00000010);
        tick(1);
        check_val("PC halted +2cy",     PC,       32'h00000010);

        // =====================================================================
        // Phase 7: LED register check
        // After LUI executed, led_out[15] sentinel must be 1
        // [15]=1 [13]=RegWrite=1 [12]=ALUSrc=1 [3]=ALUCtrl[1]=1
        // Expected = 0x9008
        // =====================================================================
        $display("--- Phase 7: LED register ---");
        check    ("LED sentinel [15]",  led_out[15], 1'b1);
        check    ("LED Jump    [14]",   led_out[14], 1'b0); // LUI has no jump
        check    ("LED RegWrite[13]",   led_out[13], 1'b1);
        check    ("LED ALUSrc  [12]",   led_out[12], 1'b1);
        check    ("LED ALUOp1  [11]",   led_out[11], 1'b0);
        check    ("LED ALUOp0  [10]",   led_out[10], 1'b0);
        check    ("LED MemtoReg [9]",   led_out[9],  1'b0);
        check    ("LED MemRead  [8]",   led_out[8],  1'b0);
        check    ("LED MemWrite [7]",   led_out[7],  1'b0);
        check    ("LED Branch   [6]",   led_out[6],  1'b0);
        // ALUCtrl = 0010 in bits [5:2]
        check    ("LED ALUCtrl3 [5]",   led_out[5],  1'b0);
        check    ("LED ALUCtrl2 [4]",   led_out[4],  1'b0);
        check    ("LED ALUCtrl1 [3]",   led_out[3],  1'b1);
        check    ("LED ALUCtrl0 [2]",   led_out[2],  1'b0);
        // LUI at PC=0x00 -> PC[3:2]=2'b00
        check    ("LED PC[3:2]  [1:0]", led_out[1:0], 2'b00);

        // Full word check
        check_val("LED full word",      {16'b0, led_out}, 32'h00009008);

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

    // Timeout guard
    initial begin
        #(100 * 10);
        $display("TIMEOUT");
        $finish;
    end

endmodule
