`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:58:05 03/08/2014 
// Design Name: 
// Module Name:    MouseInterface 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module MouseInterface(
	input CLK,
	input RESET,
	
	inout CLK_MOUSE,
	inout DATA_MOUSE,
	
	output [0:7] StatusLED,
	output [7:0] DEC_OUT,
	output [3:0] SEG_SELECT
    );

wire [4:0] MuxOut;
wire [1:0] StrobeCount;

wire [7:0] Xpos;
wire [7:0] Ypos;

wire [3:0] Pos0;
wire [3:0] Pos1;
wire [3:0] Pos2;
wire [3:0] Pos3;

assign Pos0 = Xpos[7:4];
assign Pos1 = Xpos[3:0];
assign Pos2 = Ypos[7:4];
assign Pos3 = Ypos[3:0];

MouseTransceiver MT(
	.MouseX(Xpos),
	.MouseY(Ypos),
	.CLK_MOUSE(CLK_MOUSE),
	.DATA_MOUSE(DATA_MOUSE),
	.MouseStatus(StatusLED),
	.RESET(RESET),
	.CLK(CLK)
);

Seg7Decoder Seg7(
	.SEG_SELECT_IN(StrobeCount),
	.BIN_IN(MuxOut[3:0]),
	.DOT_IN(MuxOut[4]),
	.SEG_SELECT_OUT(SEG_SELECT),
	.HEX_OUT(DEC_OUT)
);

GenericCounter #(
	.COUNTER_WIDTH(2),
	.COUNTER_MAX(3))
Strobe(
	.CLK(Bit16TrigOut),
	.RESET(1'b0),
	.ENABLE_IN(1'b1),
	.COUNT(StrobeCount)
);

GenericCounter #(
	.COUNTER_WIDTH(16), 
	.COUNTER_MAX(49999))
Bit16(
	.CLK(CLK), 
	.RESET(1'b0), 
	.ENABLE_IN(1'b1), 
	.TRIG_OUT(Bit16TrigOut)
);

Mux4Way Mux4(
	.CONTROL(StrobeCount),
	.IN0(Pos0),
	.IN1(Pos1),
	.IN2(Pos2),
	.IN3(Pos3),
	.OUT(MuxOut)
);

endmodule
