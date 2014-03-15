`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    14:12:25 03/15/2014
// Design Name:
// Module Name:    TopModule
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
module TopModule1(
    CLK,
    RESET,
    IQR_RAISE,
    IRQ_ACK
    );

    input CLK;
    input RESET;

    input [1:0] IQR_RAISE;
    output [1:0] IRQ_ACK;

    wire [7:0] ROM_DATA;
    wire [7:0] ROM_ADDR;

    wire [7:0] RAM_BUS_DATA;
    wire [7:0] RAM_BUS_ADDR;
    wire       RAM_BUS_WE;

    RAM ram0(.CLK(CLK),
             .BUS_DATA(RAM_BUS_DATA),
             .BUS_ADDR(RAM_BUS_ADDR),
             .BUS_WE(RAM_BUS_WE)
             );

    ROM rom0(.CLK(CLK),
             .DATA(ROM_DATA),
             .ADDR(ROM_ADDR)
             );

    CPU cpu0(.CLK(CLK),
             .RESET(RESET),
             .BUS_DATA(RAM_BUS_DATA),
             .BUS_ADDR(RAM_BUS_ADDR),
             .BUS_WE(RAM_BUS_WE),
             .ROM_ADDRESS(ROM_ADDR),
             .ROM_DATA(ROM_DATA),
             .BUS_INTERRUPTS_RAISE(IQR_RAISE),
             .BUS_INTERRUPTS_ACK(IRQ_ACK)
             );


endmodule
