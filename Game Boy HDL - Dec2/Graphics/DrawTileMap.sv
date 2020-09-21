/***************************************************************************
*
* Module: DrawTileMap
*
* Author: Ammon Wolfert
* Date: November 23, 2019
*
* Description: Reads tile map data from VRAM and then writes that
*              data to the VGA buffer to be displayed on screen.
*
****************************************************************************/
`default_nettype none

module DrawTileMap(
    input wire logic            clk,
    input wire logic            reset,
    input wire logic            start,
    output logic                draw,
    output logic                done,
    input wire logic    [7:0]   window_x,
    input wire logic    [7:0]   window_y,
    input wire logic    [7:0]   rd_data,
    output logic        [7:0]   rd_addr,
    output logic        [7:0]   x_out,
    output logic        [7:0]   y_out,
    output logic        [1:0]   color
    );

    ///////// Configuration Signals ////////
    localparam                  VGA_X = 160;
    localparam                  VGA_Y = 120;
    localparam                  POINTER_TABLE_ADDR = 16'hE8A8;  //Place in Memory where Tile Pointer Table is stored
    localparam                  TILES_X = 21;
    localparam                  TILES_Y = 16;

    //////////// Registers ////////////
    logic               [7:0]   pointerRegister [2];
    logic                       loadPointerReg;
    logic               [15:0]  fullPointer;

    logic               [7:0]   colorRegister   [2];
    logic                       loadColorReg;

    assign fullPointer = {pointerRegister[1], pointerRegister[0]};

    ShiftRegister #(8,2) pointerRegisterModule (
        .clk    (clk),
        .reset  (reset),
        .clr    (1'b0),
        .load   (loadPointerReg),
        .din    (rd_data),
        .dout   (pointerRegister)
    );

    ShiftRegister #(8,2) colorRegisterModule (
        .clk    (clk),
        .reset  (reset),
        .clr    (1'b0),
        .load   (loadColorReg),
        .din    (rd_data),
        .dout   (colorRegister)
    );

    ///////////// Counters ////////////////
    logic   [$clog2(TILES_X) - 1:0]   tileXCount;
    logic   [$clog2(TILES_Y) - 1:0]   tileYCount;
    logic                       incTileCount;
    logic                       clrTileCount;
    logic                       rstTileCount;

    logic                       newTileRow;
    logic                       tilesDone;

    logic               [2:0]   lineCount;
    logic                       clrLineCount;
    logic                       incLineCount;

    logic               [2:0]   bitCount;
    logic                       clrBitCount;
    logic                       incBitCount;

    logic               [7:0]   cycleCount;
    logic                       clrCycleCount;
    logic                       incCycleCount;

    logic               [7:0]   byteCount;
    logic                       clrByteCount;
    logic                       incByteCount;

    assign rstTileCount = reset || clrTileCount;

    mod_counter #(TILES_X) tileX (
        .clk(clk),                  .reset(rstTileCount),
        .increment(incTileCount),  .rolling_over(newTileRow),
        .count(tileXCount)
    );
    mod_counter #(TILES_Y) tileY (
        .clk(clk),          .reset(rstTileCount),
        .increment(newTileRow), .rolling_over(tilesDone),
        .count(tileYCount)
    );

    CCounter #(3) lineCounter (
        .clk    (clk),
        .reset  (reset),
        .clr    (clrLineCount),
        .inc    (incLineCount),
        .dout   (lineCount)
    );

    CCounter #(3) bitCounter (
        .clk    (clk),
        .reset  (reset),
        .clr    (clrBitCount),
        .inc    (incBitCount),
        .dout   (bitCount)
    );

    CCounter #(8) cycleCounter (
        .clk    (clk),
        .reset  (reset),
        .clr    (clrCycleCount),
        .inc    (incCycleCount),
        .dout   (cycleCount)
    );

    CCounter #(8) byteCounter (
        .clk    (clk),
        .reset  (reset),
        .clr    (clrByteCount),
        .inc    (incByteCount),
        .dout   (byteCount)
    );

    ////////// Address Access Varibles /////////
    logic               [9:0]   originTileAddress;
    logic               [9:0]   tileOffset;

    logic               [15:0]  tileEntryAddress;
    logic               [15:0]  tileEntryByteAddress;
    logic               [15:0]  tilePixelAddress;
    logic               [15:0]  tilePixelByteAddress;

    assign originTileAddress = {window_y[7:3], window_x[7:3]};  // 2020 MAY AMMON CHANGED THIS
    assign tileOffset = {tileYCount, tileXCount};

    assign tileEntryAddress = POINTER_TABLE_ADDR + {(originTileAddress + tileOffset), 1'b0};
    assign tileEntryByteAddress = tileEntryAddress + byteCount;
    assign tilePixelAddress = fullPointer + {lineCount, 1'b0};
    assign tilePixelByteAddress = tilePixelAddress + byteCount;

    ////////////// State Machine ///////////////
    typedef enum logic[2:0] {init, getRegisters, getTileLine, drawTile, finished, ERR = 'X} State;
    State cs, ns;

    always_comb begin
        //default values
        ns = ERR;
        color = 'X;
        x_out = 'X;
        y_out = 'X;
        rd_addr = 'X;

        draw = 0;
        done = 0;

        incTileCount = 0;
        clrTileCount = 0;

        incLineCount = 0;
        clrLineCount = 0;

        incBitCount = 0;
        clrBitCount = 0;

        incCycleCount = 0;
        clrCycleCount = 0;

        incByteCount = 0;
        clrByteCount = 0;

        loadPointerReg = 0;
        loadColorReg = 0;

        case (cs)
            init: begin
                /*
                    Wait for the start signal before preceding.
                */
                if (start) begin
                    ns = getRegisters;
                end else begin
                    ns = init;
                end
            end

            getRegisters: begin
                /*
                    Retrieve the tile's pointer to the color data.
                */
                incCycleCount = 1;
                ns = getRegisters;
                case (cycleCount)
                    0: begin
                        rd_addr = tileEntryAddress[15:8];
                    end
                    1: begin
                        rd_addr = tileEntryAddress[7:0];
                        incByteCount = 1;
                    end
                    2: begin
                        loadPointerReg = 1;
                        rd_addr = tileEntryByteAddress[15:8];
                    end
                    3: begin
                        rd_addr = tileEntryByteAddress[7:0];
                    end
                    4: begin
                        loadPointerReg = 1;
                        clrCycleCount = 1;
                        clrByteCount = 1;
                        ns = getTileLine;
                    end
                endcase
            end

            getTileLine: begin
                /*
                    Using the tiles's pointer, retrieve the two bytes of
                    color data for one line.
                */
                incCycleCount = 1;
                ns = getTileLine;
                case (cycleCount)
                    0: begin
                        rd_addr = tilePixelAddress[15:8];
                    end
                    1: begin
                        rd_addr = tilePixelAddress[7:0];
                        incByteCount = 1;
                    end
                    2: begin
                        loadColorReg = 1;
                        rd_addr = tilePixelByteAddress[15:8];
                    end
                    3: begin
                        rd_addr = tilePixelByteAddress[7:0];
                    end
                    4: begin
                        loadColorReg = 1;
                        clrCycleCount = 1;
                        clrByteCount = 1;
                        ns = drawTile;
                    end
                endcase
            end

            drawTile: begin
                /*
                    Calculate the x and y coordiantes of the pixel to
                    draw based on the window location, current line,
                    and current bit. Read the reterieved color data and write to
                    the VGA buffer if on screen.
                */
                x_out = {originTileAddress[4:0] + tileOffset[4:0], 3'b000} - window_x + bitCount;
                y_out = {originTileAddress[9:5] + tileOffset[9:5], 3'b000} - window_y + lineCount;

                color = {colorRegister[1][7 - bitCount], colorRegister[0][7 - bitCount]};
                draw = (x_out >= 0 && x_out < VGA_X) && (y_out >= 0 && y_out < VGA_Y);

                incBitCount = 1;
                ns = drawTile;
                if (bitCount == 7) begin
                    incLineCount = 1;
                    ns = getTileLine;
                    if (lineCount == 7) begin
                        incTileCount = 1;
                        ns = getRegisters;
                        if (tilesDone) begin
                            ns = finished;
                        end
                    end
                end
            end

            finished: begin
                done = 1;
                if (!start) begin
                    ns = init;
                end else begin
                    ns = finished;
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

endmodule
