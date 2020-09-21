/***************************************************************************
*
* Module: ALU
*
* Author: Ammon Wolfert
* Date: November 29, 2019
*
* Description: Preforms various arthmetic and logical operations.
*
****************************************************************************/
`default_nettype none

module ArthmeticLogicUnit(
    input wire logic    [7:0]   dataInA,
    input wire logic    [7:0]   dataInB,
    input wire logic    [3:0]   cntr,
    output logic        [7:0]   dataOut
    );

    always_comb begin
        dataOut = 'X;
        case (cntr)
            4'd0: begin
                //Preform Addition
                dataOut = dataInA + dataInB;
            end
            4'd1: begin
                //Preform Subtraction
                dataOut = dataInA - dataInB;
            end
            4'd2: begin
                //Preform Bitwise AND
                dataOut = dataInA & dataInB;
            end
            4'd3: begin
                //Preform Bitwise OR
                dataOut = dataInA | dataInB;
            end
            4'd4: begin
                //Preform Bitwise XOR
                dataOut = dataInA ^ dataInB;
            end
            4'd5: begin
                //Preform Logical AND
                dataOut = dataInA && dataInB;
            end
            4'd6: begin
                //DataInA is greater than dataInB
                dataOut = dataInA > dataInB;
            end
            4'd7: begin
                //DataInA is less than dataInB
                dataOut = dataInA < dataInB;
            end
            4'd8: begin
                //DataInA == DataInB
                dataOut = (dataInA == dataInB);
            end
            4'd9: begin
                //Left Shift A by B[2:0] places
                dataOut = dataInA << dataInB[2:0];
            end
            4'd10: begin
                //Right Shift A by B[2:0] places
                dataOut = dataInA >> dataInB[2:0];
            end
            4'd11: begin
                //Increment DataInA
                dataOut = dataInA + 1;
            end
            4'd12: begin
                //Deincrement DataInA
                dataOut = dataInA - 1;
            end
            4'd13: begin
                //Set Bit dataInB[2:0] in dataInA
                dataOut = dataInA | (8'b00000001 << dataInB[2:0]);
            end
            4'd14: begin
                //Reset Bit dataInB[2:0] in dataInA
                dataOut = dataInA & ~(8'b00000001 << dataInB[2:0]);
            end
            4'd15: begin
                //Test Bit dataInB[2:0] in dataInB
                dataOut = dataInA[dataInB[2:0]];
            end
        endcase
    end

endmodule
