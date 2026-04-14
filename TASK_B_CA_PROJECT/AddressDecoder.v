`timescale 1ns / 1ps
// =============================================================================
// Module      : AddressDecoder
// Description : Memory-mapped I/O address decoder for single-cycle RISC-V.
//               Uses exact address matching so stack accesses anywhere in
//               data memory range are never accidentally mapped to I/O.
//
//               Memory map:
//               0x200 -> LED output     (write only)
//               0x300 -> Switch input   (read only)
//               all other addresses -> DataMemory (read/write)
// =============================================================================
module AddressDecoder(
    input  [31:0] address,
    input         readEnable,
    input         writeEnable,
    output reg    DataMemWrite,
    output reg    DataMemRead,
    output reg    LEDWrite,
    output reg    SwitchReadEnable
);
    always @(*) begin
        DataMemWrite     = 0;
        DataMemRead      = 0;
        LEDWrite         = 0;
        SwitchReadEnable = 0;

        if (address == 32'h200) begin           // LED register
            LEDWrite         = writeEnable;
        end else if (address == 32'h300) begin  // Switch input
            SwitchReadEnable = readEnable;
        end else begin                          // Data memory (stack, heap, globals)
            DataMemWrite     = writeEnable;
            DataMemRead      = readEnable;
        end
    end
endmodule
