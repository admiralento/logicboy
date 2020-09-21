/***************************************************************************
*
* Module: BitmapToVga
*
* Author: Jeff Goeders / Modified by Ammon Wolfert
* Date: May 13, 2019 / November 23rd 2019
*
* Description: Stores a 160x120 RGB bitmap (2 bit monochrome), and outputs
*               a scaled up image as 640x480 video over the VGA outputs.
*               Designed for the Nexys4DDR board.
*
*
****************************************************************************/

`default_nettype none

module BitmapToVga (
    input wire logic            clk,
    input wire logic            clk_vga,
    input wire logic            reset,
    input wire logic    [7:0]   x,
    input wire logic    [7:0]   y,
    input wire logic    [1:0]   color,
    input wire logic            wr_en,
    input wire logic            swapBuffer,
    output logic                bufferSwapped,
    output logic        [3:0]   VGA_R,
    output logic        [3:0]   VGA_G,
    output logic        [3:0]   VGA_B,
    output logic                VGA_hsync,
    output logic                VGA_vsync
);

// Configuration of VGA Timing information
localparam V_PIXELS             = 10'd480;
localparam V_SYNC_START         = V_PIXELS + 14 - 1;
localparam V_SYNC_END           = V_SYNC_START + 2 - 1;
localparam V_TOTAL              = 10'd525;

localparam H_PIXELS             = 10'd640;
localparam H_SYNC_START         = H_PIXELS + 20 - 1;
localparam H_SYNC_END           = H_SYNC_START + 96 - 1;
localparam H_TOTAL              = 10'd800;

// horizontal and vertical conters
logic   [9:0]   hcount;
logic   [9:0]   vcount;

// Data read from bitmap memory
logic   [1:0]   rd_data;

// Logic to control when h/v counters are reset
logic           hcount_clear;
logic           vcount_clear;

assign hcount_clear = (hcount == (H_TOTAL - 1));
assign vcount_clear = (vcount == (V_TOTAL - 1));

// VGA Colors are taken from bitmap memory when h/v count is within drawable area
// 0 when outside drawable area
always_comb begin
    VGA_R = 4'b0000;
    VGA_B = 4'b0000;
    VGA_G = 4'b0000;

    if (hcount < H_PIXELS && vcount < V_PIXELS) begin
        VGA_G = {rd_data, 2'b10};
    end
end

//Buffer Connection Signals
logic writeA_readB;
logic [1:0] rd_data_bufA, rd_data_bufB;

//FSM
typedef enum logic[0:0] {renderingA , renderingB, ERR = 'X} stateType;
stateType cs, ns;

always_comb begin
    writeA_readB = 0;
    bufferSwapped = 0;
    ns = ERR;
    case (cs)
        renderingA: begin   //Route Writing to Buffer B and Reading to Buffer A
            writeA_readB = 0;
            if (swapBuffer && vcount_clear) begin
                ns = renderingB;
                bufferSwapped = 1;
            end else begin
                ns = renderingA;
            end
        end
        renderingB: begin   //Route Writing to Buffer A and Reading to Buffer B
            writeA_readB = 1;
            if (swapBuffer && vcount_clear) begin
                ns = renderingA;
                bufferSwapped = 1;
            end else begin
                ns = renderingB;
            end
        end
    endcase
end

always_ff @(posedge clk) begin
    cs <= (reset) ? renderingA : ns;
end

// hcount
always_ff @(posedge clk_vga) begin
    if (reset)
        hcount <= 10'b0;
    else if (hcount_clear)
        hcount <= 10'b0;
    else
        hcount <= hcount + 1;
end

// vcount
always_ff @(posedge clk_vga) begin
    if (reset)
        vcount <= 10'b0;
    else if (vcount_clear && hcount_clear)
        vcount <= 10'b0;
    else if (hcount_clear)
        vcount <= vcount + 1;
end

// VGA_hsync/VGA_vsync
always_ff @(posedge clk_vga) begin
    VGA_hsync <= ~((hcount >= H_SYNC_START) && (hcount <= H_SYNC_END));
    VGA_vsync <= ~((vcount >= V_SYNC_START) && (vcount <= V_SYNC_END));
end

VgaRam bufferA (
    .clk_user(clk),
    .clk_vga(clk_vga),
    .ena(writeA_readB),
    .enb(~writeA_readB),
    .wr_en(wr_en),
    .wr_addr({y, x}),
    .rd_addr({vcount[9:2], hcount[9:2]}),
    .wr_data(color),
    .rd_data(rd_data_bufA)
);

VgaRam bufferB (
    .clk_user(clk),
    .clk_vga(clk_vga),
    .ena(~writeA_readB),
    .enb(writeA_readB),
    .wr_en(wr_en),
    .wr_addr({y, x}),
    .rd_addr({vcount[9:2], hcount[9:2]}),
    .wr_data(color),
    .rd_data(rd_data_bufB)
);

//Handle Buffer Routing
assign rd_data = (writeA_readB) ? rd_data_bufB : rd_data_bufA;

endmodule

module VgaRam (
    input wire logic            clk_user,
    input wire logic            clk_vga,
    input wire logic            ena,
    input wire logic            enb,
    input wire logic            wr_en,
    input wire logic    [15:0]  wr_addr,
    input wire logic    [15:0]  rd_addr,
    input wire logic    [1:0]   wr_data,
    output logic        [1:0]   rd_data
);

logic                   [1:0]   ram [32768];  // 160x120 => 256x128

always_ff @(posedge clk_user)
    if (ena)
        if (wr_en)
            ram[wr_addr] <= wr_data;

always_ff @(posedge clk_vga)
    if (enb)
        rd_data <= ram[rd_addr];

endmodule
