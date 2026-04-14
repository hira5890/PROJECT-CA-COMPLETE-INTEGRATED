`timescale 1ns / 1ps
// =============================================================================
// tb_TopLevelProcessor_jalr
//
// Tests the JALR processor:
//   - PC sequence: 0x00 -> 0x04 -> 0x08 -> 0x0C -> 0x10 -> 0x14 -> 0x18 ->
//                  0x1C (JALR call) -> 0x2C -> 0x30 -> 0x34 (JALR return) ->
//                  0x20 -> 0x24 (JAL halt, self-loop)
//   - Checks RegWrite, MemWrite at key PCs
//   - Verifies jalr_led_reg sentinel bit is set after JALR executes
// =============================================================================
module tb_TopLevelProcessor_jalr;

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
    TopLevelProcessor_jalr dut (
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
    // Clock generation
    // Slow CPU clock : 10 ns period (100 MHz for sim speed)
    // Fast 7-seg clock: 4 ns period (250 MHz) – just keeps TDM running
    // -------------------------------------------------------------------------
    initial clk      = 0;
    initial clk_fast = 0;
    always #5  clk      = ~clk;
    always #2  clk_fast = ~clk_fast;

    // -------------------------------------------------------------------------
    // Task: wait N slow clock cycles
    // -------------------------------------------------------------------------
    task tick;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
            #1; // small settle after posedge
        end
    endtask

    // -------------------------------------------------------------------------
    // Helper: assert with message
    // -------------------------------------------------------------------------
    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input [255:0] test_name;
        input         got;
        input         expected;
        begin
            if (got === expected) begin
                $display("  PASS  %0s", test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %0s  got=%0b expected=%0b", test_name, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_val;
        input [255:0] test_name;
        input [31:0]  got;
        input [31:0]  expected;
        begin
            if (got === expected) begin
                $display("  PASS  %0s  (0x%08X)", test_name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %0s  got=0x%08X expected=0x%08X", test_name, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Expose internal signals via hierarchical references
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
    wire        is_jalr     = dut.is_jalr;
    wire        is_jal      = dut.is_jal;

    // -------------------------------------------------------------------------
    // Stimulus and checks
    // -------------------------------------------------------------------------
    integer cycle;

    initial begin
        $dumpfile("tb_jalr.vcd");
        $dumpvars(0, tb_TopLevelProcessor_jalr);

        // --- Reset ---
        switch_in = 6'b0;
        reset = 1;
        tick(3);
        reset = 0;
        #1;

        $display("\n=== JALR Testbench ===\n");

        // =====================================================================
        // Phase 1: verify reset lands at PC=0
        // =====================================================================
        $display("--- Phase 1: Reset ---");
        check_val("PC after reset", PC, 32'h00000000);

        // =====================================================================
        // Phase 2: Step through the first ADDI instructions
        // PC: 0x00 -> 0x04 -> 0x08 -> 0x0C -> 0x10 -> 0x14 -> 0x18
        // All ADDI: RegWrite=1, MemWrite=0, ALUSrc=1
        // =====================================================================
        $display("--- Phase 2: ADDI instructions (PC 0x00..0x18) ---");

        // PC=0x00  ADDI x10, x0, 42
        check_val("PC=0x00",            PC,       32'h00000000);
        check    ("PC=0x00 RegWrite",   RegWrite, 1'b1);
        check    ("PC=0x00 MemWrite",   MemWrite, 1'b0);
        check    ("PC=0x00 ALUSrc",     ALUSrc,   1'b1);
        check    ("PC=0x00 Branch",     Branch,   1'b0);
        tick(1);

        // PC=0x04  ADDI x5, x0, 512
        check_val("PC=0x04",            PC,       32'h00000004);
        check    ("PC=0x04 RegWrite",   RegWrite, 1'b1);
        check    ("PC=0x04 MemWrite",   MemWrite, 1'b0);
        tick(1);

        // PC=0x08  ADDI x6, x0, 44
        check_val("PC=0x08",            PC,       32'h00000008);
        check    ("PC=0x08 RegWrite",   RegWrite, 1'b1);
        tick(1);

        // PC=0x0C  ADDI x11, x0, 5
        check_val("PC=0x0C",            PC,       32'h0000000C);
        check    ("PC=0x0C RegWrite",   RegWrite, 1'b1);
        tick(1);

        // PC=0x10  NOP (ADDI x0, x0, 0) — RegWrite asserted but writes x0
        check_val("PC=0x10 NOP",        PC,       32'h00000010);
        tick(1);
        check_val("PC=0x14 NOP",        PC,       32'h00000014);
        tick(1);
        check_val("PC=0x18 NOP",        PC,       32'h00000018);
        tick(1);

        // =====================================================================
        // Phase 3: JALR call at 0x1C
        // PC=0x1C  JALR x1, x6, 0  -> PC becomes 0x2C, x1 = 0x20
        // is_jalr=1, Jump=1, RegWrite=1, MemWrite=0
        // =====================================================================
        $display("--- Phase 3: JALR call at PC=0x1C ---");
        check_val("PC=0x1C",            PC,       32'h0000001C);
        check    ("JALR is_jalr",       is_jalr,  1'b1);
        check    ("JALR Jump",          Jump,     1'b1);
        check    ("JALR RegWrite",      RegWrite, 1'b1);
        check    ("JALR MemWrite",      MemWrite, 1'b0);
        check    ("JALR Branch",        Branch,   1'b0);
        check    ("JALR ALUSrc",        ALUSrc,   1'b1); // immediate used
        tick(1);

        // After JALR call, PC should jump to 0x2C
        check_val("PC after JALR call", PC,       32'h0000002C);

        // =====================================================================
        // Phase 4: Subroutine body  0x2C SW, 0x30 ADD
        // =====================================================================
        $display("--- Phase 4: Subroutine body (PC 0x2C, 0x30) ---");

        // PC=0x2C  SW x10, 0(x5)  — MemWrite=1, RegWrite=0
        check_val("PC=0x2C SW",         PC,       32'h0000002C);
        check    ("SW MemWrite",        MemWrite, 1'b1);
        check    ("SW RegWrite",        RegWrite, 1'b0);
        check    ("SW Branch",          Branch,   1'b0);
        tick(1);

        // PC=0x30  ADD x10, x10, x11  — RegWrite=1, MemWrite=0, ALUSrc=0
        check_val("PC=0x30 ADD",        PC,       32'h00000030);
        check    ("ADD RegWrite",       RegWrite, 1'b1);
        check    ("ADD MemWrite",       MemWrite, 1'b0);
        check    ("ADD ALUSrc",         ALUSrc,   1'b0); // reg-reg
        tick(1);

        // =====================================================================
        // Phase 5: JALR return at 0x34
        // PC=0x34  JALR x0, x1, 0  -> PC becomes 0x20
        // is_jalr=1, RegWrite=1 (writes x0), Jump=1
        // =====================================================================
        $display("--- Phase 5: JALR return at PC=0x34 ---");
        check_val("PC=0x34",            PC,       32'h00000034);
        check    ("RET is_jalr",        is_jalr,  1'b1);
        check    ("RET Jump",           Jump,     1'b1);
        check    ("RET RegWrite",       RegWrite, 1'b1);
        check    ("RET MemWrite",       MemWrite, 1'b0);
        tick(1);

        // After return, PC should be 0x20 (x1 = 0x20, stored during call)
        check_val("PC after JALR ret",  PC,       32'h00000020);

        // =====================================================================
        // Phase 6: Return landing + halt
        // 0x20 NOP -> 0x24 JAL x0,0 (self-loop)
        // =====================================================================
        $display("--- Phase 6: Return landing and halt ---");
        check_val("PC=0x20 NOP",        PC,       32'h00000020);
        tick(1);

        check_val("PC=0x24 JAL halt",   PC,       32'h00000024);
        check    ("HALTis_jal",         is_jal,   1'b1);
        tick(1);

        // Should remain halted at 0x24
        check_val("PC still 0x24 +1cy", PC,       32'h00000024);
        tick(1);
        check_val("PC still 0x24 +2cy", PC,       32'h00000024);

        // =====================================================================
        // Phase 7: LED register sentinel check
        // After JALR executed, led_out[15] must be 1
        // =====================================================================
        $display("--- Phase 7: LED sentinel ---");
        check    ("LED sentinel bit15", led_out[15], 1'b1);
        check    ("LED Jump bit14",     led_out[14], 1'b1); // Jump=1 for JALR
        check    ("LED RegWrite bit13", led_out[13], 1'b1);

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

    // Timeout guard: 200 slow cycles
    initial begin
        #(200 * 10);
        $display("TIMEOUT");
        $finish;
    end

endmodule
