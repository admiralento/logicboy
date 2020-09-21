
`default_nettype none
module ReadOnlyMemory #(parameter ROM_START_ADDRESS = 0) (
        input wire logic            clk,
        input wire logic            reset,
        input wire logic    [7:0]   rd_addr,
        output logic        [7:0]   rd_data
    );
    
    localparam          LDA = 5'b00110;   //Load Register A with [Register ID] -                  opcode-XX
    localparam          LDB = 5'b00111;   //Load Register B with [Register ID] -                  opcode-XX
    localparam          LDC = 5'b01000;   //Load Register C with [Register ID] -                  opcode-XX
    localparam          LDD = 5'b01001;   //Load Register D with [Register ID] -                  opcode-XX
    
    localparam          LDV = 5'b01010;    //Load Register [Register ID] with following byte       opcode-XX [BYTE]
    localparam          LDM = 5'b01011;    //Load Register [Register ID] with [Memory Value]       opcode-XX [MSBYTE] [LSBYTE]
    
    localparam          WMLR = 5'b01100;   //Write [Register ID] to following memory address       opcode-XX [MSBYTE] [LSBYTE]
    localparam          WMLV = 5'b01101;   //Write Value to following memory address               opcode [MSBYTE] [LSBYTE] [BYTE]
    localparam          WMLM = 5'b01110;   //Write [Memory Value] to following memory address      opcode [MSBYTE] [LSBYTE] [MSBYTE] [LSBYTE]
    
    localparam          JPV = 5'b01111;    //Load [BYTE] [Byte] in to the PC                       opcode [BYTE] [BYTE]
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
    localparam          RET = 5'b10100;
    
    logic               [7:0]   rom [16];
    logic               [7:0]   rd_addrReg [2];
    logic               [15:0]  indexAdjustedReadAddress;
    
    assign rom[0] = {LDV, 3'b000};
    assign rom[1] = 8'hFF;
    assign rom[2] = {JPV, 3'b100};
    assign rom[3] = 8'h00;
    assign rom[4] = 8'h08;
    assign rom[5] = {HALT, 3'b000};
    assign rom[6] = 8'h00;
    assign rom[7] = 8'h00;
    assign rom[8] = {DEC, 3'b000};
    assign rom[9] = {JPVZ, 3'b000};
    assign rom[10] = 8'h00;
    assign rom[11] = 8'h0F;
    assign rom[12] = {JPV, 3'b100};
    assign rom[13] = 8'h00;
    assign rom[14] = 8'h08;
    assign rom[15] = {RET, 3'b000};
    
    assign indexAdjustedReadAddress = {rd_addrReg[1],rd_addrReg[0]} - ROM_START_ADDRESS;
    assign rd_data = rom[indexAdjustedReadAddress];

    always_ff @(posedge clk) begin
        if (reset) begin
            rd_addrReg[0] <= 0;
            rd_addrReg[1] <= 0;
        end else begin
            rd_addrReg[0] <= rd_addr;
            rd_addrReg[1] <= rd_addrReg[0];
        end
    end
    
endmodule
