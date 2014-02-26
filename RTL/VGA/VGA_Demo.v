`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       Pavel Abrosimov
//
// Create Date:    19:54:29 02/03/2014
// Design Name:    Demonstration of VGA signal generator with framebuffer
// Module Name:    VGA_Demo
// Project Name:   VGA
// Target Devices: Basys2
// Tool versions:  Xilinx ISE 12.4 Linux 32bit (Fedora 20)
// Description:    Top level module for the VGA project
//    Demonstrates operation of the VGA signal generator and VGA framebuffer
//
//    Draws chequered image, changing colours every one second
//
// Dependencies: VGA_Sig_Gen, Frame_Buffer and GenericCounter modules
//      Requires 50MHz clock
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module VGA_Demo(
    CLK,
    RESET,

    COLOUR_OUT,
    HS_OUT,
    VS_OUT
    );

    input        CLK;
    input        RESET;

    output [7:0] COLOUR_OUT;
    output       HS_OUT;
    output       VS_OUT;

    reg         FB_A_DATA;

    wire        FB_B_CLK;
    wire [14:0] FB_B_ADDR;
    wire        FB_B_DATA;

    wire        CLK_1Hz;
    wire  [7:0] active_colour;


    always@(posedge CLK or posedge RESET) begin
        if(RESET)
            FB_A_DATA <= 0;
        else
            FB_A_DATA <= ~FB_A_DATA;
    end

    //
    VGA_Sig_Gen vga_sig(.CLK(CLK),
                    .RESET(RESET),
                    .CONFIG_COLOURS({active_colour, 8'hFF}),
                    .VGA_HS(HS_OUT),
                    .VGA_VS(VS_OUT),
                    .VGA_COLOUR(COLOUR_OUT),
                    .MEM_CLK(FB_B_CLK),
                    .MEM_ADDR(FB_B_ADDR),
                    .MEM_DATA(FB_B_DATA)
                    );

    // counter to generate 1Hz clock
    GenericCounter #(.COUNTER_WIDTH(26), .COUNTER_MAX(50_000_000))
                s_counter(.CLK(CLK),
                            .RESET(RESET),
                            .ENABLE_IN(1'b1),
                            .NEG_DIR_IN(1'b0),
                            .TRIGG_OUT(CLK_1Hz)
                            );

    // 8bit counter that is incremented every second, count is used as colour
    GenericCounter #(.COUNTER_WIDTH(8), .COUNTER_MAX(255))
                colour_counter(.CLK(CLK),
                            .RESET(RESET),
                            .ENABLE_IN(CLK_1Hz),
                            .NEG_DIR_IN(1'b0),
                            .COUNT(active_colour)
                            );

    // framebuffer component
    Frame_Buffer fb(.RESET(RESET),
                    .A_CLK(CLK),
                    .A_ADDR(15'b0),
                    .A_DATA_IN(1'b0),
                    .A_WE(1'b0),
                    .B_CLK(FB_B_CLK),
                    .B_ADDR(FB_B_ADDR),
                    .B_DATA_OUT(FB_B_DATA)
                    );

endmodule
