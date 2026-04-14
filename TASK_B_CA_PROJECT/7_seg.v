`timescale 1ns / 1ps
// =============================================================================
// sevenseg_basys3_4digit  (fixed)
//
// Drives all four Basys-3 seven-segment digits with a 16-bit value in hex.
// Uses time-division multiplexing (TDM).
//
// FIX: previous version rolled the counter over at 2499.  With a 12-bit
// counter the top 2 bits [11:10] only reach 2'b10 before rollover, so
// digit_sel never hits 2'b11 and the leftmost digit was never enabled.
// Fix: let the counter free-run (no rollover condition).  A 12-bit counter
// wraps naturally at 4096, giving digit_sel = refresh_cnt[11:10] an even
// 1024-count slot per digit (~9.8 kHz per digit at 10 MHz - flicker-free).
//
// Digit assignment (MSB left, LSB right - matches normal hex notation):
//   an[3] (leftmost)  = val_in[15:12]
//   an[2]             = val_in[11:8]
//   an[1]             = val_in[7:4]
//   an[0] (rightmost) = val_in[3:0]
//
// an  active LOW  (0 = digit ON)
// seg active LOW  (0 = segment ON)
// Segment order: {g,f,e,d,c,b,a}
// =============================================================================
module sevenseg_basys3_4digit (
    input  wire        sys_clk,
    input  wire        sys_rst,
    input  wire [15:0] val_in,
    output reg  [6:0]  seg,
    output reg  [3:0]  an
);
    // -------------------------------------------------------------------------
    // Free-running 12-bit refresh counter.
    // Wraps at 4096 naturally - no explicit rollover needed.
    // Each digit gets 1024 counts = ~102 us at 10 MHz (well above flicker limit).
    // -------------------------------------------------------------------------
    reg [11:0] refresh_cnt;
    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst)
            refresh_cnt <= 12'd0;
        else
            refresh_cnt <= refresh_cnt + 12'd1;   // free-run, wraps at 4096
    end

    // Top 2 bits select which digit is active: 00->01->10->11->00 ...
    wire [1:0] digit_sel = refresh_cnt[11:10];

    // -------------------------------------------------------------------------
    // Digit-select and nibble mux
    // -------------------------------------------------------------------------
    reg [3:0] nibble;
    always @(*) begin
        case (digit_sel)
            2'b00: begin an = 4'b1110; nibble = val_in[3:0];   end // rightmost
            2'b01: begin an = 4'b1101; nibble = val_in[7:4];   end
            2'b10: begin an = 4'b1011; nibble = val_in[11:8];  end
            2'b11: begin an = 4'b0111; nibble = val_in[15:12]; end // leftmost
            default: begin an = 4'b1111; nibble = 4'd0;        end
        endcase
    end

    // -------------------------------------------------------------------------
    // Hex to 7-segment decoder  (active low, segments {g,f,e,d,c,b,a})
    // -------------------------------------------------------------------------
    always @(*) begin
        case (nibble)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            4'hA: seg = 7'b0001000; // A
            4'hB: seg = 7'b0000011; // b
            4'hC: seg = 7'b1000110; // C
            4'hD: seg = 7'b0100001; // d
            4'hE: seg = 7'b0000110; // E
            4'hF: seg = 7'b0001110; // F
            default: seg = 7'b1111111; // all off
        endcase
    end

endmodule
