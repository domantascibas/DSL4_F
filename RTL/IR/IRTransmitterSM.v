`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  University of Edinburgh
// Engineer: Calum Hunter
// 
// Create Date:    09:53:10 01/28/2014 
// Design Name: 	 
// Module Name:    IRTransmitterSM 
// Project Name: 	 Infrared Receiver for Remote Control Car
// Target Devices: Digilent BASYS2 FPGA
// Tool versions:  ISE 14.4
// Description: 	 Generates a clock used to communicate to the cars, whose frequency
//						 depends on the target car.
//						 State machine used to control the number of pulses that are set
//						 in the signal packet that is sent to the receiver of the target
//						 car. There are 7 states: IDLE,START,GAP,CAR_SELECT,RIGHT,LEFT,
//						 BACK and FORWARD. Depending on the number of pulses in the direction
//						 states, the car will respond by moving in that direction or not.
//
// Dependencies: 	 SendPacketCounter.v
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module IRTransmitterSM(
    //Standard Signals
	 input RST,
    input CLK,
	 //Bus Interface Signals
    input [3:0] COMMAND,
    input SEND_PACKET,
	 //Infrared LED Signal
    output IR_LED,
	 output [2:0] STATE		//Used only for debugging in simulations
    );
	 
	 ///////////////////////////////////////////////////////////////////////////////////////////////////////
	 ///////////////////////////////////////////////////////////////////////////////////////////////////////
	 
	 //State Number Parameters
	 //Use localparam so that they cannot be changed outside the module
	 localparam	IDLE			=	3'd0;
	 localparam	START			=	3'd1;
	 localparam	GAP			=	3'd2;
	 localparam	CAR_SELECT	=	3'd3;
	 localparam	RIGHT			=	3'd4;
	 localparam	LEFT			=	3'd5;
	 localparam	BACK			=	3'd6;
	 localparam	FORWARD		=	3'd7;
	 
	 //Parameter Constants for YELLOW Car
	 //These values can be altered outside the module for use of a different coloured car
	 parameter	StartBurstSize			= 88;
	 parameter	CarSelectBurstSize	= 22;
	 parameter	GapSize					= 40;
	 parameter	AsserBurstSize			= 44;
	 parameter	DeAsserBurstSize		= 22;
	 parameter	ClockRatio				= 1250;	//Master clock divided by car's clock (For Yellow: 50MHz/40kHz)
	 
	 ///////////////////////////////////////////////////////////////////////////////////////////////////////
	 ///////////////////////////////////////////////////////////////////////////////////////////////////////
	 
	 //Generate the pulse signal at a frequency of 40kHz for the YELLOW coloured car (clock frequency is 50MHz)
	 //By altering parameter ClockRatio, this can be changed to suit any coloured car from the Wrapper module.
	 reg [10:0] pulse_count = 0;
	 reg car_clk;
	 
	 //11-bit counter that counts up to the Clock Ratio minus 1 then resets.
	 always @ (posedge CLK) begin
		if (RST)
			pulse_count <= 11'b00000000000;
		else begin
			if (pulse_count == (ClockRatio - 1))
				pulse_count <= 11'b00000000000;
			else
				pulse_count <= pulse_count +1;
			end
		end
		
	 //When the above counter is between 0 and 625, set the car_clk high, and low otherwise
	 //This creates a clock with a duty raio of 0.5
	 always @ (posedge CLK) begin
		if (RST)
			car_clk <= 0;
		else begin
			if (pulse_count < (ClockRatio / 2))
				car_clk <= 1;
			else
				car_clk <= 0;
			end
		end
	 
	 //Counter to count the number of clock pulses in a given state.
	 //Counter resets on the assertion of register "count_rst".
	 reg [18:0] clk_count;
	 reg count_rst;
	 
	 always @ (posedge CLK) begin
		if (count_rst)
			clk_count <= 19'b0000000000000000000;
		else
			clk_count <= clk_count + 1;
		end
	 
	 ///////////////////////////////////////////////////////////////////////////////////////////////////////
	 ///////////////////////////////////////////////////////////////////////////////////////////////////////
	 
	 //Simple state machine to generate the states of the packet
	 
	 //Define 3-bit state registers
	 reg [2:0] CurrState;
	 reg [2:0] NextState;
	 reg [2:0] PrevState;
	 
	 //Define infrared led output register
	 reg led_out;
	 
	 //State machine sequential logic
	 //On assertion of RST, set CurrState and PrevState to 0 (IDLE).
	 //Register PrevState always mirrors CurrState unless GAP is the current state. In this case, PrevState
	 //stays what it was before entering GAP and is then used to determine which state to go to next.
	 always @ (posedge CLK) begin
		if (RST) begin
			CurrState <= IDLE;
			PrevState <= IDLE;
			end
		else begin
			CurrState <= NextState;
			if (CurrState == GAP)
				PrevState <= PrevState;
			else
				PrevState <= CurrState;
			end
		end
	 
	 //State machine combinatorial logic
	 always @* begin
		case (CurrState)
			//In IDLE, set "count_rst" to 1 to ensure the counter is set to 0 when entering start, and set
			//led_out to 0.
			//Wait for SEND_PACKET to set high before entering START, otherwise stay in IDLE.
			IDLE	:	begin
						count_rst <= 1;
						led_out <= 0;
						if (SEND_PACKET) begin
							NextState <= START;
							end
						else
							NextState <= CurrState;
						end
			
			//Set "led_out" to follow the "car_clk" until the "clk_count" reaches the StartBurstSize times the ClockRatio
			//At which, reset the counter and prepare to enter the GAP state.
			START	:	begin
						led_out <= car_clk;
							if (clk_count == (StartBurstSize*ClockRatio)-1) begin
								count_rst <= 1;
								NextState <= GAP;
								end
							else begin
								count_rst <= 0;
								NextState <= CurrState;
								end
						end
			
			//Always set led_out to 0 in the GAP state.
			//Have a case statement on PrevState, as when you know where you have come from, you can determine where to 
			//go next. 
			//In each instance, wait for the clk_count to reach the desired GAP size before progessing to the next state.
			GAP	:	begin
						led_out <= 0;
						case (PrevState)
							IDLE	:	begin
										led_out <= 0;
										count_rst <= 1;
										NextState <= START;
										end
							START : 	begin
										if (clk_count == (GapSize*ClockRatio)-1) begin
											count_rst <= 1;
											NextState <= CAR_SELECT;
											end
										else begin
											count_rst <= 0;
											NextState <= CurrState;
											end
										end
							GAP	:	begin
										led_out <= 0;
										count_rst <= 1;
										NextState <= IDLE;
										end
							CAR_SELECT :	begin
												if (clk_count == (GapSize*ClockRatio)-1) begin
													count_rst <= 1;
													NextState <= RIGHT;
													end
												else begin
													count_rst <= 0;
													NextState <= CurrState;
													end
												end
							RIGHT :	begin
										if (clk_count == (GapSize*ClockRatio)-1) begin
											count_rst <= 1;
											NextState <= LEFT;
											end
										else begin
											count_rst <= 0;
											NextState <= CurrState;
											end
										end
							LEFT	:	begin
										if (clk_count == (GapSize*ClockRatio)-1) begin
											count_rst <= 1;
											NextState <= BACK;
											end
										else begin
											count_rst <= 0;
											NextState <= CurrState;
											end
										end
							BACK	:	begin
										if (clk_count == (GapSize*ClockRatio)-1) begin
											count_rst <= 1;
											NextState <= FORWARD;
											end
										else begin
											count_rst <= 0;
											NextState <= CurrState;
											end
										end
							FORWARD	:	begin
											if (clk_count == (GapSize*ClockRatio)-1) begin
												count_rst <= 1;
												NextState <= IDLE;
												end
											else begin
												count_rst <= 0;
												NextState <= CurrState;
												end
											end
							default	:	begin
											count_rst <= 1;
											NextState <= IDLE;
											end
							endcase
						end
			
			//Set "led_out" to mirror "car_clk" and wait until the correct number of CAR_SELECT pulses have been set.
			CAR_SELECT	:	begin
								led_out <= car_clk;		
								if (clk_count == (CarSelectBurstSize*ClockRatio)-1) begin
									count_rst <= 1;
									NextState <= GAP;
									end
								else begin
									count_rst <= 0;
									NextState <= CurrState;
									end
								end
			
			//Test to see if the RIGHT bit of COMMAND has been asserted.
			//If so, use the AsserBurstSize to determine how long to spend in RIGHT, 
			//otherwise, use DeAsserBurstSize to do so.
			//"led_out" follows "car_clk" in this state.
			RIGHT	:	begin						
						led_out <= car_clk;
						if (COMMAND[0] == 1) begin
							if (clk_count == (AsserBurstSize*ClockRatio)-1) begin
								count_rst <= 1;
								NextState <= GAP;
								end
							else begin
								count_rst <= 0;
								NextState <= CurrState;
								end
							end
						else begin
							if (clk_count == (DeAsserBurstSize*ClockRatio)-1) begin
								count_rst <= 1;
								NextState <= GAP;
								end
							else begin
								count_rst <= 0;
								NextState <= CurrState;
								end
							end
						end
			
			//Test to see if the LEFT bit of COMMAND has been asserted.
			//If so, use the AsserBurstSize to determine how long to spend in LEFT, 
			//otherwise, use DeAsserBurstSize to do so.
			//"led_out" follows "car_clk" in this state.
			LEFT	:	begin
						led_out <= car_clk;
						if (COMMAND[1] == 1) begin
							if (clk_count == (AsserBurstSize*ClockRatio)-1) begin
								count_rst <= 1;
								NextState <= GAP;
								end
							else begin
								count_rst <= 0;
								NextState <= CurrState;
								end
							end
						else begin
							if (clk_count == (DeAsserBurstSize*ClockRatio)-1) begin
								count_rst <= 1;
								NextState <= GAP;
								end
							else begin
								count_rst <= 0;
								NextState <= CurrState;
								end
							end
						end
			
			//Test to see if the BACKWARD bit of COMMAND has been asserted.
			//If so, use the AsserBurstSize to determine how long to spend in BACK, 
			//otherwise, use DeAsserBurstSize to do so.
			//"led_out" follows "car_clk" in this state.
			BACK	:	begin
						led_out <= car_clk;
						if (COMMAND[2] == 1) begin
							if (clk_count == (AsserBurstSize*ClockRatio)-1) begin
								count_rst <= 1;
								NextState <= GAP;
								end
							else begin
								count_rst <= 0;
								NextState <= CurrState;
								end
							end
						else begin
							if (clk_count == (DeAsserBurstSize*ClockRatio)-1) begin
								count_rst <= 1;
								NextState <= GAP;
								end
							else begin
								count_rst <= 0;
								NextState <= CurrState;
								end
							end
						end
			
			//Test to see if the FORWARD bit of COMMAND has been asserted.
			//If so, use the AsserBurstSize to determine how long to spend in FORWARD, 
			//otherwise, use DeAsserBurstSize to do so.
			//"led_out" follows "car_clk" in this state.
			FORWARD	:	begin
							led_out <= car_clk;
							if (COMMAND[3] == 1) begin
								if (clk_count == (AsserBurstSize*ClockRatio)-1) begin
									count_rst <= 1;
									NextState <= GAP;
									end
								else begin
									count_rst <= 0;
									NextState <= CurrState;
									end
								end
							else begin
								if (clk_count == (DeAsserBurstSize*ClockRatio)-1) begin
									count_rst <= 1;
									NextState <= GAP;
									end
								else begin
									count_rst <= 0;
									NextState <= CurrState;
									end
								end
							end
			
			//Default state sends the CurrState back to IDLE, resets the counter and sets led_out to 0.
			//When in IDLE, the State Machine will wait for another assertion of SEND_PACKET and start over again.
			default	:	begin
							count_rst <= 1;
							led_out <= 0;
							NextState <= IDLE;
							end								
			endcase
		end
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////	
		///////////////////////////////////////////////////////////////////////////////////////////////////////
	   
		//Assign output IR_LED to the register led_out that had been used during the State Machine.
		assign IR_LED	= led_out;
		assign STATE	= CurrState;
	  
endmodule
