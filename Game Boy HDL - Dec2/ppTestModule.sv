/***************************************************************************
*
* Module: ppTestModule
*
* Author: Ammon Wolfert
* Date: November 25, 2019
*
* Description: Tests the PixelProcessor, writes a test sprite to all tiles
*
****************************************************************************/
`default_nettype none

module ppTestModule(
    input wire logic            clk,
    input wire logic            reset,
    input wire logic            start,
    input wire logic    [15:0]  sw,
    output logic                done,
    output logic        [7:0]   wr_addr,
    output logic        [7:0]   wr_data,
    output logic                wr_en
    );
    
    localparam          RAM_ADDR = 16'hc800;
    
    localparam          WINDOW_X_ADDR = 16'hE8A5;
    logic     [7:0]     WINDOW_X_VAL;
    localparam          WINDOW_Y_ADDR = 16'hE8A6;
    logic     [7:0]     WINDOW_Y_VAL;
    localparam          SETTINGS_ADDR = 16'hE8A7;
    localparam          SETTINGS_VAL = 8'b00000001;
    localparam          TILE_POINTER_TABLE_ADDR = 16'hE8A8;
    localparam          WINDOW_POINTER_TABLE_ADDR = 16'hF0A8;
    localparam          SPRITE_POINTER_TABLE_ADDR = 16'hF300;
    
    localparam          SPRITE_DATA_ADDR = 16'hF800;
    
    assign WINDOW_X_VAL = sw[15:8];
    assign WINDOW_Y_VAL = sw[7:0];

    logic       [7:0]   spriteMap [4][16];
    
    //Pokeball
    /*
    assign spriteMap[0][0] = 8'h3C;
    assign spriteMap[0][1] = 8'h3C;
    assign spriteMap[0][2] = 8'h7E;
    assign spriteMap[0][3] = 8'h66;
    assign spriteMap[0][4] = 8'hFF;
    assign spriteMap[0][5] = 8'hC3;
    assign spriteMap[0][6] = 8'hE7;
    assign spriteMap[0][7] = 8'h99;
    assign spriteMap[0][8] = 8'hE7;
    assign spriteMap[0][9] = 8'h99;
    assign spriteMap[0][10] = 8'hFF;
    assign spriteMap[0][11] = 8'hC3;
    assign spriteMap[0][12] = 8'h7E;
    assign spriteMap[0][13] = 8'h66;
    assign spriteMap[0][14] = 8'h3C;
    assign spriteMap[0][15] = 8'h3C;
    */
    //Dark Tile
    assign spriteMap[0][0] = 8'h00;
    assign spriteMap[0][1] = 8'h00;
    assign spriteMap[0][2] = 8'h00;
    assign spriteMap[0][3] = 8'h00;
    assign spriteMap[0][4] = 8'h00;
    assign spriteMap[0][5] = 8'h00;
    assign spriteMap[0][6] = 8'h00;
    assign spriteMap[0][7] = 8'h00;
    assign spriteMap[0][8] = 8'h00;
    assign spriteMap[0][9] = 8'h00;
    assign spriteMap[0][10] = 8'h00;
    assign spriteMap[0][11] = 8'h00;
    assign spriteMap[0][12] = 8'h00;
    assign spriteMap[0][13] = 8'h00;
    assign spriteMap[0][14] = 8'h00;
    assign spriteMap[0][15] = 8'h00;
    
    //Monochromatic - Bright
    assign spriteMap[1][0] = 8'hFF;
    assign spriteMap[1][1] = 8'hFF;
    assign spriteMap[1][2] = 8'hFF;
    assign spriteMap[1][3] = 8'hFF;
    assign spriteMap[1][4] = 8'hFF;
    assign spriteMap[1][5] = 8'hFF;
    assign spriteMap[1][6] = 8'hFF;
    assign spriteMap[1][7] = 8'hFF;
    assign spriteMap[1][8] = 8'hFF;
    assign spriteMap[1][9] = 8'hFF;
    assign spriteMap[1][10] = 8'hFF;
    assign spriteMap[1][11] = 8'hFF;
    assign spriteMap[1][12] = 8'hFF;
    assign spriteMap[1][13] = 8'hFF;
    assign spriteMap[1][14] = 8'hFF;
    assign spriteMap[1][15] = 8'hFF;
    
    //Stripes
    assign spriteMap[2][0] = 8'hF0;
    assign spriteMap[2][1] = 8'hCC;
    assign spriteMap[2][2] = 8'hF0;
    assign spriteMap[2][3] = 8'hCC;
    assign spriteMap[2][4] = 8'hF0;
    assign spriteMap[2][5] = 8'hCC;
    assign spriteMap[2][6] = 8'hF0;
    assign spriteMap[2][7] = 8'hCC;
    assign spriteMap[2][8] = 8'hF0;
    assign spriteMap[2][9] = 8'hCC;
    assign spriteMap[2][10] = 8'hF0;
    assign spriteMap[2][11] = 8'hCC;
    assign spriteMap[2][12] = 8'hF0;
    assign spriteMap[2][13] = 8'hCC;
    assign spriteMap[2][14] = 8'hF0;
    assign spriteMap[2][15] = 8'hCC;
    
    //Test Sprite
    assign spriteMap[3][0] = 8'h00;
    assign spriteMap[3][1] = 8'h00;
    assign spriteMap[3][2] = 8'h18;
    assign spriteMap[3][3] = 8'h3C;
    assign spriteMap[3][4] = 8'h18;
    assign spriteMap[3][5] = 8'h7E;
    assign spriteMap[3][6] = 8'h3E;
    assign spriteMap[3][7] = 8'h5E;
    assign spriteMap[3][8] = 8'h3E;
    assign spriteMap[3][9] = 8'h5E;
    assign spriteMap[3][10] = 8'h18;
    assign spriteMap[3][11] = 8'h66;
    assign spriteMap[3][12] = 8'h00;
    assign spriteMap[3][13] = 8'h3C;
    assign spriteMap[3][14] = 8'h00;
    assign spriteMap[3][15] = 8'h00;

    logic       [15:0]   byteCount;
    logic               incByteCount;
    logic               clrByteCount;

    logic       [15:0]   cycleCount;
    logic               incCycleCount;
    logic               clrCycleCount;

    logic       [15:0]  currentSpriteAddr;
    logic       [15:0]  currentTilePointerAddr;
    logic       [15:0]  currentWindowPointerAddr;
    logic       [15:0]  currentSpritePointerAddr;

    assign currentSpriteAddr = SPRITE_DATA_ADDR + byteCount;
    assign currentTilePointerAddr = TILE_POINTER_TABLE_ADDR + byteCount;
    assign currentWindowPointerAddr = WINDOW_POINTER_TABLE_ADDR + byteCount;
    assign currentSpritePointerAddr = SPRITE_POINTER_TABLE_ADDR + byteCount;
    
    CCounter #(16) cycleCounter (
        .clk    (clk),
        .reset  (reset),
        .clr    (clrCycleCount),
        .inc    (incCycleCount),
        .dout   (cycleCount)
    );

    CCounter #(16) byteCounter (
        .clk    (clk),
        .reset  (reset),
        .clr    (clrByteCount),
        .inc    (incByteCount),
        .dout   (byteCount)
    );
    
    logic [15:0] byteCountPlusRAMOffset;
    assign byteCountPlusRAMOffset = byteCount + RAM_ADDR;

    ///////// State Machine //////////
    typedef enum logic[3:0] {init, voidMemory, writeSettings, writeSpriteTile, writeSpriteWindow, writeSpritePlayer,
        writeTilePointers, writeWindowPointers, writeSpritePointers, finished, ERR = 'X} State;
    State cs, ns;

    //Helper signals
    logic       [7:0]   cycleDelay2;
    assign cycleDelay2 = cycleCount - 2;

    always_comb begin
        ns = ERR;
        wr_addr = 'X;
        wr_data = 'X;

        wr_en = 0;
        done = 0;

        incByteCount = 0;
        incCycleCount = 0;

        clrByteCount = 0;
        clrCycleCount = 0;

        case (cs)
            init: begin
                if (start) begin
                    ns = voidMemory;
                    clrCycleCount = 1;
                    clrByteCount = 1;
                end else begin
                    ns = init;
                end
            end
            
            voidMemory: begin
                incCycleCount = 1;
                ns = voidMemory;
                if (cycleCount == 0) begin
                    wr_addr = byteCountPlusRAMOffset[15:8];
                end else begin
                    case (cycleCount[0])
                        0: begin
                            wr_addr = byteCountPlusRAMOffset[15:8];
                            wr_data = 8'b0;
                            wr_en = 1;
                            if (byteCountPlusRAMOffset == 16'hFFFF) begin
                                ns = writeSettings;
                                clrCycleCount = 1;
                                clrByteCount = 1;
                            end
                        end
                        1: begin
                            wr_addr = byteCountPlusRAMOffset[7:0];
                            incByteCount = 1;
                        end
                    endcase
                end
            end

            writeSettings: begin
                incCycleCount = 1;
                ns = writeSettings;
                case (cycleCount)
                    0: begin
                        wr_addr = WINDOW_X_ADDR[15:8];
                    end
                    1: begin
                        wr_addr = WINDOW_X_ADDR[7:0];
                    end
                    2: begin
                        wr_data = WINDOW_X_VAL;
                        wr_en = 1;
                        wr_addr = WINDOW_Y_ADDR[15:8];
                    end
                    3: begin
                        wr_addr = WINDOW_Y_ADDR[7:0];
                    end
                    4: begin
                        wr_data = WINDOW_Y_VAL;
                        wr_en = 1;
                        wr_addr = SETTINGS_ADDR[15:8];
                    end
                    5: begin
                        wr_addr = SETTINGS_ADDR[7:0];
                    end
                    6: begin
                        wr_data = SETTINGS_VAL;
                        wr_en = 1;
                        clrCycleCount = 1;
                        clrByteCount = 1;
                        ns = writeSpriteTile;
                    end
                endcase
            end

            writeSpriteTile: begin
                incCycleCount = 1;
                ns = writeSpriteTile;
                if (cycleCount == 0) begin
                    wr_addr = SPRITE_DATA_ADDR[15:8];
                end else begin
                    case (cycleCount[0])
                        0: begin
                            wr_data = spriteMap[2][byteCount - 1];
                            wr_en = 1;
                            if (byteCount == 16) begin
                                ns = writeSpriteWindow;
                                clrCycleCount = 1;
                                clrByteCount = 1;
                            end else begin
                                wr_addr = currentSpriteAddr[15:8];
                            end
                        end
                        1: begin
                            wr_addr = currentSpriteAddr[7:0];
                            incByteCount = 1;
                        end
                    endcase
                end
            end
            
            writeSpriteWindow: begin
                incCycleCount = 1;
                ns = writeSpriteWindow;
                if (cycleCount == 0) begin
                    wr_addr = SPRITE_DATA_ADDR[15:8];
                end else begin
                    case (cycleCount[0])
                        0: begin
                            wr_data = spriteMap[1][byteCount - 1];
                            wr_en = 1;
                            if (byteCount == 16) begin
                                ns = writeSpritePlayer;
                                clrCycleCount = 1;
                                clrByteCount = 1;
                            end else begin
                                wr_addr = currentSpriteAddr[15:8];
                            end
                        end
                        1: begin
                            wr_addr = currentSpriteAddr[7:0] + 16;  //Quick and Dirty Fix, wont always work
                            incByteCount = 1;
                        end
                    endcase
                end
            end
            
            writeSpritePlayer: begin
                incCycleCount = 1;
                ns = writeSpritePlayer;
                if (cycleCount == 0) begin
                    wr_addr = SPRITE_DATA_ADDR[15:8];
                end else begin
                    case (cycleCount[0])
                        0: begin
                            wr_data = spriteMap[3][byteCount - 1];
                            wr_en = 1;
                            if (byteCount == 16) begin
                                ns = writeTilePointers;
                                clrCycleCount = 1;
                                clrByteCount = 1;
                            end else begin
                                wr_addr = currentSpriteAddr[15:8];
                            end
                        end
                        1: begin
                            wr_addr = currentSpriteAddr[7:0] + 32;  //Quick and Dirty Fix, wont always work
                            incByteCount = 1;
                        end
                    endcase
                end
            end

            writeTilePointers: begin
                incCycleCount = 1;
                ns = writeTilePointers;
                if (cycleCount < 2) begin
                    case (cycleCount)
                        0: begin
                            wr_addr = currentTilePointerAddr[15:8];
                        end
                        1: begin
                            wr_addr = currentTilePointerAddr[7:0];
                            incByteCount = 1;
                        end
                    endcase
                end else begin
                    case (cycleDelay2[1:0])
                        0: begin
                            wr_data = SPRITE_DATA_ADDR[15:8];
                            wr_en = 1;
                            wr_addr = currentTilePointerAddr[15:8];
                        end
                        1: begin
                            wr_addr = currentTilePointerAddr[7:0];
                            incByteCount = 1;
                        end
                        2: begin
                            wr_data = SPRITE_DATA_ADDR[7:0];
                            wr_en = 1;
                            if (byteCount == 2048) begin
                                ns = writeWindowPointers;
                                clrCycleCount = 1;
                                clrByteCount = 1;
                            end else begin
                                wr_addr = currentTilePointerAddr[15:8];
                            end
                        end
                        3: begin
                            wr_addr = currentTilePointerAddr[7:0];
                            incByteCount = 1;
                        end
                    endcase
                end
            end
            
            writeWindowPointers: begin
                incCycleCount = 1;
                ns = writeWindowPointers;
                if (cycleCount < 2) begin
                    case (cycleCount)
                        0: begin
                            wr_addr = currentWindowPointerAddr[15:8];
                        end
                        1: begin
                            wr_addr = currentWindowPointerAddr[7:0];
                            incByteCount = 1;
                        end
                    endcase
                end else begin
                    case (cycleDelay2[1:0])
                        0: begin
                            wr_data = (byteCount >= 560) ? SPRITE_DATA_ADDR[15:8] : 8'b0;
                            wr_en = 1;
                            wr_addr = currentWindowPointerAddr[15:8];
                        end
                        1: begin
                            wr_addr = currentWindowPointerAddr[7:0];
                            incByteCount = 1;
                        end
                        2: begin
                            wr_data = (byteCount >= 561) ? SPRITE_DATA_ADDR[7:0] + 16 : 8'b0;
                            wr_en = 1;
                            if (byteCount == 600) begin
                                ns = writeSpritePointers;
                                clrCycleCount = 1;
                                clrByteCount = 1;
                            end else begin
                                wr_addr = currentWindowPointerAddr[15:8];
                            end
                        end
                        3: begin
                            wr_addr = currentWindowPointerAddr[7:0];
                            incByteCount = 1;
                        end
                    endcase
                end
            end
            
            writeSpritePointers: begin
                incCycleCount = 1;
                ns = writeSpritePointers;
                case (cycleCount)
                    0: begin
                        wr_addr = currentSpritePointerAddr[15:8];
                    end
                    1: begin
                        wr_addr = currentSpritePointerAddr[7:0];
                        incByteCount = 1;
                    end
                    2: begin    //Write the MSByte of the graphical data pointer
                        wr_data = SPRITE_DATA_ADDR[15:8];
                        wr_en = 1;
                        wr_addr = currentSpritePointerAddr[15:8];
                    end
                    3: begin
                        wr_addr = currentSpritePointerAddr[7:0];
                        incByteCount = 1;
                    end
                    4: begin    //Write the LSByte of the graphical data pointer
                        wr_data = SPRITE_DATA_ADDR[7:0] + 32;
                        wr_en = 1;
                        wr_addr = currentSpritePointerAddr[15:8];
                    end
                    5: begin
                        wr_addr = currentSpritePointerAddr[7:0];
                        incByteCount = 1;
                    end
                    6: begin    //Write the X position for the first sprite
                        wr_data = 8'h50;
                        wr_en = 1;
                        wr_addr = currentSpritePointerAddr[15:8];
                    end
                    7: begin
                        wr_addr = currentSpritePointerAddr[7:0];
                        incByteCount = 1;
                    end
                    8: begin    //Write the Y position for the first sprite
                        wr_data = 8'h32;
                        wr_en = 1;
                        wr_addr = currentSpritePointerAddr[15:8];
                    end
                    9: begin
                        wr_addr = currentSpritePointerAddr[7:0];
                        incByteCount = 1;
                    end
                    10: begin    //Write the Config byte for the first sprite
                        wr_data = 8'b00001100;
                        wr_en = 1;
                        ns = finished;
                        clrCycleCount = 1;
                        clrByteCount = 1;
                    end
                    
                endcase
            end

            finished: begin
                done = 1;
                ns = finished;
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
