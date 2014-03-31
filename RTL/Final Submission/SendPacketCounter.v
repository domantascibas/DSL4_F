`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Calum Hunter
// 
// Create Date:    11:23:38 01/28/2014 
// Design Name: 	 
// Module Name:    SendPacketCounter 
// Project Name: 	 Infrared Receiver for Remote Control Car
// Target Devices: Digilent BASYS2
// Tool versions:  ISE 14.4
// Description: Counter with frequency of 10Hz, setting SEND_PACKET_OUT high
//		10 times a second.
//
// Dependencies: 	 N/A
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module SendPacketCounter(
    input CLK,
    input RST,
    output SEND_PACKET_OUT
    );
	 
	 //Define registers
	 reg [22:0] counter = 0;
	 reg packet_out;

	 //Implement counter to produce a frequency of 10Hz
	 always @ (posedge CLK) begin
		if (RST)
			// If reset (RST) is enabled, return counter to 0
			counter <= 0;
		else begin
			// Otherwise, when counter reaches 5000000, reset counter to 0 and set SEND_PACKET_OUT high for ONE clock cycle only
			if (counter == 5000000) begin
				counter <= 0;
				packet_out <= 1;
				end
			else begin
				// Increment counter by one and reset SEND_PACKET_OUT to 0
				counter <= counter + 1;
				packet_out <= 0;
				end
			end
		end
	
	//Assign	registers to the module output
	assign SEND_PACKET_OUT = packet_out;

endmodule
