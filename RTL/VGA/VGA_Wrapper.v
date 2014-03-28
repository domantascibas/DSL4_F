`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       Pavel Abrosimov
//
// Create Date:    17:11:56 03/17/2014
// Design Name:
// Module Name:    VGA_Wrapper
// Project Name:
// Target Devices: 8bit colour output VGA board
// Tool versions:  Xilinx ISE 12.4 Linux 32bit (Fedora 20)
// Description:    Module that abstracts VGA signal generator, Frame Buffer and
//      colour registers. The latter onces are exported for R/W operation via
//      BUS. HIGH_COLOUR_REG_ADDR and LOW_COLOUR_REG_ADDR parameters hold the addresses
//      R/W operation requires 1 clock cycle
//
// Dependencies: input clock 50MHz
//      modules: Frame_Buffer, VGA_Sig_Gen
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module VGA_Wrapper(
    CLK,
    RESET,

    BUS_ADDR,
    BUS_DATA,
    BUS_WE,

    COLOUR_OUT,
    HS_OUT,
    VS_OUT
    );

    input CLK;
    input RESET;

    input [7:0] BUS_ADDR;
    inout [7:0] BUS_DATA;
    input       BUS_WE;

    output [7:0] COLOUR_OUT;
    output       HS_OUT;
    output       VS_OUT;

    // Components

    wire [7:0] BufferedBusData;
    reg  [7:0] Out;
    reg        RAMBusWE;

    wire        FB_B_CLK;
    wire [14:0] FB_B_ADDR;
    wire        FB_B_DATA;

    reg [7:0] Colours [1:0]; // two 8bit registers to hold colours

    reg [14:0] FB_ADDR_REG;
    reg        FB_DATA_IN;
    wire       FB_DATA_OUT;
    reg        FB_WE;


    assign BUS_DATA = (RAMBusWE) ? Out : 8'hZZ;
    assign BufferedBusData = BUS_DATA;

    parameter HIGH_COLOUR_REG_ADDR  = 8'hB0; // address for the register that holds colour that is used for drawing (1)
    parameter LOW_COLOUR_REG_ADDR   = 8'hB1; // address for the register that holds colour that is used for drawing (0)
    parameter HIGH_ADDR_FB_REG_ADDR = 8'hB2;
    parameter LOW_ADDR_FB_REG_ADDR  = 8'hB3;
    parameter FB_DATA_REG_ADDR      = 8'hB4;

    Frame_Buffer fb(.RESET(RESET),
                    // No using this port A this time
                    .A_CLK(CLK),
                    .A_ADDR(FB_ADDR_REG),
                    .A_DATA_IN(FB_DATA_IN),
                    .A_DATA_OUT(FB_DATA_OUT),
                    .A_WE(FB_WE),

                    // port B - controlled by VGA_Sig_Gen
                    .B_CLK(FB_B_CLK),
                    .B_ADDR(FB_B_ADDR),
                    .B_DATA_OUT(FB_B_DATA)
                    );


    VGA_Sig_Gen sigGen(.CLK(CLK),
                       .RESET(RESET),
                       .CONFIG_COLOURS({Colours[0], Colours[1]}),
                       .VGA_HS(HS_OUT),
                       .VGA_VS(VS_OUT),
                       .VGA_COLOUR(COLOUR_OUT),
                       .MEM_CLK(FB_B_CLK),
                       .MEM_ADDR(FB_B_ADDR),
                       .MEM_DATA(FB_B_DATA)
                       );

    always@(posedge CLK)begin
        if(RESET) begin
            FB_ADDR_REG <= 15'd0;
            FB_DATA_IN <= 0;
            Out <= 8'h00;
        end else if((BUS_ADDR == HIGH_COLOUR_REG_ADDR) || (BUS_ADDR == LOW_COLOUR_REG_ADDR)) begin
            Out <= Colours[BUS_ADDR & 8'h01];

            if(BUS_WE) begin
                Colours[BUS_ADDR & 8'h01] <= BufferedBusData;
                RAMBusWE <= 1'b0;
            end else
                RAMBusWE <= 1'b1;
        end else if(BUS_ADDR == HIGH_ADDR_FB_REG_ADDR) begin
            Out <= FB_ADDR_REG[14:8];

            if(BUS_WE) begin
                FB_ADDR_REG[14:8] <= BufferedBusData[6:0];
                RAMBusWE <= 1'b0;
            end else
                RAMBusWE <= 1'b1; // place value to the bus
        end else if(BUS_ADDR == LOW_ADDR_FB_REG_ADDR) begin
            Out <= FB_ADDR_REG[7:0];

            if(BUS_WE) begin
                FB_ADDR_REG[7:0] <= BufferedBusData;
                RAMBusWE <= 1'b0;
            end else
                RAMBusWE <= 1'b1; // place value to the bus
        end else if(BUS_ADDR == FB_DATA_REG_ADDR) begin
            Out <= FB_DATA_OUT;

            if(BUS_WE) begin
                FB_DATA_IN <= BufferedBusData & 1; // LSB is the actual data
                RAMBusWE <= 1'b0;
            end else
                RAMBusWE <= 1'b1; // place value to the bus
        end else begin
            RAMBusWE <= 1'b0; // don't write to bus if address doesn't belong to the HW
            Out <= Out;
        end
    end

    always@(posedge CLK) begin
        if(RESET)
            FB_WE <= 0;
        else if((BUS_ADDR == FB_DATA_REG_ADDR) && BUS_WE)
            FB_WE <= 1;
        else
            FB_WE <= 0;
    end

    initial begin
        Colours[0] = 8'had;
        Colours[1] = 8'h00;
    end

endmodule
