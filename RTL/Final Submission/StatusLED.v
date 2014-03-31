`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:54:08 03/13/2014 
// Design Name: 
// Module Name:    StatusLED 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: This is the StatusLED peripheral module. It is responsible for
// displaying Mouse Status on the on-board LEDs.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module StatusLED(
    input RESET,
    input CLK,
    inout [7:0] BUS_DATA,
    input [7:0] BUS_ADDR,
    input BUS_WE,
    output reg [7:0] StatusLED
    );

//Define the BUS_ADDR for the StatusLEDs
parameter [7:0] StatusLEDBaseAddr = 8'hC0;

//Tristate bus read controler
	reg TransmitX;
	
	//if the WriteEnable is high, we read the status from the data bus to the internal register
	always@(posedge CLK) begin
		if((BUS_ADDR == StatusLEDBaseAddr) & BUS_WE) 
			StatusLED <= BUS_DATA;
	end
	
	//if the WriteEnable is low, we transmit the status from the internal register
	//otherwise, we keep the data bus at high impedance.
	always@(posedge CLK) begin
		if((BUS_ADDR == StatusLEDBaseAddr) & ~BUS_WE) 
			TransmitX	<= 1'b1;
		else
			TransmitX	<= 1'b0;
	end
	
	assign BUS_DATA = (TransmitX) ? StatusLED : 8'hZZ;	

endmodule
