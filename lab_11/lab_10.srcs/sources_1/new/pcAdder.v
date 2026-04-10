// ============================================================
//  pcAdder.v
//  Computes PC + 4 for sequential instruction fetch.
// ============================================================
module pcAdder (
    input  wire [31:0] PC,
    output wire [31:0] PC_Plus4 //JUST ADDER WHEN NON BRANCH 
);
    assign PC_Plus4 = PC + 32'd4;
endmodule