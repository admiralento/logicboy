/***************************************************************************
*
* Module: VramRender
*
* Author: Ammon Wolfert
* Date: November 23, 2019
*
* Description: Writes Vram data to the screen buffer
*
****************************************************************************/
`default_nettype none

module VramRender(
    input wire logic            clk,
    input wire logic            refresh,
    input wire logic            reset,
    output logic                draw,
    output logic        [7:0]   rd_addr,
    input wire logic    [7:0]   rd_data,
    output logic        [7:0]   x_out,
    output logic        [7:0]   y_out,
    output logic        [1:0]   color,
    output logic                swapBuffer,
    input wire logic            bufferSwapped,
    output logic        [15:0]  percievedSwitches
    );

    localparam          WINDOW_X_ADDR = 16'hE8A5;   //Location in Memory where the Window_X_Offset is stored
    localparam          WINDOW_Y_ADDR = 16'hE8A6;   //Location in Memory where the Window_Y_Offset is stored
    localparam          SETTINGS_ADDR = 16'hE8A7;   //Location in Memory where the Settings Byte is stored
    
    ////////// Settings Byte //////////
    // Bit 0 - Enable Window Layer

    ////////// Tilemap Varibles ///////
    logic                       tileStart;
    logic                       tileDone;
    logic                       tileEnDraw;
    logic               [7:0]   tileAddr;
    logic               [7:0]   tileData;
    logic               [7:0]   tileXOut;
    logic               [7:0]   tileYOut;
    logic               [1:0]   tileColor;

    ////// Window Layer Varibles //////
    logic                       windowStart;
    logic                       windowDone;
    logic                       windowEnDraw;
    logic               [7:0]   windowAddr;
    logic               [7:0]   windowData;
    logic               [7:0]   windowXOut;
    logic               [7:0]   windowYOut;
    logic               [1:0]   windowColor;

    ///////// Sprite Varibles /////////
    logic                       spriteStart;
    logic                       spriteDone;
    logic                       spriteEnDraw;
    logic               [7:0]   spriteAddr;
    logic               [7:0]   spriteData;
    logic               [7:0]   spriteXOut;
    logic               [7:0]   spriteYOut;
    logic               [1:0]   spriteColor;
    
    ///////// Button Varibles /////////
    logic                       buttonStart;
    logic                       buttonDone;
    logic                       buttonEnDraw;
    logic               [7:0]   buttonAddr;
    logic               [7:0]   buttonData;
    logic               [7:0]   buttonXOut;
    logic               [7:0]   buttonYOut;
    logic               [1:0]   buttonColor;

    /////////// Registers ///////////
    logic               [7:0]   windowXOffset;
    logic               [7:0]   windowYOffset;
    logic                       loadWindowXReg;
    logic                       loadWindowYReg;

    logic               [7:0]   cycleCount;
    logic                       clrCycleCount;
    logic                       incCycleCount;

    logic               [7:0]   settingsReg;
    logic                       loadSettingsReg;
    logic                       windowLayerEnabled;

    assign windowLayerEnabled = settingsReg[0];

    CLRegister #(8) windowXOffsetRegister (
        .clk    (clk),
        .reset  (reset),
        .clr    (1'b0),
        .load   (loadWindowXReg),
        .din    (rd_data),
        .dout   (windowXOffset)
    );

    CLRegister #(8) windowYOffsetRegister (
        .clk    (clk),
        .reset  (reset),
        .clr    (1'b0),
        .load   (loadWindowYReg),
        .din    (rd_data),
        .dout   (windowYOffset)
    );

    CLRegister #(8) settingsRegister (
        .clk    (clk),
        .reset  (reset),
        .clr    (1'b0),
        .load   (loadSettingsReg),
        .din    (rd_data),
        .dout   (settingsReg)
    );

    CCounter #(8) cyclesCounter (
        .clk    (clk),
        .reset  (reset),
        .clr    (clrCycleCount),
        .inc    (incCycleCount),
        .dout   (cycleCount)
    );

    ////////// State Machine //////////
    typedef enum logic[2:0] {init, getRegisters, tilemap, windowlayer, sprites, waitingForBufferSwap, drawButtonStates, ERR = 'X} State;
    State cs, ns;

    always_comb begin
        ns = ERR;
        x_out = 'X;
        y_out = 'X;
        color = 'X;
        rd_addr = 'X;
        
        tileData = 'X;
        windowData = 'X;
        spriteData = 'X;
        buttonData = 'X;

        draw = 0;

        tileStart = 0;
        windowStart = 0;
        spriteStart = 0;
        buttonStart = 0;

        loadWindowXReg = 0;
        loadWindowYReg = 0;
        loadSettingsReg = 0;

        incCycleCount = 0;
        clrCycleCount = 0;
        
        swapBuffer = 0;

        case (cs)
            init: begin
                if (refresh) begin
                    ns = getRegisters;
                    clrCycleCount = 1;
                end else begin
                    ns = init;
                end
            end

            //Read the settings registers 0x0000 - 0x0002 
            getRegisters: begin
                incCycleCount = 1;
                ns = getRegisters;
                case (cycleCount)
                    0: begin
                        rd_addr = WINDOW_X_ADDR[15:8];
                    end
                    1: begin
                        rd_addr = WINDOW_X_ADDR[7:0];
                    end
                    2: begin
                        loadWindowXReg = 1;
                        rd_addr = WINDOW_Y_ADDR[15:8];
                    end
                    3: begin
                        rd_addr = WINDOW_Y_ADDR[7:0];
                    end
                    4: begin
                        loadWindowYReg = 1;
                        rd_addr = SETTINGS_ADDR[15:8];
                    end
                    5: begin
                        rd_addr = SETTINGS_ADDR[7:0];
                    end
                    6: begin
                        loadSettingsReg = 1;
                        clrCycleCount = 1;
                        ns = tilemap;
                    end
                endcase
            end

            //Route VRAM and Screen Bufffer communication to the DrawTileMap Module
            //And enable it's operation
            tilemap: begin
                rd_addr = tileAddr;
                tileData = rd_data;
                x_out = tileXOut;
                y_out = tileYOut;
                draw = tileEnDraw;
                color = tileColor;
                if (tileDone) begin
                    if (windowLayerEnabled) begin
                        ns = windowlayer;
                    end else begin
                        ns = sprites;
                    end
                end else begin
                    tileStart = 1;
                    ns = tilemap;
                end
            end

            //Route VRAM and Screen Bufffer communication to the DrawWindowLayer Module
            //And enable it's operation
            windowlayer: begin
                rd_addr = windowAddr;
                windowData = rd_data;
                x_out = windowXOut;
                y_out = windowYOut;
                draw = windowEnDraw;
                color = windowColor;
                if (windowDone) begin
                    ns = sprites;
                end else begin
                    windowStart = 1;
                    ns = windowlayer;
                end
            end

            //Route VRAM and Screen Bufffer communication to the DrawSprites Module
            //And enable it's operation
            sprites: begin
                rd_addr = spriteAddr;
                spriteData = rd_data;
                x_out = spriteXOut;
                y_out = spriteYOut;
                draw = spriteEnDraw;
                color = spriteColor;
                if (spriteDone) begin
                    ns = drawButtonStates;
                end else begin
                    spriteStart = 1;
                    ns = sprites;
                end
            end
            
            //Draws Button States to screen for debug
            drawButtonStates: begin
                rd_addr = buttonAddr;
                buttonData = rd_data;
                x_out = buttonXOut;
                y_out = buttonYOut;
                draw = buttonEnDraw;
                color = buttonColor;
                if (buttonDone) begin
                    ns = waitingForBufferSwap;
                end else begin
                    buttonStart = 1;
                    ns = drawButtonStates;
                end
            end
            
            //Waits for current frame to finish displaying, then swaps the buffer
            waitingForBufferSwap: begin
                swapBuffer = 1;
                if (bufferSwapped) begin
                    ns = init;
                end else begin
                    ns = waitingForBufferSwap;
                end
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

    DrawTileMap DrawTileMap_inst(
        .clk        (clk),
        .reset      (reset),
        .start      (tileStart),
        .window_x   (windowXOffset),
        .window_y   (windowYOffset),
        .rd_addr    (tileAddr),
        .rd_data    (tileData),
        .done       (tileDone),
        .x_out      (tileXOut),
        .y_out      (tileYOut),
        .draw       (tileEnDraw),
        .color      (tileColor)
    );

    DrawWindowLayer DrawWindowLayer_inst(
        .clk        (clk),
        .reset      (reset),
        .start      (windowStart),
        .rd_addr    (windowAddr),
        .rd_data    (windowData),
        .done       (windowDone),
        .x_out      (windowXOut),
        .y_out      (windowYOut),
        .draw       (windowEnDraw),
        .color      (windowColor)
    );

    DrawSprites DrawSprites_inst(
        .clk        (clk),
        .reset      (reset),
        .start      (spriteStart),
        .window_x   (windowXOffset),
        .window_y   (windowYOffset),
        .rd_addr    (spriteAddr),
        .rd_data    (spriteData),
        .done       (spriteDone),
        .x_out      (spriteXOut),
        .y_out      (spriteYOut),
        .draw       (spriteEnDraw),
        .color      (spriteColor)
    );
    
    DrawButtons DrawButtons_inst(
        .clk        (clk),
        .reset      (reset),
        .start      (buttonStart),
        .rd_addr    (buttonAddr),
        .rd_data    (buttonData),
        .done       (buttonDone),
        .x_out      (buttonXOut),
        .y_out      (buttonYOut),
        .draw       (buttonEnDraw),
        .color      (buttonColor),
        .percievedSwitches(percievedSwitches)
    );


endmodule
