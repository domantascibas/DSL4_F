`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:24:30 03/13/2014 
// Design Name: 
// Module Name:    Seg7Wrapper 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: This is the 7Seg peripheral wrapper module.
//
// Dependencies: 
//					Seg7Decoder.v,
//					Mux4.v,
//					GenericCounter.v
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Seg7Wrapper(
	input CLK,
	input RESET,
	
	input BUS_WE,
	input [7:0] BUS_ADDR,
	inout [7:0] BUS_DATA,
	
	output [3:0] SEG_SELECT,
	output [7:0] DEC_OUT
	);

//Define the BUS_ADDR for the 7Seg peripheral
parameter [7:0] Seg7BaseAddr = 8'hD0;

//Internal registers to hold position data
reg [7:0] Xpos;
reg [7:0] Ypos;

//Add extra wires to interconnect all the modules
wire [1:0] StrobeCount;
wire [4:0] MuxOut;

wire [4:0] Pos0 = {1'b0,Xpos[7:4]};
wire [4:0] Pos1 = {1'b0,Xpos[3:0]};
wire [4:0] Pos2 = {1'b0,Ypos[7:4]};
wire [4:0] Pos3 = {1'b0,Ypos[3:0]};

wire Bit16TrigOut;

//Instantiate the 7Seg decoder
Seg7Decoder Seg7(
	.SEG_SELECT_IN(StrobeCount),
	.BIN_IN(MuxOut[3:0]),
	.DOT_IN(MuxOut[4]),
	.SEG_SELECT_OUT(SEG_SELECT),
	.HEX_OUT(DEC_OUT)
);

//Instantiate the 4-way Multiplexer
Mux4Way Mux4(
	.CONTROL(StrobeCount),
	.IN0(Pos0),
	.IN1(Pos1),
	.IN2(Pos2),
	.IN3(Pos3),
	.OUT(MuxOut)
);

//Instantiate the Strobe counter to display all four coordinate digits
GenericCounter #(
	.COUNTER_WIDTH(2),
	.COUNTER_MAX(3))
Strobe(
	.CLK(Bit16TrigOut),
	.RESET(RESET),
	.ENABLE_IN(1'b1),
	.COUNT(StrobeCount)
);

//Instantiate the 16Bit counter to reduce the clock speed
GenericCounter #(
	.COUNTER_WIDTH(16), 
	.COUNTER_MAX(49999))
Bit16(
	.CLK(CLK), 
	.RESET(RESET), 
	.ENABLE_IN(1'b1), 
	.TRIGG_OUT(Bit16TrigOut)
);

//Tristate bus read controler
	reg TransmitX;
	reg TransmitY;
	
	//If the WriteEnable is high, we can read data from the data bus to internal registers
	always@(posedge CLK) begin
		if((BUS_ADDR == Seg7BaseAddr) & BUS_WE) 
			Xpos <= BUS_DATA;
		if((BUS_ADDR == (Seg7BaseAddr + 1'b1)) & BUS_WE) 
			Ypos <= BUS_DATA;
	end
	
	//If the WriteEnable is low, we can transmit data from internal registers to the data bus
	//Otherwise, we just keep the data bus at high impedance
	always@(posedge CLK) begin
		if((BUS_ADDR == Seg7BaseAddr) & ~BUS_WE) 
			TransmitX	<= 1'b1;
		else
			TransmitX	<= 1'b0;

		if((BUS_ADDR == (Seg7BaseAddr + 1'b1)) & ~BUS_WE) 
			TransmitY	<= 1'b1;
		else
			TransmitY	<= 1'b0;
	end
	
	assign BUS_DATA = (TransmitX) ? Xpos : 8'hZZ;	
	assign BUS_DATA = (TransmitY) ? Ypos : 8'hZZ;	

endmodule
