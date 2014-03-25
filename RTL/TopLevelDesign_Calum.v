`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 	Calum Hunter
// 
// Create Date:    09:41:38 03/11/2014 
// Design Name: 
// Module Name:    TopLevelDesign 
// Project Name: 
// Target Devices: Digilent Basys 2
// Tool versions: 
// Description:  	Design that uses a microprocessor to navigate a remote control
//						car in set directions, moving for a set amount of time (one second).
//						RISC microprocessor employing Harvard architecture. Instructions for
//						car navigation are provided in demo RAM and ROM text files.
//
// Dependencies: 	Complete_Demo_RAM.txt
//						Complete_Demo_ROM.txt
//						IRWrapper.v
//						Timer.v
//						RAM.v
//						ROM.v
//						Microprocessor.v
//						IR_CPU.ucf
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module TopLevelDesign(
    input CLK,
    input RST,
	 input [7:0] SWITCHES,
	 output IR_LED
    );
	
	//////////////////////////////////////////////////////////////////////////////////
	//Interconnecting wires
	
	//Processor Buses
	wire [7:0] data_bus;
	wire [7:0] addr_bus;
	wire bus_we;
	
	//ROM Buses
	wire [7:0] rom_addr;
	wire [7:0] rom_data;
	
	//Interrupts
	wire [1:0] interrupt;			
	wire [1:0] interrupt_ack;	
	
	//////////////////////////////////////////////////////////////////////////////////
	
	//Instantiate IR Transmitter Module	
	IRWrapper	IR0	(	.CLK(CLK),
								.RST(RST),
								.ADDR_IN(addr_bus),
								.BUS_WE(bus_we),
								.DATA_IN(data_bus),
//								.COLOUR_SEL(COLOUR_SEL),
								.IR_LED(IR_LED)
								);
	
	//Instantiate Timer Module
	Timer			T0		(	.CLK(CLK),
								.RST(RST),
								.BUS_ADDR(addr_bus),
								.BUS_DATA(data_bus),
								.BUS_WE(bus_we),
								.BUS_INTERRUPT_ACK(interrupt_ack[1]),
								.BUS_INTERRUPT_RAISE(interrupt[1])
								);
	
	//Instantiate RAM
	RAM			RAM0	(	.CLK(CLK),
								.BUS_DATA(data_bus),
								.BUS_ADDR(addr_bus),
								.BUS_WE(bus_we)
								);
								
	//Instantiate ROM
	ROM			ROM0	(	.CLK(CLK),
								.DATA(rom_data),
								.ADDR(rom_addr)
								);
								
	//Instantiate Microprocessor
	CPU			CPU0	(	.CLK(CLK),
								.RESET(RST),
								.BUS_DATA(data_bus),
								.BUS_ADDR(addr_bus),
								.BUS_WE(bus_we),
								.ROM_ADDRESS(rom_addr),
								.ROM_DATA(rom_data),
								.BUS_INTERRUPTS_RAISE(interrupt),
								.BUS_INTERRUPTS_ACK(interrupt_ack)
								);
								
	Switches		SW0	(	.CLK(CLK),
								.RST(RST),
								.BUS_ADDR(addr_bus),
								.BUS_WE(bus_we),
								.SWITCH_VALUE(SWITCHES),
								.BUS_DATA(data_bus)
								);


endmodule
