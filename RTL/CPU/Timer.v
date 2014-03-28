`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    11:10:08 03/11/2014
// Design Name:
// Module Name:    Timer
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
module Timer(
	//Standard Signals
	input CLK,
	input RST,
	//Bus Signals
	input [7:0] BUS_ADDR,
	inout [7:0] BUS_DATA,
	input BUS_WE,
	//Interrupt Signals
	input BUS_INTERRUPT_ACK,
	output BUS_INTERRUPT_RAISE
   );

	parameter [7:0]	TimerBaseAddr				= 8'hF0;		//Timer base address in memory map
	parameter			InitialInterruptRate		= 100;		//Default interrupt rate is one interrupt signal every 100 ms.
	parameter			InitialInterruptEnable	= 1'b1;		//By default, interrupt is enabled

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/*	BaseAddr + 0 --> Reports current timer value.
		BaseAddr + 1 --> Address of a timer interrupt interval register (100ms by default).
		BaseAddr + 2 --> Resets the timer, restart counting from 0.
		BaseAddr + 3 --> Address of an interrupt enable register (allows the microprocessor to disable the timer.

		This module will raise an interrupt flag when the designated time is up. It will automatically set the time of
		the next interrupt to the time of the last interrupt plus a configurable value (in ms). */

	//Interrupt Rate Configuration - The rate is initialised to 100 by the parameter above, but can also be set by the
	//microprocessor by writing to memory address BaseAddr + 1.
	reg [7:0] interrupt_rate[1:0];

	wire [15:0] complete_rate;

	assign complete_rate = {interrupt_rate[1], interrupt_rate[0]};

	reg [7:0] buff_bus_data;
	reg [7:0] Out;
	reg [31:0] timer;

	reg state_counter;
	parameter idle_state = 0;
	parameter high_written = 1;

	always@(posedge CLK) begin
	    if(BUS_WE)
	        buff_bus_data <= BUS_DATA;
	end


	always @ (posedge CLK) begin
		if (RST) begin
			interrupt_rate[0] <= InitialInterruptRate;
			interrupt_rate[1] <= 0;
			state_counter <= idle_state;
	    end
		else if ((BUS_ADDR == TimerBaseAddr + 8'h04) & BUS_WE) begin
			//interrupt_rate <= BUS_DATA;
			if(state_counter == idle_state)
			    state_counter <= high_written;
		end else if((BUS_ADDR == TimerBaseAddr + 8'h05) & BUS_WE) begin
		    if(state_counter == high_written) begin
		        // we have both bytes => we can commit
			    state_counter <= idle_state;
			    interrupt_rate[1] <= buff_bus_data;
			    interrupt_rate[0] <= BUS_DATA;
			end
        end
    end

    always@(posedge CLK) begin
        if((BUS_ADDR == TimerBaseAddr + 8'h04) & (BUS_WE == 1'b0))
            Out <= interrupt_rate[1];
        else if((BUS_ADDR == TimerBaseAddr + 8'h05) & (BUS_WE == 1'b0))
            Out <= interrupt_rate[0];
        else
            Out <= timer[7:0];
    end


	//Interrupt Enable Configuration - If this is not set to 1 then no interrupts will be created.
	reg interrupt_en;

	always @ (posedge CLK) begin
		if (RST)
			interrupt_en <= InitialInterruptEnable;
		else if ((BUS_ADDR == TimerBaseAddr + 8'h03) & BUS_WE)
			interrupt_en <= BUS_DATA[0];
		end

	//First we must lower the clock speed from 50MHz to 1kHz (1ms period).
	reg [31:0] down_counter;

	always @ (posedge CLK) begin
		if (RST)
			down_counter <= 1'b0;
		else begin
			if (down_counter == 32'd49999)
				down_counter <= 32'd0;
			else
				down_counter <= down_counter + 1;
			end
		end

	//Now we can record the last time an interrupt was sent, and add a value to it to determine if is time to raise
	//the interrupt.

	always @ (posedge CLK) begin
		if (RST | (BUS_ADDR == TimerBaseAddr + 8'h02))
			timer <= 32'd0;
		else begin
			if (down_counter == 32'd0)
				timer <= timer + 1;
			else
				timer <= timer;
			end
		end

	//Interrupt Generation
	reg target_reached;
	reg [31:0] last_time;

	always @ (posedge CLK) begin
		if (RST) begin
			target_reached <= 1'b0;
			last_time <= 32'd0;
			end
		else if ((last_time + complete_rate) == timer) begin
			if (interrupt_en)
				target_reached <= 1'b1;
			last_time <= timer;
			end
		else
			target_reached <= 1'b0;
		end

	//Broadcast the interrupt
	reg interrupt;

	always @ (posedge CLK) begin
		if (RST)
			interrupt <= 1'b0;
		else if (target_reached)
			interrupt <= 1'b1;
		else if (BUS_INTERRUPT_ACK)
			interrupt <= 1'b0;
		end

	assign BUS_INTERRUPT_RAISE = interrupt;

	//Tristate output for interrupt timer output value
	reg transmit_timer_value;

	always @ (posedge CLK) begin
		if ((BUS_ADDR == TimerBaseAddr) || (BUS_ADDR == (TimerBaseAddr + 8'h04)) || (BUS_ADDR == (TimerBaseAddr + 8'h05)))
			transmit_timer_value <= 1'b1;
		else
			transmit_timer_value <= 1'b0;
		end

//	assign BUS_DATA = (transmit_timer_value) ? timer[7:0]:8'hZZ;
    assign BUS_DATA = (transmit_timer_value) ? Out:8'hZZ;

endmodule
