`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: East Preston Electronics
// Engineer: Domantas Cibas
// 
// Create Date:    00:59:38 11/04/2012 
// Design Name: Decimal Counter
// Module Name:    Seg7Decoder 
// Project Name: Decimal Counter
// Target Devices: Xilinx Basys 2
// Tool versions: ISE Project Navigator 14.2
// Description: This is the main module for the decimal counter project
//
// Dependencies: GenericCounter, Mux4Way, DecimalCounter
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: This is the decoder module for the Decimal Counter.
//	It receives a 2bit input to select and light one segment at a time. A 4bit
//	input from the Multiplexer which actually is a binary encoded number. The
//	decoder converts binary to decimal and displays it in the relevant segment.
//////////////////////////////////////////////////////////////////////////////////

module Seg7Decoder(
    input [1:0] SEG_SELECT_IN,
    input [3:0] BIN_IN,
    input DOT_IN,
    output reg [3:0] SEG_SELECT_OUT,
    output reg [7:0] HEX_OUT
    );

	//segment select case statement
	
	always@(SEG_SELECT_IN) begin
		case(SEG_SELECT_IN)
			2'b00		: SEG_SELECT_OUT <= 4'b1110;
			2'b01		: SEG_SELECT_OUT <= 4'b1101;
			2'b10		: SEG_SELECT_OUT <= 4'b1011;
			2'b11		: SEG_SELECT_OUT <= 4'b0111;
			default	: SEG_SELECT_OUT <= 4'b1111;
		endcase
	end
	
	//4bit input to 8bit 7segment display output
	always@(BIN_IN or DOT_IN) begin
		case(BIN_IN)
			4'h0	: HEX_OUT[6:0] <= 7'b1000000;
			4'h1	: HEX_OUT[6:0] <= 7'b1111001;
			4'h2	: HEX_OUT[6:0] <= 7'b0100100;
			4'h3	: HEX_OUT[6:0] <= 7'b0110000;
			
			4'h4	: HEX_OUT[6:0] <= 7'b0011001;
			4'h5	: HEX_OUT[6:0] <= 7'b0010010;
			4'h6	: HEX_OUT[6:0] <= 7'b0000010;
			4'h7	: HEX_OUT[6:0] <= 7'b1111000;
			
			4'h8	: HEX_OUT[6:0] <= 7'b0000000;
			4'h9	: HEX_OUT[6:0] <= 7'b0010000;
			4'hA	: HEX_OUT[6:0] <= 7'b0001000;
			4'hB	: HEX_OUT[6:0] <= 7'b0000011;
			
			4'hC	: HEX_OUT[6:0] <= 7'b1000110;
			4'hD	: HEX_OUT[6:0] <= 7'b0100001;
			4'hE	: HEX_OUT[6:0] <= 7'b0000110;
			4'hF	: HEX_OUT[6:0] <= 7'b0001110;
			
			default:HEX_OUT[6:0] <= 7'b1000000;
		endcase
		
		//this controls the state of the dot for each of the 7segment displays
		HEX_OUT[7] <= ~DOT_IN;
	end

endmodule
