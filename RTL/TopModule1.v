`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       Pavel Abrosimov
//
// Create Date:    14:12:25 03/15/2014
// Design Name:
// Module Name:    TopModule1
// Project Name:
// Target Devices:
// Tool versions:  Xilinx ISE 12.4 Linux 32bit (Fedora 20)
// Description:    Top module for VGA and CPU implementation
//          Feature CPU, Timer and VGA blocks
//          Instruction in CPU modify colour register in VGA_Wrapper module
//          once a second via an interrupt from the Timer
//
// Dependencies:   input clock CLK of 50MHz
//          Modules: RAM, ROM, CPU, Timer and VGA_Wrapper
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module TopModule1(
    CLK,
    RESET,

    COLOUR_OUT,
    HS_OUT,
    VS_OUT
    );

    input CLK;
    input RESET;

    output [7:0] COLOUR_OUT;
    output       HS_OUT;
    output       VS_OUT;

    wire [7:0] ROM_DATA;
    wire [7:0] ROM_ADDR;

    wire [7:0] RAM_BUS_DATA;
    wire [7:0] RAM_BUS_ADDR;
    wire       RAM_BUS_WE;

    wire Timer_IRQ;
    wire Timer_IRQ_Ack;
    wire Mouse_IRQ_Ack; // not connected, used for output bus on CPU

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
             .BUS_INTERRUPTS_RAISE({Timer_IRQ, 1'b0}),
             .BUS_INTERRUPTS_ACK({Timer_IRQ_Ack,Mouse_IRQ_Ack})
             );

    VGA_Wrapper vga(.CLK(CLK),
                    .RESET(RESET),
                    .BUS_ADDR(RAM_BUS_ADDR),
                    .BUS_DATA(RAM_BUS_DATA),
                    .BUS_WE(RAM_BUS_WE),
                    .COLOUR_OUT(COLOUR_OUT),
                    .HS_OUT(HS_OUT),
                    .VS_OUT(VS_OUT)
                    );

    Timer timer0(.CLK(CLK),
              .RST(RESET),
              .BUS_ADDR(RAM_BUS_ADDR),
              .BUS_DATA(RAM_BUS_DATA),
              .BUS_WE(RAM_BUS_WE),
              .BUS_INTERRUPT_ACK(Timer_IRQ_Ack),
              .BUS_INTERRUPT_RAISE(Timer_IRQ)
              );

endmodule
