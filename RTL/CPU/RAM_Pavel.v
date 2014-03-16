`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:17:29 03/14/2014 
// Design Name: 
// Module Name:    RAM 
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
module RAM(
    CLK,
    BUS_DATA,
    BUS_ADDR,
    BUS_WE
    );

    input CLK;
    inout [7:0] BUS_DATA;   //  8bit in/out RAM data
    input [7:0] BUS_ADDR;   //  8bit address
    input       BUS_WE;     //  Write enable

    parameter RAMBaseAddr  = 0;
    parameter RAMAddrWidth = 7; // 128 x 8-bits memory; high memory reserved for RAM mapped HW
    parameter RAMAddrMask  = 128 - 1; // Since RAMBaseAddr is 0

    // Components

    wire [7:0] BufferedBusData;
    reg  [7:0] Out;
    reg        RAMBusWE;

    //Only place data on the bus if the processor is NOT writing, and it is addressing this memory

    assign BUS_DATA = (RAMBusWE) ? Out : 8'hZZ;
    assign BufferedBusData = BUS_DATA;

    // Memory

    reg [7:0] Mem[2**RAMAddrWidth-1:0];
    // Initialise the memory for data preloading, initialising variables, and declaring constants
    initial $readmemh("Complete_Demo_RAM.txt", Mem);

    //single port RAM logic

    always@(posedge CLK) begin
        if((BUS_ADDR & (~RAMAddrMask)) == 8'd0) begin
            if(BUS_WE) begin
                Mem[BUS_ADDR[6:0]] <= BufferedBusData;
                RAMBusWE <= 1'b0;
            end else
                RAMBusWE <= 1'b1;
        end else
            RAMBusWE <= 1'b0;

        Out <= Mem[BUS_ADDR[6:0]];
    end

endmodule
