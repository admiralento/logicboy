/***************************************************************************
*
* Module: VideoRam
*
* Author: Ammon Wolfert
* Date: November 23, 2019
*
* Description: Register file that holds sprite and tile data
*
****************************************************************************/
`default_nettype none

module VideoRam #(parameter VRAM_START_ADDRESS = 0) (
    input wire logic            clk,
    input wire logic            reset,
    input wire logic            wr_en,
    input wire logic    [7:0]   rd_addr1,
    output logic        [7:0]   rd_data1,
    input wire logic    [7:0]   rd_addr2,
    output logic        [7:0]   rd_data2,
    input wire logic    [7:0]   wr_addr,
    input wire logic    [7:0]   wr_data,
    input wire logic    [15:0]  test_addr,
    output logic        [7:0]   test_data
    );

    logic [7:0] vram [16'h175b];
    logic [7:0] rdAddrReg1 [2];
    logic [7:0] rdAddrReg2 [2];
    logic [7:0] wrAddrReg  [2];
    
    logic               [15:0]  indexAdjustedReadAddress1;
    logic               [15:0]  indexAdjustedReadAddress2;
    logic               [15:0]  indexAdjustedWriteAddress;
    
    assign indexAdjustedReadAddress1 = {rdAddrReg1[1],rdAddrReg1[0]} - VRAM_START_ADDRESS;
    assign indexAdjustedReadAddress2 = {rdAddrReg2[1],rdAddrReg2[0]} - VRAM_START_ADDRESS;
    assign indexAdjustedWriteAddress = {wrAddrReg[1],wrAddrReg[0]} - VRAM_START_ADDRESS;

    always_ff @(posedge clk) begin
        if (wr_en) begin
            vram[indexAdjustedWriteAddress] <= wr_data;
        end
    end

    //Shift registers allow for 8 bit bus to access 16-bit addresses
    always_ff @(posedge clk) begin
        if (reset) begin
            rdAddrReg1[0] <= 0;
            rdAddrReg1[1] <= 0;
            rdAddrReg2[0] <= 0;
            rdAddrReg2[1] <= 0;
            wrAddrReg[0] <= 0;
            wrAddrReg[1] <= 0;
        end else begin
            rdAddrReg1[0] <= rd_addr1;
            rdAddrReg1[1] <= rdAddrReg1[0];
    
            rdAddrReg2[0] <= rd_addr2;
            rdAddrReg2[1] <= rdAddrReg2[0];
            
            wrAddrReg[0] <= wr_addr;
            wrAddrReg[1] <= wrAddrReg[0];
            
        end
    end

    assign rd_data1 = vram[indexAdjustedReadAddress1];
    assign rd_data2 = vram[indexAdjustedReadAddress2];
    
    assign test_data = vram[test_addr];

    //  Relative Address Map
    //  0x0000 - 0x0002     Window X,Y, and Settings    (3 bytes)
    //  0x0003 - 0x0802     Primary Tile Map            (32 x 32)
    //  0x0803 - 0x0A5A     Window Tile Map             (15 x 20)
    //  0x0A5B - 0x0F5A     Sprite Location Registers  (256 sprites)
    //      - 2 bytes pointer
    //      - 1 byte X pos
    //      - 1 byte Y pos
    //      - 1 info byte
    //  0x0F5B - 0x135A     Graphical Tile Data                    (64 tiles)
    //  0x135B - 0x175A     Graphical Sprite Data                 (64 Sprites)
    
    //  Abs Address Map
    //  0xE8A5 - 0xE8A7     Window X,Y, and Settings    (3 bytes)
    //  0xE8A8 - 0xF0A7     Primary Tile Map            (32 x 32)
    //  0xF0A8 - 0xF2FF     Window Tile Map             (15 x 20)
    //  0xF300 - 0xF4FF     Sprite Location Registers  (256 sprites)
    //      - 2 bytes pointer
    //      - 1 byte X pos
    //      - 1 byte Y pos
    //      - 1 info byte
    //  0xF800 - 0xFBFF     Graphical Tile Data                    (64 tiles)
    //  0xFC00 - 0xFFFF     Graphical Sprite Data                 (64 Sprites)
    
    //TODO move button register to GRAM!

endmodule
