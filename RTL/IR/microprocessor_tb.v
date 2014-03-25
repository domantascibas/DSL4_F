`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:35:19 03/16/2014
// Design Name:   TopLevelDesign
// Module Name:   /home/s1021378/Documents/dsl4/IR_Transmitter_7_Microprocessor/microprocessor_tb.v
// Project Name:  IR_Transmitter
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: TopLevelDesign
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module microprocessor_tb;

	// Inputs
	reg CLK;
	reg RST;
	reg [3:0] COLOUR_SEL;

	// Outputs
	wire IR_LED;

	// Instantiate the Unit Under Test (UUT)
	TopLevelDesign uut (
		.CLK(CLK), 
		.RST(RST), 
		.COLOUR_SEL(COLOUR_SEL), 
		.IR_LED(IR_LED)
	);

	initial begin
		// Initialize Inputs
		RST = 0;
		COLOUR_SEL = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		
		COLOUR_SEL = 4'b0010;
		RST = 1;
		#10
		RST = 0;
	end
	
	initial begin
		CLK = 1;
		forever #10 CLK = !CLK;
		end
      
endmodule

