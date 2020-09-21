/***************************************************************************
*
* Module: GeneralRam
*
* Author: Ammon Wolfert
* Date: November 26, 2019
*
* Description: Random Access Memory for general use. Records button state.
*
****************************************************************************/
`default_nettype none

module GeneralRam #(parameter GRAM_START_ADDRESS = 0, parameter BANK_SIZE = 16'h0400) (
    input wire logic            clk,
    input wire logic            reset,
    input wire logic            wr_en,
    input wire logic    [7:0]   rd_addr,
    output logic        [7:0]   rd_data,
    input wire logic    [7:0]   wr_addr,
    input wire logic    [7:0]   wr_data
    );

    logic               [7:0]   ram [BANK_SIZE];
    logic               [7:0]   rd_addrReg [2];
    logic               [7:0]   wr_addrReg [2];
    
    logic               [15:0]  indexAdjustedReadAddress;
    logic               [15:0]  indexAdjustedWriteAddress;
    
    assign indexAdjustedReadAddress = {rd_addrReg[1],rd_addrReg[0]} - GRAM_START_ADDRESS;
    assign indexAdjustedWriteAddress = {wr_addrReg[1],wr_addrReg[0]} - GRAM_START_ADDRESS;
    
    assign rd_data = ram[indexAdjustedReadAddress];

    always_ff @(posedge clk) begin
        if (~reset && wr_en) begin
            ram[indexAdjustedWriteAddress] = wr_data;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            rd_addrReg[0] <= 0;
            rd_addrReg[1] <= 0;
        end else begin
            rd_addrReg[0] <= rd_addr;
            rd_addrReg[1] <= rd_addrReg[0];
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            wr_addrReg[0] <= 0;
            wr_addrReg[1] <= 0;
        end else begin
            wr_addrReg[0] <= wr_addr;
            wr_addrReg[1] <= wr_addrReg[0];
        end
    end
endmodule
