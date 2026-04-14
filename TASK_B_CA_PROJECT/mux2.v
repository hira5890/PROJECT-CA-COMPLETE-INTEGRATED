// ============================================================
//  mux2.v
//  2-to-1 multiplexer.
//  sel = 0  ?  Y = A   (PC + 4, sequential)
//  sel = 1  ?  Y = B   (branch target)
// ============================================================
module mux2 (

    input  wire [31:0] A,      // PC + 4
    input  wire [31:0] B,      // Branch target
    input  wire  sel,    // PCSrc control signal
    output wire [31:0] Y       // Next PC
);
    assign Y = sel ? B : A;
endmodule
