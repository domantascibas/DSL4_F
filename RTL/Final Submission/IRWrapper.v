`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 	University of Edinburgh
// Engineer: 	Calum Hunter
// 
// Create Date:    16:25:58 02/12/2014 
// Design Name: 	 
// Module Name:    IRWrapper 
// Project Name: 	 Infrared Receiver for Remote Control Car
// Target Devices: Digilent Basys2 FPGA
// Tool versions:  Xilinx ISE 14.4
// Description:	Program that uses the slide switches present on the Digilent
//		Basys2 to select the colour of car you wish to operate, and by
//		using the buttons on the board to control the direction of the
//		car.
//
// Dependencies: 	 IRTransmitterSM.v
//			 SendPacketCounter.v
//			 MuxIR.v
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module IRWrapper(
	 //Standard Inputs
    input CLK,
    input RST,
	 //Bus Interface Inputs
	 input [7:0] ADDR_IN,
	 input BUS_WE,
    input [7:0] DATA_IN,
    //IR Output
	 output IR_LED
    );
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Define local parameter for the base address of the IR Transmitter module
	localparam BaseAddrIR 		= 8'h90;
	
	//Define wires to be used for signal communication between instantiated modules.
	wire send_packet_out;
	wire yellow;
	wire green;
	wire blue;
	wire red;
	
	reg [3:0] command;		//Used to control the movment of the car. The car will only move (follow the DATA_IN)
									//when the address bus is set to the base address of the IR Transmitter.
	reg [3:0] car_colour;	//Used to select which state machine is to be used, depending on the colour of the car chosen.
	
	//Condition that ensures the module is only operating when the address bus is set to the base address of the IR
	//Transmitter module (0x90).
	always @ (posedge CLK) begin
		if (RST) begin
			command <= 4'b0000;
			car_colour <= 4'b0000;
			end
		else if ((ADDR_IN == BaseAddrIR) & BUS_WE) begin
			command <= DATA_IN [3:0];
			car_colour <= car_colour;
			end
		else if ((ADDR_IN == BaseAddrIR + 8'h01) & BUS_WE) begin
			command <= command;
			car_colour <= DATA_IN [3:0];
			end			
		else begin
			command <= command;
			car_colour <= car_colour;
			end
		end
	
	//Instantiate the IRTransmitter State Machine module for each of the 4 coloured cars: YELLOW,RED,BLUE and GREEN.
	IRTransmitterSM	#			(	.StartBurstSize(88),
											.CarSelectBurstSize(22),
											.GapSize(40),
											.AsserBurstSize(44),
											.DeAsserBurstSize(22),
											.ClockRatio(1250)
											)
							YELLOW	(	.CLK(CLK),
											.RST(RST),
											.COMMAND(command),
											.SEND_PACKET(send_packet_out),
											.IR_LED(yellow)
											);
	IRTransmitterSM	#			(	.StartBurstSize(191),
											.CarSelectBurstSize(47),
											.GapSize(25),
											.AsserBurstSize(47),
											.DeAsserBurstSize(22),
											.ClockRatio(1389)
											)
							BLUE		(	.CLK(CLK),
											.RST(RST),
											.COMMAND(command),
											.SEND_PACKET(send_packet_out),
											.IR_LED(blue)
											);
	IRTransmitterSM	#			(	.StartBurstSize(192),
											.CarSelectBurstSize(24),
											.GapSize(24),
											.AsserBurstSize(48),
											.DeAsserBurstSize(24),
											.ClockRatio(1389)
											)
							RED		(	.CLK(CLK),
											.RST(RST),
											.COMMAND(command),
											.SEND_PACKET(send_packet_out),
											.IR_LED(red)
											);
	IRTransmitterSM	#			(	.StartBurstSize(88),
											.CarSelectBurstSize(44),
											.GapSize(40),
											.AsserBurstSize(44),
											.DeAsserBurstSize(22),
											.ClockRatio(1334)
											)
							GREEN		(	.CLK(CLK),
											.RST(RST),
											.COMMAND(command),
											.SEND_PACKET(send_packet_out),
											.IR_LED(green)
											);
									
	//Instantiate the SendPacketCounter module, used to send a 10Hz trigger to each of the state machines.
	SendPacketCounter	SP0		(	.CLK(CLK),
											.RST(RST),
											.SEND_PACKET_OUT(send_packet_out)
											);
											
	//Instantiate the multiplexer module for selecting the appropriate car colour.
	MuxIR					Mux0		(	.COLOUR_SEL(car_colour),
											.yellow_car(yellow),
											.green_car(green),
											.blue_car(blue),
											.red_car(red),
											.IR_LED(IR_LED)
											);


endmodule
