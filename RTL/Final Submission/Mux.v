`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: East Preston Electronics
// Engineer: Domantas Cibas
// 
// Create Date:    00:59:38 11/04/2012 
// Design Name: Decimal Counter
// Module Name:    Mux4Way 
// Project Name: Decimal Counter
// Target Devices: Xilinx Basys 2
// Tool versions: ISE Project Navigator 14.2
// Description: This is the multiplexer module for the decimal counter project
//
// Dependencies: GenericCounter, DecimalCounter, Seg7Decoder
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: This is the multiplexer for the decimal counter display.
//	It receives a 2bit input from the 2bit counter to select one input out of 4,
//	and sends it to the output (Seg7Decoder)
//////////////////////////////////////////////////////////////////////////////////

module Mux4Way(
    input [1:0] CONTROL,
    input [4:0] IN0,
    input [4:0] IN1,
    input [4:0] IN2,
    input [4:0] IN3,
    output reg [4:0] OUT
    );

always@(CONTROL or IN0 or IN1 or IN2 or IN3) begin
	case (CONTROL)
		2'b00		: OUT <= IN0;
		2'b01		: OUT <= IN1;
		2'b10		: OUT <= IN2;
		2'b11		: OUT <= IN3;
		default	: OUT <= 5'b00000;
	endcase	
end

endmodule
