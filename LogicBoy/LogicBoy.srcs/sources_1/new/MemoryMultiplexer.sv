/***************************************************************************
*
* Module: Memory Multiplexer
*
* Author: Ammon Wolfert
* Date: May 26, 2020
*
* Description: Routes Communication between the CPU and Memory Modules
*
****************************************************************************/
`default_nettype none

module MemoryMultiplexer(
    input wire logic            clk,
    input wire logic            reset,
    
    input wire logic    [7:0]   address_bus,
    input wire logic    [7:0]   readROMdata,
    input wire logic    [7:0]   readGRAMdata,
    input wire logic    [7:0]   readVRAMdata,
    output logic        [7:0]   data_out_bus,
    
    input wire logic            wr_en,
    output logic                wr_en_GRAM,
    output logic                wr_en_VRAM
    );
    
    ////////// Address Register //////////
    logic               [7:0]   addressRegister [2];
    logic               [15:0]  fullAddress;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            addressRegister[0] <= 0;
            addressRegister[1] <= 0;
        end else begin
            addressRegister[0] <= address_bus;
            addressRegister[1] <= addressRegister[0];
        end
    end
    
    assign fullAddress = {addressRegister[1], addressRegister[0]};
    
     //////////// Memory Map ////////////
    
    //0x0000 - 0xc7ff   ROM -- 50kB
    //0xc800 - 0xe7ff   GRAM -- 8kB
    //0xe800 - 0xe8A4   Stack Reserved GRAM -- 0.2kB
    //0xe8a5 - 0xffff   VRAM -- 5.8kB
    
    always_comb begin
        wr_en_GRAM = 0;
        wr_en_VRAM = 0;
        data_out_bus = 'X;
        
        if (fullAddress < 16'hc800) begin   //ROM
            data_out_bus = readROMdata;
        end else if (fullAddress < 16'he8A5) begin   //GRAM
            data_out_bus = readGRAMdata;
            wr_en_GRAM = wr_en;
        end else begin
            data_out_bus = readVRAMdata;
            wr_en_VRAM = wr_en;
        end
    end
    
    
endmodule
