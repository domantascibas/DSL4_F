`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    23:00:03 03/06/2014
// Design Name:
// Module Name:    CPU
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
module CPU(
    CLK,
    RESET,

    BUS_DATA,
    BUS_ADDR,
    BUS_WE,

    ROM_ADDRESS,
    ROM_DATA,

    BUS_INTERRUPTS_RAISE,
    BUS_INTERRUPTS_ACK
    );

    input CLK;
    input RESET;

    // BUS signals

    inout  [7:0] BUS_DATA;
    output [7:0] BUS_ADDR;
    output       BUS_WE;

    // ROM signals

    output [7:0] ROM_ADDRESS;
    input  [7:0] ROM_DATA;

    // interrupt signals

    input  [1:0] BUS_INTERRUPTS_RAISE;
    output [1:0] BUS_INTERRUPTS_ACK;

    // The main data bus is treated as tristate, so we need a mechanism to handle this
    // Tristate signals that interface with the main state machine
    wire [7:0] BusDataIn;
    reg  [7:0] CurrBusDataOut, NextBusDataOut;
    reg        CurrBusDataOutWE, NextBusDataOutWE;

    // Tristate mechanism
    assign BusDataIn = BUS_DATA;
    assign BUS_DATA  = CurrBusDataOutWE ? CurrBusDataOut : 8'hZZ;
    assign BUS_WE    = CurrBusDataOutWE;

    // Address of the bus
    reg [7:0] CurrBusAddr, NextBusAddr;
    assign BUS_ADDR = CurrBusAddr;

    // The processor has two internal registers to hold data between operations, and a third to hold
    // the current program context when using function calls.
    reg [7:0] CurrRegA, NextRegA;
    reg [7:0] CurrRegB, NextRegB;
    reg       CurrRegSelect, NextRegSelect;
    reg [7:0] CurrProgContext, NextProgContext;

    // Dedicated Interrupt output lines - one for each interrupt line
    reg [1:0] CurrInterruptAck, NextInterruptAck;
    assign BUS_INTERRUPTS_ACK = CurrInterruptAck;

    // Instantiate program memory here
    // There is a program counter which points to the current operation. The program counter
    // has an offset that is used to reference information that is part of the current operation
    reg  [7:0] CurrProgCounter, NextProgCounter;
    reg  [1:0] CurrProgCounterOffset, NextProgCounterOffset;
    wire [7:0] ProgMemoryOut;
    wire [7:0] ActualAddress;
    assign ActualAddress = CurrProgCounter + CurrProgCounterOffset;

    // ROM signals
    assign ROM_ADDRESS = ActualAddress;
    assign ProgMemoryOut = ROM_DATA;

    // Instantiate the ALU
    // The processor has an integrated ALU that can do several different operations
    wire [7:0] AluOut;
    ALU ALU0(.CLK(CLK),
             .RESET(RESET),
             .IN_A(CurrRegA),
             .IN_B(CurrRegB),
             .ALU_Op_Code(ProgMemoryOut[7:4]),
             .OUT_RESULT(AluOut)
             );

    // The microprocessor is essentially a state machine, with one sequential pipeline
    // of states for each operation.
    // The current list of operations is:
    //  0: Read from memory to A
    //  1: Read from memory to B
    //  2: Write to memory from A
    //  3: Write to memory from B
    //  4: Do maths with the ALU, and save result in reg A
    //  5: Do maths with the ALU, and save result in reg B
    //  6: if A (== or < or > B) GoTo ADDR
    //  7: Goto ADDR
    //  8: Go to IDLE
    //  9: End thread, goto idle state and wait for interrupt.
    // 10: Function call
    // 11: Return from function call
    // 12: Dereference A
    // 13: Dereference B

    parameter [7:0] // Program thread selection
    IDLE = 8'hF0,   // Waits here until an interrupt wakes up the processor.
    GET_THREAD_START_ADDR_0 = 8'hF1, // Wait.
    GET_THREAD_START_ADDR_1 = 8'hF2, // Apply the new address to the program counter.
    GET_THREAD_START_ADDR_2 = 8'hF3, // Wait. Goto ChooseOp.

    // Operation selection
    // Depending on the value of ProgMemOut, goto one of the instruction start states.
    CHOOSE_OPP = 8'h00,

    // Data Flow
    READ_FROM_MEM_TO_A     = 8'h10, // Wait to find what address to read, save reg select.
    READ_FROM_MEM_TO_B     = 8'h11, // Wait to find what address to read, save reg select.
    READ_FROM_MEM_0        = 8'h12, // Set BUS_ADDR to designated address.
    READ_FROM_MEM_1        = 8'h13, // wait - Increments program counter by 2. Reset offset.
    READ_FROM_MEM_2        = 8'h14, // Writes memory output to chosen register, end op.

    WRITE_TO_MEM_FROM_A    = 8'h20, // Reads Op+1 to find what address to Write to.
    WRITE_TO_MEM_FROM_B    = 8'h21, // Reads Op+1 to find what address to Write to.
    WRITE_TO_MEM_0         = 8'h22, // wait - Increments program counter by 2. Reset offset.

    // Data Manipulation
    DO_MATHS_OPP_SAVE_IN_A = 8'h30, // The result of maths op. is available, save it to Reg A
    DO_MATHS_OPP_SAVE_IN_B = 8'h31, // The result of maths op. is available, save it to Reg B
    DO_MATHS_OPP_0         = 8'h32, // wait for new op address to settle. end op.

//    IF_A_EQ_B_GOTO_ADDR    = 8'h40, // Branch to address if reg A == reg B
//    IF_A_GREAT_B_GOTO_ADDR = 8'h41, // Branch to address if reg A > reg B
//    IF_A_LESS_B_GOTO_ADDR  = 8'h42, // Branch to address if reg A < reg B
    BRANCH_OPP             = 8'h40, // Opcode for all branch operations is the same, type resolved in ALU
    BRANCH_STAGE_0         = 8'h41, // Take the branch put the address to PC
    BRANCH_STAGE_1         = 8'h42, // wait for new op address to settle. end op.
    GOTO_ADDR              = 8'h43, // goto address
    GOTO_ADDR_0            = 8'h44, // wait for address is available
    GOTO_ADDR_1            = 8'h45, // wait for new op address to settle. end op.
    GOTO_IDLE              = 8'h46, // goto Idle state and wait for IRQ
    FUNCTION_CALL          = 8'h47, // function call at address; save next PC
    FUNCTION_CALL_0        = 8'h48, // wait for address is available
    FUNCTION_CALL_1        = 8'h49, // wait for new op address to settle. end op.
    RETURN                 = 8'h4A, // return from function; load PC from context
    RETURN_0               = 8'h4B, // wait for new op address to settle. end op.

    DEREF_A                = 8'h50, // Indirect mem access through reg A
    DEREF_B                = 8'h51, // Indirect mem access through reg B
	DEREF_1				   = 8'h52,	// wait for the value from RAM to arrive
	DEREF_2				   = 8'h53, // write data from BusDataIn to the correct Reg
	DEREF_3				   = 8'h54,	// wait for new op address to settle. end op.

	LOAD_IMM_A             = 8'h60, // Load immediate to register A
	LOAD_IMM_B             = 8'h61, // Load immediate to register B
	LOAD_IMM_0             = 8'h62, // Wait for value from ROM
	LOAD_IMM_1             = 8'h63; // Wait for next instruction to settle


    // Sequential part of the State Machine.

    reg [7:0] CurrState, NextState;

    always@(posedge CLK) begin
        if(RESET) begin
            CurrState             = 8'h00;
            CurrProgCounter       = 8'h00;
            CurrProgCounterOffset = 2'h0;
            CurrBusAddr           = 8'hFF; //Initial instruction after reset.
            CurrBusDataOut        = 8'h00;
            CurrBusDataOutWE      = 1'b0;
            CurrRegA              = 8'h00;
            CurrRegB              = 8'h00;
            CurrRegSelect         = 1'b0;
            CurrProgContext       = 8'h00;
            CurrInterruptAck      = 2'b00;
        end else begin
            CurrState             = NextState;
            CurrProgCounter       = NextProgCounter;
            CurrProgCounterOffset = NextProgCounterOffset;
            CurrBusAddr           = NextBusAddr;
            CurrBusDataOut        = NextBusDataOut;
            CurrBusDataOutWE      = NextBusDataOutWE;
            CurrRegA              = NextRegA;
            CurrRegB              = NextRegB;
            CurrRegSelect         = NextRegSelect;
            CurrProgContext       = NextProgContext;
            CurrInterruptAck      = NextInterruptAck;
        end
    end

    // Combinatorial section
    always@(*) begin
        // Generic assignment to reduce the complexity of the rest of the S/M
        NextState             = CurrState;
        NextProgCounter       = CurrProgCounter;
        NextProgCounterOffset = 2'h0;
        NextBusAddr           = 8'hFF;
        NextBusDataOut        = CurrBusDataOut;
        NextBusDataOutWE      = 1'b0;
        NextRegA              = CurrRegA;
        NextRegB              = CurrRegB;
        NextRegSelect         = CurrRegSelect;
        NextProgContext       = CurrProgContext;
        NextInterruptAck      = 2'b00;

        case (CurrState)
        IDLE: begin
            if(BUS_INTERRUPTS_RAISE[0]) begin // Interrupt request A
                NextState        = GET_THREAD_START_ADDR_0;
                NextProgCounter  = 8'hFF; // Address for IRQ A handler
                NextInterruptAck = 2'b01;
            end else if(BUS_INTERRUPTS_RAISE[1]) begin // Interrupt request B
                NextState        = GET_THREAD_START_ADDR_0;
                NextProgCounter  = 8'hFE; // Address for IRQ B handler
                NextInterruptAck = 2'b10;
            end else begin
                NextState        = IDLE;
                NextProgCounter  = 8'hFF; // Nothing has happened.
                NextInterruptAck = 2'b00;
            end
        end

        GET_THREAD_START_ADDR_0:
                NextState        = GET_THREAD_START_ADDR_1;

        GET_THREAD_START_ADDR_1: begin
                NextState        = GET_THREAD_START_ADDR_2;
                NextProgCounter  = ProgMemoryOut;
        end

        // Wait for the new program counter value to settle
        GET_THREAD_START_ADDR_2:
                NextState        = CHOOSE_OPP;

        // CHOOSE_OPP - Another case statement to choose which operation to perform
        CHOOSE_OPP: begin
            case(ProgMemoryOut[3:0])
            4'h0: NextState = READ_FROM_MEM_TO_A;
            4'h1: NextState = READ_FROM_MEM_TO_B;
            4'h2: NextState = WRITE_TO_MEM_FROM_A;
            4'h3: NextState = WRITE_TO_MEM_FROM_B;
            4'h4: NextState = DO_MATHS_OPP_SAVE_IN_A;
            4'h5: NextState = DO_MATHS_OPP_SAVE_IN_B;
            4'h6: NextState = BRANCH_OPP;
            4'h7: NextState = GOTO_ADDR;
            4'h8: NextState = GOTO_IDLE;
            4'h9: NextState = FUNCTION_CALL;
            4'hA: NextState = RETURN;
            4'hB: NextState = DEREF_A;
            4'hC: NextState = DEREF_B;
            4'hD: NextState = LOAD_IMM_A;
            4'hE: NextState = LOAD_IMM_B;
            default:
                  NextState = CurrState;
            endcase

            NextProgCounterOffset = 2'h1;
        end

        ///////////////////////////////////////////////////////////////////////////////////////
        // READ_FROM_MEM_TO_A : here starts the memory read operational pipeline.
        // Wait state - to give time for the mem address to be read. Reg select is set to 0
        READ_FROM_MEM_TO_A:begin
            NextState     = READ_FROM_MEM_0;
            NextRegSelect = 1'b0;
        end

        // READ_FROM_MEM_TO_B : here starts the memory read operational pipeline.
        // Wait state - to give time for the mem address to be read. Reg select is set to 1
        READ_FROM_MEM_TO_B:begin
            NextState     = READ_FROM_MEM_0;
            NextRegSelect = 1'b1;
        end

        // The address will be valid during this state, so set the BUS_ADDR to this value.
        READ_FROM_MEM_0:begin
            NextState   = READ_FROM_MEM_1;
            NextBusAddr = ProgMemoryOut;
        end

        // Wait state - to give time for the mem data to be read
        // Increment the program counter here. This must be done 2 clock cycles ahead
        // so that it presents the right data when required.
        READ_FROM_MEM_1:begin
            NextState   = READ_FROM_MEM_2;
            NextProgCounter = CurrProgCounter + 2;
        end

        // The data will now have arrived from memory. Write it to the proper register.
        READ_FROM_MEM_2:begin
            NextState = CHOOSE_OPP;

            if(!CurrRegSelect)
                NextRegA = BusDataIn;
            else
                NextRegB = BusDataIn;
        end

        ///////////////////////////////////////////////////////////////////////////////////////
        // WRITE_TO_MEM_FROM_A : here starts the memory write operational pipeline.
        // Wait state - to find the address of where we are writing
        // Increment the program counter here. This must be done 2 clock cycles ahead
        // so that it presents the right data when required.
        WRITE_TO_MEM_FROM_A:begin
            NextState       = WRITE_TO_MEM_0;
            NextRegSelect   = 1'b0;
            NextProgCounter = CurrProgCounter + 2;

            NextBusDataOutWE = 1'b1;
        end

        ///////////////////////////////////////////////////////////////////////////////////////
        // WRITE_TO_MEM_FROM_B : here starts the memory write operational pipeline.
        // Wait state - to find the address of where we are writing
        // Increment the program counter here. This must be done 2 clock cycles ahead
        // so that it presents the right data when required.
        WRITE_TO_MEM_FROM_B:begin
            NextState       = WRITE_TO_MEM_0;
            NextRegSelect   = 1'b1;
            NextProgCounter = CurrProgCounter + 2;
        end

        // The address will be valid during this state, so set the BUS_ADDR to this value,
        // and write the value to the memory location.
        WRITE_TO_MEM_0:begin
            NextState       = CHOOSE_OPP;
            NextBusAddr     = ProgMemoryOut;
            if(!NextRegSelect)
                NextBusDataOut = CurrRegA;
            else
                NextBusDataOut = CurrRegB;

            NextBusDataOutWE = 1'b1;
        end

        ///////////////////////////////////////////////////////////////////////////////////////
        // DO_MATHS_OPP_SAVE_IN_A : here starts the DoMaths operational pipeline.
        // Reg A and Reg B must already be set to the desired values. The MSBs of the
        // Operation type determines the maths operation type. At this stage the result is
        // ready to be collected from the ALU.
        DO_MATHS_OPP_SAVE_IN_A:begin
            NextState   = DO_MATHS_OPP_0;
            NextRegA    = AluOut;
            NextProgCounter = CurrProgCounter + 1;
        end

        // DO_MATHS_OPP_SAVE_IN_B : here starts the DoMaths operational pipeline
        // when the result will go into reg B.
        DO_MATHS_OPP_SAVE_IN_B:begin
            NextState   = DO_MATHS_OPP_0;
            NextRegB    = AluOut;
            NextProgCounter = CurrProgCounter + 1;
        end

        // Wait state for new prog address to settle.
        DO_MATHS_OPP_0: NextState = CHOOSE_OPP;

        ///////////////////////////////////////////////////////////////////////////////////////
        // BRANCH_OPP : here starts the bracnh operational pipeline.
        // This block handles all 3 types of branches: BREQ, BGTQ and BLTQ
        // Branch type is fed to ALU and if condition is met, ALU output set to 8'h01
        // If condition is met, move along
        BRANCH_OPP:begin
            NextState = BRANCH_STAGE_0;
            NextProgCounter = CurrProgCounter + 1;
        end

        BRANCH_STAGE_0:begin
            if(AluOut == 8'h01) begin
                // branch taken; ProgMemoryOut == address
                NextProgCounter = ProgMemoryOut;
                NextState       = BRANCH_STAGE_1;
            end else begin
                NextProgCounter = CurrProgCounter + 1; // move along the program
                NextState       = CHOOSE_OPP;          // decide what is next instruction
            end
        end

        BRANCH_STAGE_1: NextState = CHOOSE_OPP;

        ///////////////////////////////////////////////////////////////////////////////////////
        // GOTO_ADDR : here starts the GOTO address operational pipeline.
        // Assign new address to PC and move along the program
        GOTO_ADDR: NextState = GOTO_ADDR_0;

        // address is now available
        GOTO_ADDR_0:begin
            NextProgCounter = ProgMemoryOut;
            NextState = GOTO_ADDR_1;
        end

        // next cycle - decision
        GOTO_ADDR_1: NextState = CHOOSE_OPP;

        ///////////////////////////////////////////////////////////////////////////////////////
        // FUNCTION_CALL : here starts the function call operational pipeline.
        // Save the PC of return position and move to address
        // At the start wait for 1 cycle for address to be available
        FUNCTION_CALL: NextState = FUNCTION_CALL_0;

        // set next PC to address and store PC + 2 - return position
        FUNCTION_CALL_0:begin
            NextProgContext = CurrProgCounter + 2;
            NextProgCounter = ProgMemoryOut;
            NextState       = FUNCTION_CALL_1;
        end

        FUNCTION_CALL_1: NextState = CHOOSE_OPP;

        ///////////////////////////////////////////////////////////////////////////////////////
        // RETURN : here starts the return from function call operational pipeline.
        // restore PC from context
        RETURN:begin
            NextState = RETURN_0;
            NextProgCounter = CurrProgContext;
        end

        RETURN_0: NextState = CHOOSE_OPP;

        ///////////////////////////////////////////////////////////////////////////////////////
        // DEREF_A : here starts the dereference operational pipeline.
        // immitates indirect memory access
        // Value in reg A istreated as an address for the value
        // Set the BUS address to contents of reigster A, store return value from ram in reg A
		DEREF_A: begin
			NextRegSelect = 1'b0;
			NextState = DEREF_1;
			NextBusAddr = CurrRegA;
		end

		DEREF_B: begin
			NextRegSelect = 1'b1;
			NextState = DEREF_1;
			NextBusAddr = CurrRegB;
		end

        // wait for the RAM value
		DEREF_1: NextState = DEREF_2;

        // store RAM data in the right register and increment PC
		DEREF_2: begin
			NextState = DEREF_3;
			NextProgCounter = CurrProgCounter + 1;
			if(!CurrRegSelect)
				NextRegA = BusDataIn;
			else
				NextRegB = BusDataIn;
		end

        // wait for next instruction
		DEREF_3: NextState = CHOOSE_OPP;

        ///////////////////////////////////////////////////////////////////////////////////////
        // LOAD_IMM_A : here starts the load immediate operational pipeline.
        // Set next 8bit value to one of the registers
		LOAD_IMM_A: begin
		    NextState = LOAD_IMM_0;
		    NextRegSelect = 1'b0;
		end

		LOAD_IMM_B: begin
		    NextState = LOAD_IMM_0;
		    NextRegSelect = 1'b1;
		end

		// immediate value is now ready
		LOAD_IMM_0: begin
			if(!CurrRegSelect)
				NextRegA = ProgMemoryOut;
			else
				NextRegB = ProgMemoryOut;


            NextState = LOAD_IMM_1;
            NextProgCounter = CurrProgCounter + 2;
        end

        LOAD_IMM_1: NextState = CHOOSE_OPP;


        endcase
    end

endmodule
