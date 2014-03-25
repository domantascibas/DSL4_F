`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:34:56 03/25/2014 
// Design Name: 
// Module Name:    Switches 
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
module Switches(
    input CLK,
    input RST,
    input [7:0] BUS_ADDR,
	 input [7:0] SWITCH_VALUE,
	 input BUS_WE,
    output [7:0] BUS_DATA
    );
	
	///////////////////////////////////////////////////////////////////////////////
	//Define parameters to be used in this module.
	parameter	[7:0]	SwitchBaseAddr	=	8'hD2;
	
	///////////////////////////////////////////////////////////////////////////////
	//Define internal register for switch control.
	reg [7:0] bus_data;
	
	///////////////////////////////////////////////////////////////////////////////
	//Test for correct base address in address bus and that write enable is set.
	//If so, pass the value of the switches into the data bus.
	always @ (posedge CLK) begin
		if (RST)
			bus_data <= 0;
		else begin
			if ((BUS_ADDR == SwitchBaseAddr) & BUS_WE)
				bus_data <= SWITCH_VALUE;
			end
		end
		
	///////////////////////////////////////////////////////////////////////////////
	//Define write enable register
	reg switch_we;
	
	always @ (posedge CLK) begin
		if (RST)
			switch_we <= 0;
		else begin
			if ((BUS_ADDR == SwitchBaseAddr) & BUS_WE)
				switch_we <= 1;
			else
				switch_we <= 0;
			end
		end
	
	///////////////////////////////////////////////////////////////////////////////
	//Assign register to data bus output.
	assign BUS_DATA = (switch_we) ? bus_data:8'hZZ;
	
endmodule
