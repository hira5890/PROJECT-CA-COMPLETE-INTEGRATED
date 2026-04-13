module RISCVALU(
    input  [3:0] ALUctl,       // ALU control signal
    input  [31:0] A, B,        // 32-bit operands
    output reg [31:0] ALUout,  // 32-bit result
    output Zero                 // Zero flag
);

// Zero flag: 1 if ALUout is 0
assign Zero = (ALUout == 0);

always @(ALUctl, A, B) begin
    case (ALUctl)
        4'b0000: ALUout <= A & B;             // AND
        4'b0001: ALUout <= A | B;             // OR
        4'b0010: ALUout <= A + B;             // ADD
        4'b0110: ALUout <= A - B;             // SUBTRACT
        4'b0111: ALUout <= (A < B) ? 1 : 0;  // SET ON LESS THAN
        4'b1100: ALUout <= ~(A | B);          // NOR
        4'b1000: ALUout <= A << B;            // SLL (Shift Left Logical)
        4'b1001: ALUout <= A >> B;            // SRL (Shift Right Logical)
        4'b1010: ALUout <= A ^ B;   // XOR
        4'b0011: ALUout <= B;   // LUI pass-through

        default: ALUout <= 32'b0;             // Default: 0
    endcase
end

endmodule  
 
