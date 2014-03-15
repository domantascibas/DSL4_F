`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:   14:35:52 03/15/2014
// Design Name:   TopModule
// Module Name:   /media/NTFS/Uni/13-14/Sem_2/DSL/REPO/DSL4_F/TB/CPU/TopModule_tb.v
// Project Name:  DSL4_F
// Target Device:
// Tool versions:
// Description:
//
// Verilog Test Fixture created by ISE for module: TopModule
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
////////////////////////////////////////////////////////////////////////////////

module TopModule1_tb;

	// Inputs
	reg CLK;
	reg RESET;
	reg [1:0] IQR_RAISE;

	// Outputs
	wire [1:0] IRQ_ACK;

	// Instantiate the Unit Under Test (UUT)
	TopModule1 uut (
		.CLK(CLK),
		.RESET(RESET),
		.IQR_RAISE(IQR_RAISE),
		.IRQ_ACK(IRQ_ACK)
	);

	initial begin
		// Initialize Inputs
		CLK = 0;
		forever #10 CLK = ~CLK;
	end

	initial begin
		// Initialize Inputs
		RESET = 1;
		IQR_RAISE = 0;

		#30;
		RESET = 0;

		#30;

		//IQR_RAISE = 1; // trigger handler @ 0xFF addr

	    // Wait 100 ns for global reset to finish
		#100;

		// Add stimulus here

	end

endmodule

