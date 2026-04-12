`timescale 1ns / 1ps

module task_c_tb;
    reg clk;
    reg reset;
    reg [5:0] switch_in;

    wire [5:0] led_out;
    wire led_write_en;
    wire [6:0] seg;
    wire [3:0] an;

    TopLevelProcessor uut (
        .clk(clk),
        .reset(reset),
        .switch_in(switch_in),
        .led_out(led_out),
        .led_write_en(led_write_en),
        .seg(seg),
        .an(an)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer cycle;

    initial begin
        $display("SIM START");

        reset = 1;
        switch_in = 0;

        #20 reset = 0;

        #1000;

        $display("SIM END");
        $stop;
    end

    always @(posedge clk) begin
        cycle = cycle + 1;

        // ONLY CRITICAL DEBUG
        $display(
            "PC=%h | OPCODE=%b | ALU=%h | MEMWR=%b | LEDWR=%b | LED=%d",
            uut.PC,
            uut.opcode,
            uut.ALUResult,
            uut.MemWrite,
            uut.LEDWrite_en,
            led_out
        );
    end

endmodule