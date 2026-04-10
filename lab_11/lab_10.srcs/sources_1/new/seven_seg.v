`timescale 1ns / 1ps

module sevenseg_basys3(
    input sys_clk,
    input sys_rst,
    input [15:0] val_in,
    output reg [6:0] seg,
    output reg [3:0] an
);
    reg  [19:0] refr_ctr;
    wire         refr_tick;
    reg  [3:0]  cur_digit;
    reg  [3:0]  tens_place;
    reg  [3:0]  ones_place;
    wire [6:0]  disp_val;

    /* clamp input to max 99 */
    assign disp_val = (val_in > 16'd99) ? 7'd99 : val_in[6:0];

    /* BCD extraction without division */
    always @(*) begin
        if      (disp_val >= 7'd90) begin tens_place = 4'd9; ones_place = disp_val - 7'd90; end
        else if (disp_val >= 7'd80) begin tens_place = 4'd8; ones_place = disp_val - 7'd80; end
        else if (disp_val >= 7'd70) begin tens_place = 4'd7; ones_place = disp_val - 7'd70; end
        else if (disp_val >= 7'd60) begin tens_place = 4'd6; ones_place = disp_val - 7'd60; end
        else if (disp_val >= 7'd50) begin tens_place = 4'd5; ones_place = disp_val - 7'd50; end
        else if (disp_val >= 7'd40) begin tens_place = 4'd4; ones_place = disp_val - 7'd40; end
        else if (disp_val >= 7'd30) begin tens_place = 4'd3; ones_place = disp_val - 7'd30; end
        else if (disp_val >= 7'd20) begin tens_place = 4'd2; ones_place = disp_val - 7'd20; end
        else if (disp_val >= 7'd10) begin tens_place = 4'd1; ones_place = disp_val - 7'd10; end
        else                        begin tens_place = 4'd0; ones_place = disp_val;          end
    end

    /* refresh counter driven by clock */
    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst)
            refr_ctr <= 20'd0;
        else
            refr_ctr <= refr_ctr + 20'd1;
    end

    assign refr_tick = refr_ctr[19];

    /* digit mux - alternate between tens and ones */
    always @(*) begin
        if (refr_tick) begin
            cur_digit = tens_place;
            an        = 4'b1101;
        end else begin
            cur_digit = ones_place;
            an        = 4'b1110;
        end
    end

    /* seven-segment decode */
    always @(*) begin
        case (cur_digit)
            4'd0:    seg = 7'b1000000;
            4'd1:    seg = 7'b1111001;
            4'd2:    seg = 7'b0100100;
            4'd3:    seg = 7'b0110000;
            4'd4:    seg = 7'b0011001;
            4'd5:    seg = 7'b0010010;
            4'd6:    seg = 7'b0000010;
            4'd7:    seg = 7'b1111000;
            4'd8:    seg = 7'b0000000;
            4'd9:    seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end

endmodule