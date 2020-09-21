/***************************************************************************
*
* Module: PixelProcessor
*
* Author: Ammon Wolfert
* Date: November 24, 2019
*
* Description: Handles communication with the VRAM and manages creation of
*              the VGA video signal
*
****************************************************************************/
`default_nettype none

module PixelProcessor (
    input wire logic            clk,
    input wire logic            clk_vga,
    input wire logic            reset,
    input wire logic            refresh_en,
    input wire logic            wr_en,
    input wire logic    [7:0]   wr_data,
    input wire logic    [7:0]   wr_addr,
    output logic        [7:0]   rd_data,
    input wire logic    [7:0]   rd_addr,
    output logic        [7:0]   test_data,
    input wire logic    [15:0]  test_addr,
    output logic        [3:0]   VGA_R,
    output logic        [3:0]   VGA_G,
    output logic        [3:0]   VGA_B,
    output logic                VGA_hsync,
    output logic                VGA_vsync,
    output logic        [15:0]  percievedSwitches
);

    //Rendering signals
    logic                   draw_out;
    logic           [7:0]   x_out;
    logic           [7:0]   y_out;
    logic           [1:0]   color_out;
    logic           [7:0]   render_addr;
    logic           [7:0]   render_data;
    
    //Buffer Handshake signals
    logic                   swapBuffer;
    logic                   bufferSwapped;

    //VRAM contains pointers and sprites
    VideoRam #(16'hE8A5) VideoRam_inst (
        .clk(clk),
        .reset(reset),
        .wr_en(wr_en),
        .rd_addr1(render_addr),
        .rd_data1(render_data),
        .rd_addr2(rd_addr),
        .rd_data2(rd_data),
        .test_addr(test_addr),
        .test_data(test_data),
        .wr_addr(wr_addr),
        .wr_data(wr_data)
    );

    //Translates vram into a screen buffer
    VramRender Render_inst(
        .clk(clk),
        .reset(reset),
        .refresh(refresh_en),
        .draw(draw_out),
        .color(color_out),
        .rd_addr(render_addr),
        .rd_data(render_data),
        .x_out(x_out),
        .y_out(y_out),
        .swapBuffer(swapBuffer),
        .bufferSwapped(bufferSwapped),
        .percievedSwitches(percievedSwitches)
    );

    //Creats a VGA video signal from an internal bitmap
    BitmapToVga BitVGA_inst(
        .clk(clk),
        .clk_vga(clk_vga),
        .reset(reset),
        .wr_en(draw_out),
        .x(x_out),
        .y(y_out),
        .color(color_out),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_hsync(VGA_hsync),
        .VGA_vsync(VGA_vsync),
        .swapBuffer(swapBuffer),
        .bufferSwapped(bufferSwapped)
    );

endmodule
  