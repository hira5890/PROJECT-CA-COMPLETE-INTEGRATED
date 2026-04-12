`timescale 1ns / 1ps

module top_control_fpga_task_b(
    input clk,
    input rst,
    input btnC,
    input [15:0] sw,
    output [15:0] led
);

    reg [1:0] state;
    reg [6:0] opcode_reg;
    reg [2:0] funct3_reg;
    reg [6:0] funct7_reg;

    wire [31:0] switch_readData;

    wire RegWrite;
    wire [1:0] ALUOp;
    wire MemRead;
    wire MemWrite;
    wire ALUSrc;
    wire MemtoReg;
    wire Branch;
    wire Jump;              // FIX: declared Jump wire
    wire [3:0] ALUControl_out;

    reg btn_prev;
    wire btn_pulse;

    assign btn_pulse = btnC & ~btn_prev;

    // Switch interface
    switches sw_if (
        .clk(clk),
        .rst(rst),
        .writeData(32'b0),
        .writeEnable(1'b0),
        .readEnable(1'b1),
        .memAddress(30'b0),
        .sw(sw),
        .readData(switch_readData),
        .leds()
    );

    // Button edge detection
    always @(posedge clk or posedge rst) begin
        if (rst)
            btn_prev <= 1'b0;
        else
            btn_prev <= btnC;
    end

    // FSM for loading opcode, funct3, funct7
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= 2'b00;
            opcode_reg <= 7'b0;
            funct3_reg <= 3'b0;
            funct7_reg <= 7'b0;
        end
        else if (btn_pulse) begin
            case (state)
                2'b00: begin
                    opcode_reg <= switch_readData[6:0];
                    state <= 2'b01;
                end
                2'b01: begin
                    funct3_reg <= switch_readData[2:0];
                    state <= 2'b10;
                end
                2'b10: begin
                    funct7_reg <= switch_readData[6:0];
                    state <= 2'b11;
                end
                2'b11: begin
                    state <= 2'b11;  // stay here to observe outputs
                end
            endcase
        end
    end

    // Main Control
    MainControl mc (
        .opcode(opcode_reg),
        .RegWrite(RegWrite),
        .ALUOp(ALUOp),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg),
        .Branch(Branch),
        .Jump(Jump)         // FIX: now connects to declared wire
    );

    // ALU Control
    ALUControl alu_ctrl (
        .opcode(opcode_reg),
        .ALUOp(ALUOp),
        .funct3(funct3_reg),
        .funct7(funct7_reg),
        .ALUControl(ALUControl_out)
    );

    /*
    LED Mapping:
    LED[15:12] = ALUControl_out (4 bits)
    LED[11]    = ALUOp[1]
    LED[10]    = ALUOp[0]
    LED[9]     = Branch | Jump
    LED[8]     = MemtoReg
    LED[7]     = MemWrite
    LED[6]     = MemRead
    LED[5]     = ALUSrc
    LED[4]     = RegWrite
    LED[3:2]   = unused
    LED[1:0]   = FSM state
    */
    // Gate all signal LEDs - only show final result once all three inputs
    // have been loaded (state 11). This prevents misleading partial
    // results for R-type / I-type where funct3/funct7 affect ALUControl.
    assign led[15:12] = (state == 2'b11) ? ALUControl_out : 4'b0000;
    assign led[11]    = (state == 2'b11) ? ALUOp[1]       : 1'b0;
    assign led[10]    = (state == 2'b11) ? ALUOp[0]       : 1'b0;
    assign led[9]     = (state == 2'b11) ? (Branch|Jump)  : 1'b0;
    assign led[8]     = (state == 2'b11) ? MemtoReg       : 1'b0;
    assign led[7]     = (state == 2'b11) ? MemWrite       : 1'b0;
    assign led[6]     = (state == 2'b11) ? MemRead        : 1'b0;
    assign led[5]     = (state == 2'b11) ? ALUSrc         : 1'b0;
    assign led[4]     = (state == 2'b11) ? RegWrite       : 1'b0;
    assign led[3:2]   = 2'b00;
    assign led[1:0]   = state;          // always show FSM state for navigation

endmodule