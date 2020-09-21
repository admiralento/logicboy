/***************************************************************************
*
* Module: LogicBoy
*
* Author: Ammon Wolfert
* Date: November 23, 2019
*
* Description: An FPGA implemented game console based on the Nintendo GameBoy
*
****************************************************************************/
`default_nettype none

module LogicBoy(
    input wire logic        CPU_RESETN,
    input wire logic        clk,
    input wire logic        btnu,
    input wire logic        btnd,
    input wire logic        btnc,
    input wire logic        btnl,
    input wire logic        btnr,
    input wire logic[15:0]  sw,
    output logic    [3:0]   VGA_R,
    output logic    [3:0]   VGA_G,
    output logic    [3:0]   VGA_B,
    output logic            VGA_HS,
    output logic            VGA_VS,
    output logic    [15:0]  led,
    output logic    [7:0]   anode,
    output logic    [7:0]   segment
    );
    
    localparam cpuEnabled = 1;

    ////////// Global Signals ////////

    logic                   clk_100;
    logic                   clk_25;
    logic           [7:0]   data_output_bus;
    logic                   reset;

    assign reset = ~CPU_RESETN;
    
    
    //////// CPU Signals ////////
    logic           [7:0]   address_bus_CPU;
    logic           [7:0]   data_from_CPU_bus;
    logic                   memoryWriteEnable;
    logic                   interrupt;

    //////// Pixel Processor Signals ////////
    logic           [7:0]   writeVRAMaddress;
    logic           [7:0]   writeVRAMdata;
    logic                   writeVRAMen;
    logic           [7:0]   readVRAMaddress;
    logic           [7:0]   readVRAMdata;
    logic           [15:0]  testVRAMaddress;
    logic           [7:0]   testVRAMdata;
    logic                   refresh_screen;
    
    /////// General Ram Signals ////////////
    logic           [7:0]   writeGRAMaddress;
    logic           [7:0]   writeGRAMdata;
    logic           [7:0]   readGRAMdata;
    logic                   writeGRAMen;

    ////// Pixel Processor Test Moudle //////
    logic           [7:0]   writeTestAddress;
    logic           [7:0]   writeTestData;
    logic                   writeTestEn;
    logic                   runTestModule;
    logic                   testDone;
    
    ///////////// ROM Signals //////////////
    logic           [7:0]   readROMdata;
    
    //////// Memory Multiplexer Signals ///
    logic           [7:0]   address_bus_MM;
    logic           [7:0]   data_input_bus;
    logic                   memoryWriteEnable_MM;
    
    ////// Input Reader Moudle //////
    logic           [7:0]   userInputAddress;
    logic           [7:0]   userInputData;
    logic                   userInputEn;
    logic                   runInputModule;
    logic                   userInputDone;
    
    logic           [7:0]   buttonState;

    assign runTestModule = ~testDone;
    assign refresh_screen = testDone;
    assign runInputModule = testDone;
    
    /////////// Signal Routing /////////
    always_comb begin
        testVRAMaddress = sw;
        if (~testDone) begin
            memoryWriteEnable_MM = writeTestEn;
            data_input_bus = writeTestData;
            address_bus_MM = writeTestAddress;
        end else if (cpuEnabled) begin
            memoryWriteEnable_MM = memoryWriteEnable;
            data_input_bus = data_from_CPU_bus;
            address_bus_MM = address_bus_CPU;
        end else begin
            memoryWriteEnable_MM = userInputEn;
            data_input_bus = userInputData;
            address_bus_MM = userInputAddress;
        end
    end
    
    CPU CPU_inst (
        .clk(clk_100),
        .reset(reset),
        .data_in_bus(data_output_bus),
        .data_out_bus(data_from_CPU_bus),
        .address_bus(address_bus_CPU),
        .wr_en(memoryWriteEnable),
        .interrupt(interrupt),
        .run(cpuEnabled && testDone)
    );
    
    MemoryMultiplexer MM_inst (
        .clk(clk_100),
        .reset(reset),
        .address_bus(address_bus_MM),
        .readROMdata(readROMdata),
        .readGRAMdata(readGRAMdata),
        .readVRAMdata(readVRAMdata),
        .data_out_bus(data_output_bus), //Read Memory Goes Here
        .wr_en(memoryWriteEnable_MM),   
        .wr_en_GRAM(writeGRAMen),
        .wr_en_VRAM(writeVRAMen)
    );

    PixelProcessor PixelProcessor_inst (
        .clk(clk_100),
        .clk_vga(clk_25),
        .reset(reset),
        .refresh_en(refresh_screen),
        .wr_en(writeVRAMen),
        .wr_data(data_input_bus),
        .wr_addr(address_bus_MM),
        .rd_data(readVRAMdata),
        .rd_addr(address_bus_MM),
        .test_addr(testVRAMaddress),
        .test_data(testVRAMdata),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_hsync(VGA_HS),
        .VGA_vsync(VGA_VS),
        .percievedSwitches(led)
    );
    
    //8 Kilobytes       0xc800 - 0xe7ff
    GeneralRam #(16'hc800, 16'h2000) GeneralRam_inst (
        .clk(clk_100),
        .reset(reset),
        .wr_en(writeGRAMen),
        .wr_addr(address_bus_MM),
        .wr_data(data_input_bus),
        .rd_addr(address_bus_MM),
        .rd_data(readGRAMdata)
    );
    
    //8 Kilobytes       0xc800 - 0xe7ff
    ReadOnlyMemory #(16'h0000) ROM_inst (
        .clk(clk_100),
        .reset(reset),
        .rd_addr(address_bus_MM),
        .rd_data(readROMdata)
    );

    ppTestModule ppTestModule_inst(
        .start(runTestModule),
        .clk(clk_100),
        .reset(reset),
        .done(testDone),
        .wr_addr(writeTestAddress),
        .wr_data(writeTestData),
        .wr_en(writeTestEn),
        .sw(sw)
    );
    
    InputReader InputReader_inst(
        .start(runInputModule),
        .clk(clk_100),
        .reset(reset),
        .done(userInputDone),
        .wr_addr(userInputAddress),
        .wr_data(userInputData),
        .wr_en(userInputEn),
        .buttons(buttonState),
        .sw(sw)
    );

    ButtonDebounce ButtonDebounce_inst (
        .clk(clk_100),
        .reset(reset),
        .btnc(btnc),
        .btnu(btnu),
        .btnd(btnd),
        .btnl(btnl),
        .btnr(btnr),
        .buttonState(buttonState)
    );

    clk_generator clk_generator_inst (
        .clk_100(clk_100),
        .clk_25(clk_25),
        .clk_in_100(clk)
    );
    
    SevenSegmentControl ssc_inst (
        .clk(clk_100),
        .reset(reset),
        .dataIn({sw, 8'b0, testVRAMdata}),
        .digitDisplay(8'b11110011),
        .digitPoint(8'b00000000),
        .anode(anode),
        .segment(segment)
    );

endmodule
