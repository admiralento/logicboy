/***************************************************************************
*
* Module: DrawSprites
*
* Author: Ammon Wolfert
* Date: November 23, 2019
*
* Description: Reads sprite data from VRAM and then writes that
*              data to the VGA buffer to be displayed on screen.
*
****************************************************************************/
`default_nettype none

module DrawSprites(
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
    localparam                  POINTER_TABLE_ADDR = 16'hF300;
    localparam                  MAX_SPRITES = 256;

    ///////////// Registers ////////////////
    logic               [7:0]   pointerRegister     [2];
    logic                       loadPointerReg;
    logic               [15:0]  fullPointer;

    logic               [7:0]   xyRegister          [2];
    logic                       loadXYReg;
    logic               [7:0]   spriteX;
    logic               [7:0]   spriteY;

    logic               [7:0]   colorRegister       [2];
    logic                       loadColorReg;

    logic               [7:0]   propertiesRegister;
    logic                       loadPropReg;
    logic               [1:0]   alpha;
    logic                       reflectV;
    logic                       reflectH;

    assign fullPointer = {pointerRegister[1], pointerRegister[0]};
    assign spriteX = xyRegister[1];
    assign spriteY = xyRegister[0];
    assign alpha = propertiesRegister[1:0];
    assign reflectV = propertiesRegister[2];
    assign reflectH = propertiesRegister[3];

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

    ShiftRegister #(8,2) xyRegisterModule (
        .clk    (clk),
        .reset  (reset),
        .clr    (1'b0),
        .load   (loadXYReg),
        .din    (rd_data),
        .dout   (xyRegister)
    );

    CLRegister #(8) propertiesRegisterModule (
        .clk    (clk),
        .reset  (reset),
        .clr    (1'b0),
        .load   (loadPropReg),
        .din    (rd_data),
        .dout   (propertiesRegister)
    );

    ///////////// Counters ////////////////
    logic               [7:0]   spriteCount;
    logic                       clrSpriteCount;
    logic                       incSpriteCount;
    logic                       spritesDone;

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

    assign spritesDone = (spriteCount == MAX_SPRITES - 1);

    CCounter spriteCounter (
        .clk    (clk),
        .reset  (reset),
        .clr    (clrSpriteCount),
        .inc    (incSpriteCount),
        .dout   (spriteCount)
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
    logic               [15:0]  spriteEntryAddress;
    logic               [15:0]  spriteEntryByteAddress;
    logic               [15:0]  spritePixelAddress;
    logic               [15:0]  spritePixelByteAddress;

    assign spriteEntryAddress = POINTER_TABLE_ADDR + (spriteCount * 5);
    assign spriteEntryByteAddress = spriteEntryAddress + byteCount;
    assign spritePixelAddress = fullPointer + {lineCount, 1'b0};
    assign spritePixelByteAddress = spritePixelAddress + byteCount;

    ////////////// State Machine ///////////////
    typedef enum logic[3:0] {init, getRegisters, getSpriteLine, drawSprite, finished, ERR = 'X} State;
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

        incSpriteCount = 0;
        clrSpriteCount = 0;

        incLineCount = 0;
        clrLineCount = 0;

        incBitCount = 0;
        clrBitCount = 0;

        incCycleCount = 0;
        clrCycleCount = 0;

        incByteCount = 0;
        clrByteCount = 0;

        loadPointerReg = 0;
        loadXYReg = 0;
        loadColorReg = 0;
        loadPropReg = 0;

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
                    Retrieve the sprite's pointer to the color data, X position,
                    Y position, alpha selection, and reflection options.
                */
                incCycleCount = 1;
                ns = getRegisters;
                case (cycleCount)
                    0: begin
                        rd_addr = spriteEntryAddress[15:8];
                    end
                    1: begin
                        rd_addr = spriteEntryAddress[7:0];
                        incByteCount = 1;
                    end
                    2: begin
                        loadPointerReg = 1;
                        rd_addr = spriteEntryByteAddress[15:8];
                    end
                    3: begin
                        rd_addr = spriteEntryByteAddress[7:0];
                        incByteCount = 1;
                    end
                    4: begin
                        loadPointerReg = 1;
                        rd_addr = spriteEntryByteAddress [15:8];
                    end
                    5: begin
                        
                         if (fullPointer == 16'b0) begin //If ptr == null skip
                            incSpriteCount = 1;
                            clrCycleCount = 1;
                            clrByteCount = 1;
                            ns = getRegisters;
                            if (spritesDone) begin
                                ns = finished;
                            end
                        end
                        
                        rd_addr = spriteEntryByteAddress [7:0];
                        incByteCount = 1;
                    end
                    6: begin
                        loadXYReg = 1;
                        rd_addr = spriteEntryByteAddress [15:8];
                    end
                    7: begin
                        rd_addr = spriteEntryByteAddress [7:0];
                        incByteCount = 1;
                    end
                    8: begin
                        loadXYReg = 1;
                        rd_addr = spriteEntryByteAddress [15:8];
                    end
                    9: begin
                        rd_addr = spriteEntryByteAddress [7:0];
                    end
                    10: begin
                        loadPropReg = 1;
                        clrCycleCount = 1;
                        clrByteCount = 1;
                        ns = getSpriteLine;
                    end
                endcase
            end


            getSpriteLine: begin
                /*
                    Using the sprite's pointer, retrieve the two bytes of
                    color data for one line.
                */
                incCycleCount = 1;
                ns = getSpriteLine;
                case (cycleCount)
                    0: begin
                        rd_addr = spritePixelAddress[15:8];
                    end
                    1: begin
                        rd_addr = spritePixelAddress[7:0];
                        incByteCount = 1;
                    end
                    2: begin
                        loadColorReg = 1;
                        rd_addr = spritePixelByteAddress[15:8];
                    end
                    3: begin
                        rd_addr = spritePixelByteAddress[7:0];
                    end
                    4: begin
                        loadColorReg = 1;
                        clrCycleCount = 1;
                        clrByteCount = 1;
                        ns = drawSprite;
                    end
                endcase
            end

            drawSprite: begin
                /*
                    Calculate the x and y coordiantes of the pixel to
                    draw based on the window location, current line,
                    and current bit. Read the reterieved color data and write to
                    the VGA buffer if on screen. Handle reflections and alpha
                    pallete choice.
                */
                clrCycleCount = 1;
                clrByteCount = 1;
                
                if (reflectV) begin
                    y_out = spriteY - window_y + (7 - lineCount);
                end else begin
                    y_out = spriteY - window_y + lineCount;
                end

                if (reflectH) begin
                    x_out = spriteX - window_x + (7 - bitCount);
                end else begin
                    x_out = spriteX - window_x + bitCount;
                end

                color = {colorRegister[1][7 - bitCount], colorRegister[0][7 - bitCount]};

                draw = (color != alpha) && (x_out >= 0 && x_out < VGA_X)
                                        && (y_out >= 0 && y_out < VGA_Y);
                incBitCount = 1;
                ns = drawSprite;
                if (bitCount == 7) begin
                    incLineCount = 1;
                    ns = getSpriteLine;
                    if (lineCount == 7) begin
                        incSpriteCount = 1;
                        ns = getRegisters;
                        if (spritesDone) begin
                            ns = finished;
                        end
                    end
                end
            end

            finished: begin
                /*
                    Ensure start goes low before allowing another
                    draw cycle.
                */
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
