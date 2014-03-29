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
//     Port A: 8bit Read/Write
//     A_DATA_IN sets the colour of 8 pixel selected
//     with A_ADDR:
//      concatenated Addr_X (8bit) and Addr_Y(7bit) if A_WE asserted,
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
// Revision 0.02 - 0.01 : port A widen to 8bit
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

    input            A_CLK;
//    input     [11:0] A_ADDR;
    input     [14:0] A_ADDR;
    input      [7:0] A_DATA_IN;
    output reg [7:0] A_DATA_OUT;
    input            A_WE;

    //  Port B

    input        B_CLK;
    input [14:0] B_ADDR;
    output reg   B_DATA_OUT;

    parameter MEM_SIZE = 16'd2**15;

    //  Components

    // FB memory
//    reg [0:0] Mem[MEM_SIZE-1:0];
    reg [7:0] Mem[(MEM_SIZE/8)-1:0];
/*
    wire [14:0] a_addr_full;
    assign a_addr_full = {A_ADDR, 3'b000};
*/
    //  Port A logic: to be used by microprocessor
    always@(posedge A_CLK) begin
        if(A_WE) begin
        /*
            Mem[A_ADDR    ] <= A_DATA_IN[0];
            Mem[A_ADDR + 1] <= A_DATA_IN[1];
            Mem[A_ADDR + 2] <= A_DATA_IN[2];
            Mem[A_ADDR + 3] <= A_DATA_IN[3];
            Mem[A_ADDR + 4] <= A_DATA_IN[4];
            Mem[A_ADDR + 5] <= A_DATA_IN[5];
            Mem[A_ADDR + 6] <= A_DATA_IN[6];
            Mem[A_ADDR + 7] <= A_DATA_IN[7];
        */
            Mem[A_ADDR[14:3]] <= A_DATA_IN;
        end
        /*
        A_DATA_OUT <= {Mem[A_ADDR + 7],
                       Mem[A_ADDR + 6],
                       Mem[A_ADDR + 5],
                       Mem[A_ADDR + 4],
                       Mem[A_ADDR + 3],
                       Mem[A_ADDR + 2],
                       Mem[A_ADDR + 1],
                       Mem[A_ADDR    ]};
        */
        A_DATA_OUT <= Mem[A_ADDR[14:3]];
    end

    //  Port B logic: used by VGA signal generator
    always@(posedge B_CLK)
        B_DATA_OUT <= Mem[B_ADDR[14:3]][B_ADDR[2:0]];

    initial begin
        $readmemb("mem.data",Mem);
    end

endmodule
