`timescale 1ns / 1ps

module tb_top;


// Inputs
reg clk;
reg reset;
reg [5:0] switch_in;

// Outputs
wire [5:0] led_out;
wire led_write_en;
wire [6:0] seg;
wire [3:0] an;

// Instantiate DUT (your TopLevelProcessor)
TopLevelProcessor uut (
    .clk(clk),
    .reset(reset),
    .switch_in(switch_in),
    .led_out(led_out),
    .led_write_en(led_write_en),
    .seg(seg),
    .an(an)
);

// Clock generation (10ns period)
always #5 clk = ~clk;

initial begin
    // Initialize
    clk = 0;
    reset = 1;
    switch_in = 0;

    // Apply reset
    #20;
    reset = 0;

    // Stay idle
    #50;

    // Give input (simulate switch = 5)
    switch_in = 6'd5;

    // Let it run (countdown should happen)
    #2000;

    // Remove input
    switch_in = 0;

    #500;

    $stop;
end

endmodule
