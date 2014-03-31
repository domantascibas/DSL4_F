`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 	University of Edinburgh
// Engineer: 	Calum Hunter
// 
// Create Date:    16:49:08 02/20/2014 
// Design Name: 
// Module Name:    Mux 
// Project Name: 	 Infrared Receiver for Remote Control Car
// Target Devices: Digilent Basys2 FPGA
// Tool versions:  Xilinx ISE 14.4
// Description: 	 Simple multiplexer used to pass to the Wrapper's output the 
//						 appropriate LED output signal depending on which switch has
//						 been set by the user.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module MuxIR(
	//Colour Select input used as the multiplexer select.
	input [3:0] COLOUR_SEL,
	//Outputs from each state machine used as the inputs
	input yellow_car,
	input green_car,
	input blue_car,
	input red_car,
	//Output to send back to the wrapper module for implementation on the board.
	output IR_LED
    );
	
	///////////////////////////////////////////////////////////////////////////////
	//Define register for use in always@ statement
	reg led;
	
	///////////////////////////////////////////////////////////////////////////////
	//Depending on the value of COLOUR_SEL, pass the desired car output to register
	//"led"
	always @* begin
		case (COLOUR_SEL)
			4'b0001	:	led <= yellow_car;
			4'b0010	:	led <= green_car;
			4'b0100	:	led <= blue_car;
			4'b1000	:	led <= red_car;
			default	:	led <= 1'b0;
			endcase
		end

	///////////////////////////////////////////////////////////////////////////////
	//Assign register "led" to output IR_LED
	assign IR_LED = led;

endmodule
