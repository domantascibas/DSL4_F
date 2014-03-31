`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       Pavel Abrosimov
//
// Create Date:    14:44:48 02/02/2014
// Design Name:    VGA signal generator
// Module Name:    VGA_Sig_Gen
// Project Name:   VGA
// Target Devices: Basys2 board
// Tool versions:  Xilinx ISE 12.4 32bit Linux (Fedora 20)
// Description:    VGA signal generator with access to framebuffer memory
//          Requests data from framebuffer at 25MHz frequency
//          For the correct operation requires delay of 1 CLK for data access
//          Implements 640x480 VGA resolution
//
// Dependencies:   GenericCounter module
//              input CLK is 50MHz
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module VGA_Sig_Gen(
    CLK,
    RESET,

    CONFIG_COLOURS,

    VGA_HS,
    VGA_VS,
    VGA_COLOUR,

    MEM_CLK,
    MEM_ADDR,
    MEM_DATA
    );

    input         CLK;
    input         RESET;

    input [15:0]  CONFIG_COLOURS;

    output reg    VGA_HS;
    output reg    VGA_VS;
    output reg [7:0]  VGA_COLOUR;

    output        MEM_CLK;
    output [14:0] MEM_ADDR;
    input         MEM_DATA;

    wire       CLK25;  // 25MHz clock

    wire [9:0] verCntVal;
    wire [9:0] horCntVal;
    wire       horTrigWire;

    /*
    Define VGA signal parameters e.g. Horizontal and Vertical display time, pulse widths, front and back
    porch widths etc.
    */

    // Time in Vertical Lines
    parameter VertTimeToPulseWidthEnd   = 10'd2;
    parameter VertTimeBackPorchWidth    = 10'd29;
    parameter VertTimeToBackPorchEnd    = VertTimeToPulseWidthEnd + VertTimeBackPorchWidth;   // = 10'd31;
    parameter VertNumOfActiveLines      = 10'd480;
    parameter VertTimeToDisplayTimeEnd  = VertNumOfActiveLines + VertTimeToBackPorchEnd;      // = 10'd511;
    parameter VertNumOfFrontPorchLines  = 10'd10;
    parameter VertTimeToFrontPorchEnd   = VertTimeToDisplayTimeEnd + VertNumOfFrontPorchLines;// = 10'd521;

    // Time in Horizontal Lines
    parameter HorzTimeToPulseWidthEnd   = 10'd96;
    parameter HorzBackPorchClocks       = 10'd48;
    parameter HorzTimeToBackPorchEnd    = HorzTimeToPulseWidthEnd + HorzBackPorchClocks;   // = 10'd144;
    parameter HorzNumOfActiveLines      = 10'd640;
    parameter HorzTimeToDisplayTimeEnd  = HorzTimeToBackPorchEnd + HorzNumOfActiveLines;   // = 10'd784;
    parameter HorzFrontPorchClocks      = 10'd16;
    parameter HorzTimeToFrontPorchEnd   = HorzFrontPorchClocks + HorzTimeToDisplayTimeEnd; // = 10'd800;

    // VGA clock of 25MHz - half the 50MHz input clock
    GenericCounter #(.COUNTER_WIDTH(1), .COUNTER_MAX(1))
                    clk_counter(.CLK(CLK),
                                .RESET(RESET),
                                .ENABLE_IN(1'b1),
                                .NEG_DIR_IN(1'b0),
                                .TRIGG_OUT(CLK25)
                                );

    GenericCounter #(.COUNTER_WIDTH(10), .COUNTER_MAX(HorzTimeToFrontPorchEnd - 1))
                    hor_counter(.CLK(CLK),
                                .RESET(RESET),
                                .ENABLE_IN(CLK25),
                                .NEG_DIR_IN(1'b0),
                                .COUNT(horCntVal),
                                .TRIGG_OUT(horTrigWire)
                                );

    GenericCounter #(.COUNTER_WIDTH(10), .COUNTER_MAX(VertTimeToFrontPorchEnd - 1))
                     ver_counter(.CLK(CLK),
                                 .RESET(RESET),
                                 .ENABLE_IN(horTrigWire),
                                 .NEG_DIR_IN(1'b0),
                                 .COUNT(verCntVal)
                                 );

    assign MEM_CLK = CLK25;
    assign MEM_ADDR = {verCntVal[8:2], horCntVal[9:2]};

    // Color output logic

    always@(*) begin
        if ((verCntVal > (VertTimeToBackPorchEnd - 1)) && (verCntVal < VertTimeToDisplayTimeEnd) && (horCntVal > (HorzTimeToBackPorchEnd)) && (horCntVal <= HorzTimeToDisplayTimeEnd))
        begin
            // inside drawing area - resolve colour
            if(MEM_DATA)
                VGA_COLOUR <= CONFIG_COLOURS[15:8];
            else
                VGA_COLOUR <= CONFIG_COLOURS[7:0];
        end
        else
            VGA_COLOUR <= 8'd0;
    end

    // VS/HS signals logic

    always@(posedge CLK) begin
        if(verCntVal < VertTimeToPulseWidthEnd)
            VGA_VS = 0;
        else
            VGA_VS = 1;
    end

    always@(posedge CLK) begin
        if(horCntVal < HorzTimeToPulseWidthEnd)
            VGA_HS <= 0;
        else
            VGA_HS <= 1;
    end

endmodule
