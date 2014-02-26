`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       Pavel Abrosimov
//
// Create Date:    13:41:31 02/02/2014
// Design Name:    Two port Frame Buffer
// Module Name:    Frame_Buffer
// Project Name:   VGA
// Target Devices:
// Tool versions:  ISE 12.4 Linux 32bit, Fedora 20
// Description:    two port memory frame buffer
//     Frame buffer is 160x120 of size, 1 bit ber pixel
//
//     Port A: Read/Write
//     A_DATA_IN sets the colour of the pixel selected
//     with A_ADDR: concatenated Addr_X (8bit) and Addr_Y(7bit) if A_WE asserted,
//     Value is read from A_DATA_OUT
//     A_ADDR[7:0]  - Addr_X
//     A_ADDR[14:8] - Addr_Y
//
//     Port B: Read
//     Pixel colour is returned in B_DATA_OUT selected
//     with B_ADDR: concatenated Addr_X (8bit) and Addr_Y(7bit)
//     B_ADDR[7:0]  - Addr_X
//     B_ADDR[14:8] - Addr_Y
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module Frame_Buffer(
    RESET,

    A_CLK,
    A_ADDR,
    A_DATA_IN,
    A_DATA_OUT,
    A_WE,

    B_CLK,
    B_ADDR,
    B_DATA_OUT
    );

    //  Interface

    input        RESET;

    // Port A

    input        A_CLK;
    input [14:0] A_ADDR;
    input        A_DATA_IN;
    output reg   A_DATA_OUT;
    input        A_WE;

    //  Port B

    input        B_CLK;
    input [14:0] B_ADDR;
    output reg   B_DATA_OUT;

    parameter MEM_SIZE = 16'd2**15;

    //  Components

    // FB memory
    reg [0:0] Mem[MEM_SIZE-1:0];

    //  Port A logic: to be used by microprocessor
    always@(posedge A_CLK) begin
        if(A_WE)
            Mem[A_ADDR] <= A_DATA_IN;

        A_DATA_OUT <= Mem[A_ADDR];
    end

    //  Port B logic: used by VGA signal generator
    always@(posedge B_CLK)
        B_DATA_OUT <= Mem[B_ADDR];

    initial begin
        $readmemb("mem.data",Mem);
    end

endmodule
