`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Pavel Abrosimov, Calum Hunter, Domantas Cibas
// 
// Create Date: 19:13:46 03/27/2014 
// Design Name: Project Top Wrapper
// Module Name:	TopWrapper.v
// Project Name: Digital Systems Laboratory 4, group F
// Target Devices: Digilent Basys 2 board
// Tool versions: 
// Description: Design that uses a microprocessor and various peripherals (a VGA 
//				screen, a PS/2 mouse and an IR transmitter) to navigate a remote
//				controlled car in various directions. RISC microprocessor employing
//				Harvard architecture. Instructions for car navigation are provided 
//				in demo RAM and ROM text files.
//
// Dependencies: 
//				RAM.v
//				ROM.v
//				CPU.v	
//				Complete_Demo_RAM.txt
//				Complete_Demo_ROM.txt
//				VGA_Wrapper.v
//				IRWrapper.v
//				MouseTransceiver.v
//				Timer.v
//				Seg7Wrapper.v
//				StatusLED.v
//				Switches.v
//				IR_CPU.ucf
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module TopWrapper(
	// inputs
	input CLK,
	input RESET,
	input [7:0] SWITCHES,

	//inouts
	inout CLK_MOUSE,
	inout DATA_MOUSE,

	//outputs
	output [7:0] StatusLED,
	output [3:0] SEG_SELECT,
	output [7:0] DEC_OUT,

   //output [7:0] COLOUR_OUT,
   //output HS_OUT,
   //output VS_OUT,

	output IR_LED
    );

//////////////////////////////////////////////////////////////////////////////////
//Interconnecting wires
//

//ROM buses
wire [7:0] ROM_DATA;
wire [7:0] ROM_ADDR;

//Processor buses
wire [7:0] BUS_DATA;
wire [7:0] BUS_ADDR;
wire BUS_WE;

//Interrupts
wire [1:0] BUS_INTERRUPTS_RAISE;
wire [1:0] BUS_INTERRUPTS_ACK;

//////////////////////////////////////////////////////////////////////////////////
//Instantiating peripherals
//

//Instantiate RAM
RAM RAM(
	.CLK(CLK),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE)
);

//Instantiate ROM
ROM ROM(
	.CLK(CLK),
    .DATA(ROM_DATA),
    .ADDR(ROM_ADDR)
);

//Instantiate CPU
CPU CPU(
	.CLK(CLK),
	.RESET(RESET),
	.BUS_DATA(BUS_DATA),
	.BUS_ADDR(BUS_ADDR),
	.BUS_WE(BUS_WE),
	.ROM_ADDRESS(ROM_ADDR),
	.ROM_DATA(ROM_DATA),
	.BUS_INTERRUPTS_RAISE(BUS_INTERRUPTS_RAISE),
	.BUS_INTERRUPTS_ACK(BUS_INTERRUPTS_ACK)
);
/*
//Instantiate VGA peripheral
VGA_Wrapper VGA(
	.CLK(CLK),
    .RESET(RESET),
    .BUS_ADDR(BUS_ADDR),
    .BUS_DATA(BUS_DATA),
    .BUS_WE(BUS_WE),
    .COLOUR_OUT(COLOUR_OUT),
    .HS_OUT(HS_OUT),
    .VS_OUT(VS_OUT)
);
*/
//Instantiate IR peripheral
IRWrapper IR(
	.CLK(CLK),
	.RST(RESET),
	.DATA_IN(BUS_DATA),
	.ADDR_IN(BUS_ADDR),
	.BUS_WE(BUS_WE),
//	.COLOUR_SEL(COLOUR_SEL),
	.IR_LED(IR_LED)
);

//Instantiate MOUSE peripheral
MouseTransceiver MOUSE(
	.CLK_MOUSE(CLK_MOUSE),
	.DATA_MOUSE(DATA_MOUSE),
	.CLK(CLK),
	.RESET(RESET),
	.BUS_DATA(BUS_DATA),
	.BUS_ADDR(BUS_ADDR),
	.BUS_WE(BUS_WE),
	.BUS_INTERRUPT_ACK(BUS_INTERRUPTS_ACK[0]),
	.BUS_INTERRUPT_RAISE(BUS_INTERRUPTS_RAISE[0])
);

//Instantiate TIMER peripheral
Timer TIMER(
	.CLK(CLK),
    .RST(RESET),
    .BUS_ADDR(BUS_ADDR),
    .BUS_DATA(BUS_DATA),
    .BUS_WE(BUS_WE),
    .BUS_INTERRUPT_ACK(BUS_INTERRUPTS_ACK[1]),
    .BUS_INTERRUPT_RAISE(BUS_INTERRUPTS_RAISE[1])
);    

//Instantiate SEG7 peripheral
Seg7Wrapper SEG7(
	.CLK(CLK),
	.RESET(RESET),
	.BUS_WE(BUS_WE),
	.BUS_DATA(BUS_DATA),
	.BUS_ADDR(BUS_ADDR),
	.SEG_SELECT(SEG_SELECT),
	.DEC_OUT(DEC_OUT)
);

//Instantiate LED peripheral
StatusLED LED(
	.CLK(CLK),
	.RESET(RESET),
	.BUS_DATA(BUS_DATA),
	.BUS_ADDR(BUS_ADDR),
	.BUS_WE(BUS_WE),
	.StatusLED(StatusLED)
);

//Instantiate SWITCHES
Switches SW(
	.CLK(CLK),
	.RST(RESET),
	.BUS_DATA(BUS_DATA),
	.BUS_ADDR(BUS_ADDR),
	.BUS_WE(BUS_WE),
	.SWITCH_VALUE(SWITCHES)
);

endmodule