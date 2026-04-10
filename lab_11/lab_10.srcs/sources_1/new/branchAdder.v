// ============================================================
//  branchAdder.v
//  Computes PC + (sign-extended immediate << 1).
//
//  NOTE: The B-type immediate from immGen is already the
//  sign-extended 13-bit offset encoded in the instruction.
//  RV32I branches are PC-relative: target = PC + imm,
//  where imm bit[0] is always 0 (2-byte aligned).
//  immGen delivers this value directly, so NO extra shift
//  is needed here.  If your immGen outputs the raw 12-bit
//  field (bits [12:1] only, i.e. NOT pre-shifted), replace
//  the assign with:
//      assign Branch_Target = PC + (Imm << 1);
// ============================================================
module branchAdder (
    input  wire [31:0] PC,
    input  wire [31:0] Imm,          // sign-extended B-type immediate from immGen
    output wire [31:0] Branch_Target
);
    assign Branch_Target = PC + Imm;
endmodule