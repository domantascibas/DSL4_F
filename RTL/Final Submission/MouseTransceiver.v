`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Domantas Cibas
// 
// Create Date:    11:50:46 02/11/2014 
// Design Name: Digital Design Lab 4
// Module Name:    MouseTransceiver 
// Project Name: PS2 Mouse Interface
// Target Devices: Basys 2
// Tool versions: 
// Description: This is the top module in the PS2 Mouse Interface project.
//	Other three modules are: MouseTransmitter, MouseReceiver and MouseMasterSM.
//
// Dependencies: 
//					MouseTransmitter.v,
//					MouseReceiver.v,
//					MouseMasterSM.v
//					(also the icon and ila files if ChipScope has to be used)
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module MouseTransceiver(
	//Standard Inputs
	input CLK,
	input RESET,
	
	// Mouse data information
	inout				[7:0]			BUS_DATA,
	input				[7:0]			BUS_ADDR,
	input								BUS_WE,
	output	reg					BUS_INTERRUPT_RAISE,
	input								BUS_INTERRUPT_ACK,
	//IO - Mouse side
	inout								CLK_MOUSE,	
	inout								DATA_MOUSE
    );

	parameter [7:0] 	MouseBaseAddr 	= 8'hA0;

	// X, Y Limits of Mouse Position e.g. VGA Screen with 160 x 120 resolution
	parameter [7:0] MouseLimitX = 160;
	parameter [7:0] MouseLimitY = 120;

/////////////////////////////////////////////////////////////////////
//TriState Signals
//Clk
reg ClkMouseIn;
wire ClkMouseOutEnTrans;

//Data
wire DataMouseIn;
wire DataMouseOutTrans;
wire DataMouseOutEnTrans;

//Clk Output - can be driven by host or device
assign CLK_MOUSE = ClkMouseOutEnTrans ? 1'b0 : 1'bz;

//Clk Input
assign DataMouseIn = DATA_MOUSE;

//Clk Output - can be driven by host or device
assign DATA_MOUSE = DataMouseOutEnTrans ? DataMouseOutTrans : 1'bz;

/////////////////////////////////////////////////////////////////////
//This section filters the incoming Mouse clock to make sure that
//it is stable before data is latched by either transmitter
//or receiver modules

reg [7:0] MouseClkFilter;

always@(posedge CLK) begin
	if(RESET)
		ClkMouseIn <= 1'b0;
	else begin
		//A simple shift register
		MouseClkFilter[7:1] <= MouseClkFilter[6:0];
		MouseClkFilter[0] <= CLK_MOUSE;
		//falling edge
		if(ClkMouseIn & (MouseClkFilter == 8'h00))
			ClkMouseIn <= 1'b0;
		//rising edge
		else if(~ClkMouseIn & (MouseClkFilter == 8'hFF))
			ClkMouseIn <= 1'b1;
	end
end

///////////////////////////////////////////////////////
//Instantiate the Transmitter module
wire SendByteToMouse;
wire ByteSentToMouse;
wire [7:0] ByteToSendToMouse;

MouseTransmitter T(
	//Standard Inputs
	.RESET (RESET),
	.CLK(CLK),
	//Mouse IO - CLK
	.CLK_MOUSE_IN(ClkMouseIn),
	.CLK_MOUSE_OUT_EN(ClkMouseOutEnTrans),
	//Mouse IO - DATA
	.DATA_MOUSE_IN(DataMouseIn),
	.DATA_MOUSE_OUT(DataMouseOutTrans),
	.DATA_MOUSE_OUT_EN (DataMouseOutEnTrans),
	//Control
	.SEND_BYTE(SendByteToMouse),
	.BYTE_TO_SEND(ByteToSendToMouse),
	.BYTE_SENT(ByteSentToMouse)
);

///////////////////////////////////////////////////////
//Instantiate the Receiver module
wire ReadEnable;
wire [7:0] ByteRead;
wire [1:0] ByteErrorCode;
wire ByteReady;

MouseReceiver R(
	//Standard Inputs
	.RESET(RESET),
	.CLK(CLK),
	//Mouse IO - CLK
	.CLK_MOUSE_IN(ClkMouseIn),
	//Mouse IO - DATA
	.DATA_MOUSE_IN(DataMouseIn),
	//Control
	.READ_ENABLE (ReadEnable),
	.BYTE_READ(ByteRead),
	.BYTE_ERROR_CODE(ByteErrorCode),
	.BYTE_READY(ByteReady)
);

///////////////////////////////////////////////////////
//Instantiate the Master State Machine module
wire [7:0] MouseStatusRaw;
wire [7:0] MouseDxRaw;
wire [7:0] MouseDyRaw;
wire SendInterrupt;
wire [3:0] Master_State_code;
wire [4:0] STATE;

assign STATE = {1'b0, Master_State_code};

MouseMasterSM MSM(
	//Standard Inputs
	.RESET(RESET),
	.CLK(CLK),
	//Transmitter Interface
	.SEND_BYTE(SendByteToMouse),
	.BYTE_TO_SEND(ByteToSendToMouse),
	.BYTE_SENT(ByteSentToMouse),
	//Receiver Interface
	.READ_ENABLE (ReadEnable),
	.BYTE_READ(ByteRead),
	.BYTE_ERROR_CODE(ByteErrorCode),
	.BYTE_READY(ByteReady),
	//Data Registers
	.MOUSE_STATUS(MouseStatusRaw),
	.MOUSE_DX(MouseDxRaw),
	.MOUSE_DY(MouseDyRaw),
	.SEND_INTERRUPT(SendInterrupt),
	.CURRENT_STATE(Master_State_code)
);

/*
//Instantiate Softcore for ChipScope

wire [35:0] control_bus;

icon i_icon(
	.CONTROL0(control_bus)
);

ila i_ila(
	.CONTROL(control_bus),
	.CLK(CLK_MOUSE),
	.TRIG0(DATA_MOUSE),
	.TRIG1(RESET),
	.TRIG2(STATE),
	.TRIG3(ByteToSendToMouse),
	.TRIG4(ByteRead)
);
*/

//Pre-processing - handling of overflow and signs.
//More importantly, this keeps tabs on the actual X/Y
//location of the mouse.
reg [7:0] MouseStatus;
reg signed [7:0] MouseX;
reg signed [7:0] MouseY;
wire signed [8:0] MouseDx;
wire signed [8:0] MouseDy;
wire signed [8:0] MouseNewX;
wire signed [8:0] MouseNewY;

//DX and DY are modified to take account of overflow and direction
assign MouseDx = (MouseStatusRaw[6]) ? (MouseStatusRaw[4] ? {MouseStatusRaw[4],8'h00} : {MouseStatusRaw[4],8'hFF} ) : {MouseStatusRaw[4],MouseDxRaw[7:0]};
assign MouseDy = (MouseStatusRaw[7]) ? (MouseStatusRaw[5] ? {MouseStatusRaw[5],8'h00} : {MouseStatusRaw[5],8'hFF} ) : {MouseStatusRaw[5],MouseDyRaw[7:0]};

// calculate new mouse position
assign MouseNewX = {1'b0,MouseX} + MouseDx;
assign MouseNewY = {1'b0,MouseY} + ~MouseDy+1; //change to '-' if (0;0) at the top.

always@(posedge CLK) begin
	if(RESET) begin
		//Set mouse position to the middle of the screen upon RESET
		MouseStatus <= 0;
		MouseX <= MouseLimitX/2;
		MouseY <= MouseLimitY/2;
	end else if (SendInterrupt) begin
		MouseStatus <= MouseStatusRaw[7:0];
		//X is modified based on DX with limits on max and min
		if(MouseNewX < 0)
			MouseX <= 0;
		else if(MouseNewX > (MouseLimitX-1))
			MouseX <= MouseLimitX-1;
		else
			MouseX <= MouseNewX[7:0];
		//Y is modified based on DY with limits on max and min
		if(MouseNewY < 0)
			MouseY <= 0;
		else if(MouseNewY > (MouseLimitY-1))
			MouseY <= MouseLimitY-1;
		else
			MouseY <= MouseNewY[7:0];
	end
end

//Tristate bus read controler
	reg TransmitStatus;
	reg TransmitDx;
	reg TransmitDy;
	
	//If the mouse peripheral is targeted, and WriteEnable is low
	//then, we can transmit data from MOUSE to the BUS_DATA line
	always@(posedge CLK) begin
		if((BUS_ADDR == MouseBaseAddr) & ~BUS_WE) 
			TransmitStatus	<= 1'b1;
		else
			TransmitStatus	<= 1'b0;
			
		if((BUS_ADDR == MouseBaseAddr + 1) & ~BUS_WE) 
			TransmitDx	<= 1'b1;
		else
			TransmitDx	<= 1'b0;

		if((BUS_ADDR == MouseBaseAddr + 2) & ~BUS_WE) 
			TransmitDy	<= 1'b1;
		else
			TransmitDy	<= 1'b0;
	end
	
	assign BUS_DATA 	= (TransmitStatus) 	? {4'b0000, MouseStatus} 	: 8'hZZ;	
	assign BUS_DATA 	= (TransmitDx) 		? MouseX[7:0]					: 8'hZZ;	
	assign BUS_DATA 	= (TransmitDy) 		? MouseY[7:0]					: 8'hZZ;	
	
	//Interrupt Handling
	always@(posedge CLK) begin
		if(RESET)
			BUS_INTERRUPT_RAISE <= 1'b0;
		else if(SendInterrupt)
			BUS_INTERRUPT_RAISE <= 1'b1;
		else if(BUS_INTERRUPT_ACK)
			BUS_INTERRUPT_RAISE <= 1'b0;
	end	

endmodule
