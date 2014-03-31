`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       Pavel Abrosimov
//
// Create Date:    22:08:52 03/06/2014
// Design Name:    ROM
// Module Name:    ROM
// Project Name:
// Target Devices:
// Tool versions:  Xilinx ISE 12.4 Linux 32bit (Fedora 20)
// Description:    single port 256bit ROM module, 8bit address
//      Stores application instructions
//      Requires Complete_Demo_ROM.txt file next to the module,
//      that stores instructions in hex form
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module ROM(
    CLK,
    DATA,
    ADDR
    );

    input            CLK;
    output reg [7:0] DATA;
    input      [7:0] ADDR;

    parameter RAMAddrWidth = 8;

    // Memory
    reg [7:0] ROM [2**RAMAddrWidth-1:0];

    // Load program
    initial $readmemh("Complete_Demo_ROM.txt", ROM);

    // Single port logic
    always@(posedge CLK)
        DATA <= ROM[ADDR];

endmodule
