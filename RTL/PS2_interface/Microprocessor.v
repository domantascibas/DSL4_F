`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:13:46 03/15/2014 
// Design Name: 
// Module Name:    Microprocessor 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: Top module for the second Lab assessment. Uses the CPU to read
// position data from the mouse and then displays it on the 7Seg display and LEDs.
//
// Dependencies: 
//					MouseTransceiver.v,
//					CPU.v,
//					RAM.v,
//					ROM.v,
//					Seg7Wrapper.v,
//					StatusLED.v,
//					(Timer.v was used for testing purposes).
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Microprocessor(
	// inputs
	input CLK,
	input RESET,
	
	//inouts
	inout CLK_MOUSE,
	inout DATA_MOUSE,
	
	//outputs
	output [7:0] StatusLED,
	output [3:0] SEG_SELECT,
	output [7:0] DEC_OUT
);

wire MouseInterruptRaise;
wire MouseInterruptAck;
//wire TimerInterruptRaise;
//wire TimerInterruptAck;
wire [1:0] BUS_INTERRUPTS_RAISE;
wire [1:0] BUS_INTERRUPTS_ACK;

wire [7:0] BUS_DATA;
wire [7:0] BUS_ADDR;
wire BUS_WE;

wire [7:0] ROM_ADDRESS;
wire [7:0] ROM_DATA;

assign BUS_INTERRUPTS_RAISE = {1'b0,MouseInterruptRaise};
assign MouseInterruptAck = BUS_INTERRUPTS_ACK[0];
//assign TimerInterruptAck = BUS_INTERRUPTS_ACK[1];

//Instantiate the MOUSE peripheral
MouseTransceiver MOUSE(
	.CLK_MOUSE(CLK_MOUSE),
	.DATA_MOUSE(DATA_MOUSE),
	.CLK(CLK),
	.RESET(RESET),
	.BUS_DATA(BUS_DATA),
	.BUS_ADDR(BUS_ADDR),
	.BUS_WE(BUS_WE),
	.BUS_INTERRUPT_RAISE(MouseInterruptRaise),
	.BUS_INTERRUPT_ACK(MouseInterruptAck)
);

//Instantiate the Timer peripheral
/*Timer T(
	.CLK(CLK),
	.RST(RESET),
	.BUS_ADDR(BUS_ADDR),
	.BUS_DATA(BUS_DATA),
	.BUS_WE(BUS_WE),
	.BUS_INTERRUPT_ACK(TimerInterruptAck),
	.BUS_INTERRUPT_RAISE(TimerInterruptRaise)
);
*/

//Instantiate the CPU peripheral
CPU CPU(
	.CLK(CLK),
	.RESET(RESET),
	.BUS_DATA(BUS_DATA),
	.BUS_ADDR(BUS_ADDR),
	.BUS_WE(BUS_WE),
	.ROM_ADDRESS(ROM_ADDRESS),
	.ROM_DATA(ROM_DATA),
	.BUS_INTERRUPTS_RAISE(BUS_INTERRUPTS_RAISE),
	.BUS_INTERRUPTS_ACK(BUS_INTERRUPTS_ACK)
);

//Instantiate the RAM peripheral
RAM RAM(
	.CLK(CLK),
	.BUS_DATA(BUS_DATA),
	.BUS_ADDR(BUS_ADDR),
	.BUS_WE(BUS_WE)
);

//Instantiate the ROM peripheral
ROM ROM(
	.CLK(CLK),
	.DATA(ROM_DATA),
	.ADDR(ROM_ADDRESS)
);

//Instantiate the Seg7Wrapper peripheral
Seg7Wrapper Seg7Interface(
	.CLK(CLK),
	.RESET(RESET),
	.BUS_WE(BUS_WE),
	.BUS_DATA(BUS_DATA),
	.BUS_ADDR(BUS_ADDR),
	.SEG_SELECT(SEG_SELECT),
	.DEC_OUT(DEC_OUT)
);

//Instantiate the StatusLED peripheral
StatusLED LEDInterface(
	.CLK(CLK),
	.RESET(RESET),
	.BUS_DATA(BUS_DATA),
	.BUS_ADDR(BUS_ADDR),
	.BUS_WE(BUS_WE),
	.StatusLED(StatusLED)
);

endmodule
