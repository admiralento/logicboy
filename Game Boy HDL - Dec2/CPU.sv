/***************************************************************************
*
* Module: CPU
*
* Author: Ammon Wolfert
* Date: November 26, 2019
*
* Description: 8-bit CPU with reduced custom instruction set
*
****************************************************************************/
`default_nettype none

module CPU(
    input wire logic            clk,
    input wire logic            reset,
    input wire logic            run,
    input wire logic    [7:0]   data_in_bus,
    output logic        [7:0]   data_out_bus,
    output logic        [7:0]   address_bus,
    output logic                wr_en,
    output logic                interrupt
    );
    
    /*
    *   6-bit Opcodes with 2-bits of configuration
    */
    
    
    localparam          LDA = 5'b00110;   //Load Register A with [Register ID] -                  opcode-XX
    localparam          LDB = 5'b00111;   //Load Register B with [Register ID] -                  opcode-XX
    localparam          LDC = 5'b01000;   //Load Register C with [Register ID] -                  opcode-XX
    localparam          LDD = 5'b01001;   //Load Register D with [Register ID] -                  opcode-XX
    
    localparam          LDV = 5'b01010;    //Load Register [Register ID] with following byte       opcode-XX [BYTE]
    localparam          LDM = 5'b01011;    //Load Register [Register ID] with [Memory Value]       opcode-XX [MSBYTE] [LSBYTE]
    
    localparam          WMLR = 5'b01100;   //Write [Register ID] to following memory address       opcode-XX [MSBYTE] [LSBYTE]
    localparam          WMLV = 5'b01101;   //Write Value to following memory address               opcode [MSBYTE] [LSBYTE] [BYTE]
    localparam          WMLM = 5'b01110;   //Write [Memory Value] to following memory address      opcode [MSBYTE] [LSBYTE] [MSBYTE] [LSBYTE]
    
    localparam          JPV = 5'b01111;    //Load [Byte] in to the PC                              opcode [BYTE] [BYTE]
    localparam          JPM = 5'b10000;    //Load [Memory Value] in to the PC                      opcode [MSBYTE] [LSBYTE]
    
    localparam          JPVZ = 5'b10001;   //Load [Byte] in to the PC if zero flag is set          opcode [BYTE]
    localparam          JPMZ = 5'b10010;   //Load [Memory Value] in to the PC if zero flag is set  opcode [MSBYTE] [LSBYTE]
    
    localparam          ADD = 5'b00001;    //Add Register B to the A Register                       opcode
    localparam          SUB = 5'b00010;    //Subtract Register B from the A Register                opcode
    localparam          INC = 5'b00011;    //Increment the A Register by one                        opcode
    localparam          DEC = 5'b00100;    //Deccrement the A Register by one                        opcode
    localparam          SET = 5'b00101;    //Set the XXX bit of Register A                        opcode-XXX
    localparam          RST = 5'b10011;    //Reset the XXX bit of Register A                      opcode-XXX
    
    localparam          NOP = 5'b00000;    //Do nothing                                            opcode
    localparam          HALT = 5'b11111;   //Stop the computer                                     opcode
    
    localparam          RET = 5'b10100;    //Return up the Stack                                     opcode
    
    localparam          STACK_START = 16'hE800;
    
    /////////// ALU Signals ///////////
    logic           [7:0]   aluDataInA;
    logic           [7:0]   aluDataInB;
    logic           [7:0]   aluDataOut;
    logic           [3:0]   aluControl;

    ArthmeticLogicUnit ALU (
        .dataInA(aluDataInA),
        .dataInB(aluDataInB),
        .cntr(aluControl),
        .dataOut(aluDataOut)
    );

    //////////// Internal Registers ////////////
    logic               [7:0]   registerA;
    logic               [7:0]   inputRegisterA;
    logic                       loadRegisterA;

    logic               [7:0]   registerB;
    logic               [7:0]   inputRegisterB;
    logic                       loadRegisterB;

    logic               [7:0]   registerC;
    logic               [7:0]   inputRegisterC;
    logic                       loadRegisterC;

    logic               [7:0]   registerD;
    logic               [7:0]   inputRegisterD;
    logic                       loadRegisterD;
    
    logic               [7:0]   flagRegister;
    logic               [7:0]   inputFlagRegister;
    logic                       loadFlagRegister;
    
    logic               [7:0]  instructionRegister;
    logic               [7:0]  inputInstructionRegister;
    logic                       loadInstructionRegister;

    logic               [15:0]  programCounter;
    logic               [15:0]  inputProgramCounter;
    logic                       loadProgramCounter;
    logic                       incProgramCounter;
    
    logic               [15:0]  stackPointer;
    logic                       decStackPointer;
    logic                       incStackPointer;

    always_ff @(posedge clk) begin
        if (reset) begin
            registerA <= 0;
        end else if (loadRegisterA) begin
            registerA <= inputRegisterA;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            registerB <= 0;
        end else if (loadRegisterB) begin
            registerB <= inputRegisterB;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            registerC <= 0;
        end else if (loadRegisterC) begin
            registerC <= inputRegisterC;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            registerD <= 0;
        end else if (loadRegisterD) begin
            registerD <= inputRegisterD;
        end
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin
            flagRegister <= 0;
        end else if (loadFlagRegister) begin
            flagRegister <= inputFlagRegister;
        end
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin
            registerD <= 0;
        end else if (loadRegisterD) begin
            registerD <= inputRegisterD;
        end
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin
            instructionRegister <= 0;
        end else if (loadInstructionRegister) begin
            instructionRegister <= inputInstructionRegister;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            programCounter <= 0;
        end else if (loadProgramCounter) begin
            programCounter <= inputProgramCounter;
        end else if (incProgramCounter) begin
            programCounter <= programCounter + 1;
        end
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin
            stackPointer <= STACK_START;
        end else if (incStackPointer) begin
            stackPointer <= stackPointer + 1;
        end else if (decStackPointer) begin
            stackPointer <= stackPointer - 1;
        end
    end
    
    ///////// Memory Cache //////////
    logic               [7:0]   cache [8];
    logic                       loadCache;
    logic               [7:0]   inputCache;
    logic               [2:0]   cacheAddress;
    
    always_ff @(posedge clk) begin
        if (loadCache)
            cache[cacheAddress] <= inputCache;
    end

    ///////// Execution Signals /////
    logic               [7:0]   microCount;
    logic                       clrMicroCount;
    logic                       incMicroCount;
    always_ff @(posedge clk) begin
        if (reset || clrMicroCount) begin
            microCount <= 0;
        end else if (incMicroCount) begin
            microCount <= microCount + 1;
        end
    end

    ///////// State Machine /////////
    typedef enum logic[7:0] {init, fetch, execute, halt, ERR='X} State;
    State cs, ns;

    always_comb begin
        ns = ERR;

        loadRegisterA = 0;
        loadRegisterB = 0;
        loadRegisterC = 0;
        loadRegisterD = 0;
        loadInstructionRegister = 0;
        loadProgramCounter = 0;
        loadFlagRegister = 0;

        inputRegisterA = 'X;
        inputRegisterB = 'X;
        inputRegisterC = 'X;
        inputRegisterD = 'X;
        inputInstructionRegister = 'X;
        inputProgramCounter = 'X;
        
        inputCache = 'X;
        loadCache = 0;
        cacheAddress = 'X;

        clrMicroCount = 0;
        incMicroCount = 0;
        
        aluDataInA = 'X;
        aluDataInB = 'X;
        aluControl = 'X;

        interrupt = 0;
        
        data_out_bus = 'X;
        wr_en = 0;
        
        address_bus = 'X;
        incProgramCounter = 0;
        incStackPointer = 0;
        decStackPointer = 0;

        case (cs)
            init: begin
                if (run) begin
                    ns = fetch;
                    inputProgramCounter = 16'h00;
                    loadProgramCounter = 1;
                    clrMicroCount = 1;
                end else begin
                    ns = init;
                end
            end

            fetch: begin
                incMicroCount = 1;
                ns = fetch;
                case (microCount)
                    0: begin    //Load MSByte Address
                        address_bus = programCounter[15:8];
                    end
                    1: begin    //Load LSByte Address
                        address_bus = programCounter[7:0];
                    end
                    2: begin
                        loadInstructionRegister = 1;                //Load IR
                        inputInstructionRegister = data_in_bus;
                        clrMicroCount = 1;
                        incProgramCounter = 1;                      //Advance PC
                        ns = execute;
                    end
                endcase
            end
            
            execute: begin
                ns = execute;
                case (instructionRegister[7:3])
                
                    //Do nothing
                    NOP: begin
                        ns = fetch;
                        clrMicroCount = 1;
                    end
                    
                    //Stop the Computer
                    HALT: begin
                        ns = halt;
                    end
                    
                    ADD: begin
                        aluDataInA = registerA;
                        aluDataInB = registerB;
                        aluControl = 0;
                        loadRegisterA = 1;
                        inputRegisterA = aluDataOut;
                        loadFlagRegister = 1;
                        inputFlagRegister = {7'b0000000, ((aluDataOut == 0) ? 1'b1 : 1'b0)};
                        ns = fetch;
                        clrMicroCount = 1;
                    end
                    
                    SUB: begin
                        aluDataInA = registerA;
                        aluDataInB = registerB;
                        aluControl = 1;
                        loadRegisterA = 1;
                        inputRegisterA = aluDataOut;
                        loadFlagRegister = 1;
                        inputFlagRegister = {7'b0000000, ((aluDataOut == 0) ? 1'b1 : 1'b0)};
                        ns = fetch;
                        clrMicroCount = 1;
                    end
                    
                    INC: begin
                        aluDataInA = registerA;
                        aluControl = 11;
                        loadRegisterA = 1;
                        inputRegisterA = aluDataOut;
                        loadFlagRegister = 1;
                        inputFlagRegister = {7'b0000000, ((aluDataOut == 0) ? 1'b1 : 1'b0)};
                        ns = fetch;
                        clrMicroCount = 1;
                    end
                    
                    DEC: begin
                        aluDataInA = registerA;
                        aluControl = 12;
                        loadRegisterA = 1;
                        inputRegisterA = aluDataOut;
                        loadFlagRegister = 1;
                        inputFlagRegister = {7'b0000000, ((aluDataOut == 0) ? 1'b1 : 1'b0)};
                        ns = fetch;
                        clrMicroCount = 1;
                    end
                    
                    SET: begin
                        aluDataInA = registerA;
                        aluDataInB = instructionRegister[2:0];
                        aluControl = 13;
                        loadRegisterA = 1;
                        inputRegisterA = aluDataOut;
                        loadFlagRegister = 1;
                        inputFlagRegister = {7'b0000000, ((aluDataOut == 0) ? 1'b1 : 1'b0)};
                        ns = fetch;
                        clrMicroCount = 1;
                    end
                    
                    RST: begin
                        aluDataInA = registerA;
                        aluDataInB = instructionRegister[2:0];
                        aluControl = 14;
                        loadRegisterA = 1;
                        inputRegisterA = aluDataOut;
                        loadFlagRegister = 1;
                        inputFlagRegister = {7'b0000000, ((aluDataOut == 0) ? 1'b1 : 1'b0)};
                        ns = fetch;
                        clrMicroCount = 1;
                    end
                    
                    RET: begin
                        incMicroCount = 1;
                        case (microCount)
                            0: begin
                                address_bus = stackPointer[15:8];
                            end
                            1: begin    //Move SP to [LSBYTE]
                                address_bus = stackPointer[7:0];
                                incStackPointer = 1;
                            end
                            2: begin    //Read [MSBYTE] into Cache[0]
                                loadCache = 1;
                                cacheAddress = 0;
                                inputCache = data_in_bus;
                                address_bus = stackPointer[15:8];
                            end
                            3: begin
                                address_bus = stackPointer[7:0];
                                incStackPointer = 1;
                            end
                            4: begin    //Load the SP Vaule into the PC
                                loadProgramCounter = 1;
                                inputProgramCounter = {cache[0], data_in_bus};
                                ns = fetch;
                                clrMicroCount = 1;
                            end
                        endcase
                    end
                    
                    //Load Register A with [Register ID]
                    LDA: begin
                        ns = fetch;
                        clrMicroCount = 1;
                        loadRegisterA = 1;
                        case (instructionRegister[1:0])
                            0:  inputRegisterA = registerA;
                            1:  inputRegisterA = registerB;
                            2:  inputRegisterA = registerC;
                            3:  inputRegisterA = registerD;
                            default: inputRegisterA = 'X;
                        endcase
                    end
                    
                    //Load Register B with [Register ID]
                    LDB: begin
                        ns = fetch;
                        clrMicroCount = 1;
                        loadRegisterB = 1;
                        case (instructionRegister[1:0])
                            0:  inputRegisterB = registerA;
                            1:  inputRegisterB = registerB;
                            2:  inputRegisterB = registerC;
                            3:  inputRegisterB = registerD;
                            default: inputRegisterB = 'X;
                        endcase
                    end
                    
                    //Load Register C with [Register ID]
                    LDC: begin
                        ns = fetch;
                        clrMicroCount = 1;
                        loadRegisterC = 1;
                        case (instructionRegister[1:0])
                            0:  inputRegisterC = registerA;
                            1:  inputRegisterC = registerB;
                            2:  inputRegisterC = registerC;
                            3:  inputRegisterC = registerD;
                            default: inputRegisterC = 'X;
                        endcase
                    end
                    
                    //Load Register D with [Register ID]
                    LDD: begin
                        ns = fetch;
                        clrMicroCount = 1;
                        loadRegisterD = 1;
                        case (instructionRegister[1:0])
                            0:  inputRegisterD = registerA;
                            1:  inputRegisterD = registerB;
                            2:  inputRegisterD = registerC;
                            3:  inputRegisterD = registerD;
                            default: inputRegisterD = 'X;
                        endcase
                    end
                    
                    //Load Register [Register ID] with following byte
                    LDV: begin
                        incMicroCount = 1;
                        case (microCount)
                            0: begin    //Load MSByte Address
                                address_bus = programCounter[15:8];
                            end
                            1: begin    //Load LSByte Address
                                address_bus = programCounter[7:0];
                            end
                            2: begin    //Load [Register-ID] with new Byte
                                case (instructionRegister[1:0])
                                    0: begin
                                        loadRegisterA = 1;
                                        inputRegisterA = data_in_bus;
                                    end
                                    1: begin
                                        loadRegisterB = 1;
                                        inputRegisterB = data_in_bus;
                                    end
                                    2: begin
                                        loadRegisterC = 1;
                                        inputRegisterC = data_in_bus;
                                    end
                                    3: begin
                                        loadRegisterD = 1;
                                        inputRegisterD = data_in_bus;
                                    end
                                endcase
                                incProgramCounter = 1;                      //Advance PC
                                ns = fetch;
                                clrMicroCount = 1;
                            end
                        endcase
                    end
                    
                    //Load Register [Register ID] with [Memory Value]       opcode-XX [MSBYTE] [LSBYTE]
                    LDM: begin
                        incMicroCount = 1;
                        case (microCount)
                            0: begin
                                address_bus = programCounter[15:8];
                            end
                            1: begin
                                address_bus = programCounter[7:0];
                                incProgramCounter = 1;
                            end
                            2: begin    //Read [MSBYTE] into Cache[0]
                                loadCache = 1;
                                cacheAddress = 0;
                                inputCache = data_in_bus;
                                address_bus = programCounter[15:8];
                            end
                            3: begin
                                address_bus = programCounter[7:0];
                            end
                            4: begin    //Read [LSBYTE] into Cache[1], Start reading memory
                                loadCache = 1;
                                cacheAddress = 1;
                                inputCache = data_in_bus;
                                address_bus = cache[0];
                            end
                            5: begin    //
                                address_bus = cache[1];
                            end
                            6: begin    //Load [Register-ID] with new Byte
                                case (instructionRegister[1:0])
                                    0: begin
                                        loadRegisterA = 1;
                                        inputRegisterA = data_in_bus;
                                    end
                                    1: begin
                                        loadRegisterB = 1;
                                        inputRegisterB = data_in_bus;
                                    end
                                    2: begin
                                        loadRegisterC = 1;
                                        inputRegisterC = data_in_bus;
                                    end
                                    3: begin
                                        loadRegisterD = 1;
                                        inputRegisterD = data_in_bus;
                                    end
                                endcase
                                incProgramCounter = 1;                      //Advance PC
                                ns = fetch;
                                clrMicroCount = 1;
                            end
                        endcase
                    end
                    
                    //Write [Register ID] to following memory address       opcode-XX [MSBYTE] [LSBYTE]
                    WMLR: begin
                        incMicroCount = 1;
                        case (microCount)
                            0: begin
                                address_bus = programCounter[15:8];
                            end
                            1: begin
                                address_bus = programCounter[7:0];
                                incProgramCounter = 1;
                            end
                            2: begin    //Read [MSBYTE] into Cache[0]
                                loadCache = 1;
                                cacheAddress = 0;
                                inputCache = data_in_bus;
                                address_bus = programCounter[15:8];
                            end
                            3: begin
                                address_bus = programCounter[7:0];
                            end
                            4: begin    //Read [LSBYTE] into Cache[1], Start reading memory
                                loadCache = 1;
                                cacheAddress = 1;
                                inputCache = data_in_bus;
                                address_bus = cache[0];
                            end
                            5: begin
                                address_bus = cache[1];
                            end
                            6: begin    //Write [Register-ID] to Memory
                                wr_en = 1;
                                case (instructionRegister[1:0])
                                    0: data_out_bus = registerA;
                                    1: data_out_bus = registerB;
                                    2: data_out_bus = registerC;
                                    3: data_out_bus = registerD;
                                    default: data_out_bus = 'X;
                                endcase
                                incProgramCounter = 1;                      //Advance PC
                                ns = fetch;
                                clrMicroCount = 1;
                            end
                        endcase
                    end
                    
                    //Write Value to following memory address               opcode [MSBYTE] [LSBYTE] [BYTE]
                    WMLV: begin
                        incMicroCount = 1;
                        case (microCount)
                            0: begin
                                address_bus = programCounter[15:8];
                            end
                            1: begin
                                address_bus = programCounter[7:0];
                                incProgramCounter = 1;  //Advance PC to [LSBYTE]
                            end
                            2: begin    //Read [MSBYTE] into Cache[0]
                                loadCache = 1;
                                cacheAddress = 0;
                                inputCache = data_in_bus;
                                address_bus = programCounter[15:8];
                            end
                            3: begin
                                address_bus = programCounter[7:0];
                                incProgramCounter = 1;  //Advance PC to [BYTE]
                            end
                            4: begin    //Read [LSBYTE] into Cache[1]
                                loadCache = 1;
                                cacheAddress = 1;
                                inputCache = data_in_bus;
                                address_bus = programCounter[15:8];
                            end
                            5: begin
                                address_bus = programCounter[7:0];
                            end
                            6: begin    //Read [BYTE] into Cache[2]
                                loadCache = 1;
                                cacheAddress = 2;
                                inputCache = data_in_bus;
                                address_bus = cache[0];
                            end
                            7: begin
                                address_bus = cache[1];
                            end
                            8: begin    //Route [BYTE] out to new memory location
                                wr_en = 1;
                                data_out_bus = cache[2];
                                incProgramCounter = 1;  //Advance PC to next opcode
                                ns = fetch;
                                clrMicroCount = 1;
                            end
                        endcase
                    end
                    
                    //Write [Memory Value (2)] to following memory address (1)     opcode [MSBYTE1] [LSBYTE1] [MSBYTE2] [LSBYTE2]
                    WMLM: begin
                        incMicroCount = 1;
                        case (microCount)
                            0: begin
                                address_bus = programCounter[15:8];
                            end
                            1: begin
                                address_bus = programCounter[7:0];
                                incProgramCounter = 1;  //Advance PC to [LSBYTE1]
                            end
                            2: begin    //Read [MSBYTE1] into Cache[0]
                                loadCache = 1;
                                cacheAddress = 0;
                                inputCache = data_in_bus;
                                address_bus = programCounter[15:8];
                            end
                            3: begin
                                address_bus = programCounter[7:0];
                                incProgramCounter = 1;  //Advance PC to [MSBYTE2]
                            end
                            4: begin    //Read [LSBYTE1] into Cache[1]
                                loadCache = 1;
                                cacheAddress = 1;
                                inputCache = data_in_bus;
                                address_bus = programCounter[15:8];
                            end
                            5: begin
                                address_bus = programCounter[7:0];
                                incProgramCounter = 1;  //Advance PC to [LSBYTE2]
                            end
                            6: begin    //Read [MSBYTE2] into Cache[2]
                                loadCache = 1;
                                cacheAddress = 2;
                                inputCache = data_in_bus;
                                address_bus = programCounter[15:8];
                            end
                            7: begin
                                address_bus = programCounter[7:0];
                            end
                            8: begin    //Read [LSBYTE2] into Cache[3]
                                loadCache = 1;
                                cacheAddress = 3;
                                inputCache = data_in_bus;
                                address_bus = cache[2];
                            end
                            9: begin
                                address_bus = cache[3];
                            end
                            10: begin    //Read [DATA_BYTE] into Cache[4]
                                loadCache = 1;
                                cacheAddress = 4;
                                inputCache = data_in_bus;
                                address_bus = cache[0];
                            end
                            11: begin
                                address_bus = cache[1];
                            end
                            12: begin    //Route [BYTE] out to new memory location
                                wr_en = 1;
                                data_out_bus = cache[4];
                                incProgramCounter = 1;  //Advance PC to next opcode
                                ns = fetch;
                                clrMicroCount = 1;
                            end
                        endcase
                    end
                    
                    //Load [Byte1][Byte2] in to the PC                              opcode [BYTE1] [BYTE2]
                    JPV: begin
                        incMicroCount = 1;
                        case (microCount)
                            0: begin    //Load MSByte Address
                                address_bus = programCounter[15:8];
                            end
                            1: begin    //Move PC to [BYTE2]
                                address_bus = programCounter[7:0];
                                incProgramCounter = 1;
                            end
                            2: begin    //Load [BYTE1] into Cache[0]
                                loadCache = 1;
                                cacheAddress = 0;
                                inputCache = data_in_bus;
                                address_bus = programCounter[15:8];
                            end
                            3: begin
                                loadCache = 1;
                                cacheAddress = 1;
                                inputCache = programCounter[7:0] + 8'b00000001;
                                address_bus = programCounter[7:0];
                                incProgramCounter = 1;
                                if (instructionRegister[2]) decStackPointer = 1;
                            end
                            4: begin    //Load PC with new 16-bit value
                                loadCache = 1;
                                cacheAddress = 2;
                                inputCache = programCounter[15:8];
                                loadProgramCounter = 1;
                                inputProgramCounter = {cache[0],data_in_bus};
                                if (instructionRegister[2]) begin
                                    address_bus = stackPointer[15:8];
                                end else begin
                                    ns = fetch;
                                    clrMicroCount = 1;
                                end
                            end
                            5: begin
                                address_bus = stackPointer[7:0];
                                decStackPointer = 1;
                            end
                            6: begin
                                wr_en = 1;
                                data_out_bus = cache[1];
                                address_bus = stackPointer[15:8];
                            end
                            7: begin
                                address_bus = stackPointer[7:0];
                            end
                            8: begin
                                wr_en = 1;
                                data_out_bus = cache[2];
                                ns = fetch;
                                clrMicroCount = 1;
                            end
                        endcase
                    end
                    
                    //Currently doesnt use the Stack
                     //Load [Memory Value] in to the PC                      opcode [MSBYTE] [LSBYTE]
                    JPM: begin
                        incMicroCount = 1;
                        case (microCount)
                            0: begin
                                address_bus = programCounter[15:8];
                            end
                            1: begin    //Move PC to [LSBYTE]
                                address_bus = programCounter[7:0];
                                incProgramCounter = 1;
                            end
                            2: begin    //Read [MSBYTE] into Cache[0]
                                loadCache = 1;
                                cacheAddress = 0;
                                inputCache = data_in_bus;
                                address_bus = programCounter[15:8];
                            end
                            3: begin
                                address_bus = programCounter[7:0];
                            end
                            4: begin    //Read [MSBYTE][LSBYTE] into PC, Start executing a JPV
                                loadProgramCounter = 1;
                                inputProgramCounter = {cache[0], data_in_bus};
                                loadInstructionRegister = 1;
                                inputInstructionRegister = {JPV, instructionRegister[2:0]};
                                clrMicroCount = 1;
                            end
                        endcase
                    end
                    
                    //Load [Byte1] [Byte2] in to the PC if zero flag is set          opcode [BYTE1] [BYTE2]
                    JPVZ: begin
                        if (flagRegister[0]) begin
                            loadInstructionRegister = 1;
                            inputInstructionRegister = {JPV, instructionRegister[2:0]};
                        end else begin
                            loadProgramCounter = 1;
                            inputProgramCounter = programCounter + 2;
                            ns = fetch;
                            clrMicroCount = 1;
                        end
                    end
                    
                    //Load [Memory Value] in to the PC if zero flag is set  opcode [MSBYTE] [LSBYTE]
                    JPMZ: begin
                        if (flagRegister[0]) begin
                            loadInstructionRegister = 1;
                            inputInstructionRegister = {JPM, instructionRegister[2:0]};
                        end else begin
                            loadProgramCounter = 1;
                            inputProgramCounter = programCounter + 2;
                            ns = fetch;
                            clrMicroCount = 1;
                        end
                    end
                    
                endcase
            end

            halt: begin
                ns = halt;
                interrupt = 1;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            cs <= init;
        end else begin
            cs <= ns;
        end
    end

endmodule
