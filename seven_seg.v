`timescale 1ns / 1ps
module sevenseg_basys3(
    input        sys_clk,
    input        sys_rst,
    input [15:0] val_in,
    output reg [6:0] seg,
    output reg [3:0] an
);
    // Only rightmost digit, always enabled
    // an is active LOW on Basys3: 1110 = rightmost digit ON, rest OFF
    always @(*) begin
        an = 4'b1110;

        case (val_in[3:0])
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end

endmodule