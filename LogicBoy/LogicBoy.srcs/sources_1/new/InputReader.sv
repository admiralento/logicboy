/***************************************************************************
*
* Module: InputReader
* Author: Ammon Wolfert
* Date: May 7th, 2020
*
* Description: Writes user input information into memory
*
****************************************************************************/
`default_nettype none

module InputReader(
    input wire logic            clk,
    input wire logic            reset,
    input wire logic            start,
    input wire logic    [15:0]  sw,
    input wire logic    [7:0]   buttons,
    output logic                done,
    output logic        [7:0]   wr_addr,
    output logic        [7:0]   wr_data,
    output logic                wr_en
    );
    
    localparam          WINDOW_X_ADDR = 16'hE8A5;
    localparam          WINDOW_Y_ADDR = 16'hE8A6;
    localparam          BUTTON_STATE_REG = 16'hFFFF;
    localparam          POINTER_TABLE_ADDR = 16'hE8A8;
    localparam          SPRITE_DATA_ADDR = 16'hF800;
    
    logic       [15:0]   byteCount;
    logic               incByteCount;
    logic               clrByteCount;

    logic       [15:0]   cycleCount;
    logic               incCycleCount;
    logic               clrCycleCount;

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

    ///////// State Machine //////////
    typedef enum logic[2:0] {init, writeSwitches, writeButtons, finished, ERR = 'X} State;
    State cs, ns;
    
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
                    ns = writeSwitches;
                end else begin
                    ns = init;
                end
            end

            writeSwitches: begin
                incCycleCount = 1;
                ns = writeSwitches;
                case (cycleCount)
                    0: begin
                        wr_addr = WINDOW_X_ADDR[15:8];
                    end
                    1: begin
                        wr_addr = WINDOW_X_ADDR[7:0];
                    end
                    2: begin
                        wr_data = sw[15:8];
                        wr_en = 1;
                        wr_addr = WINDOW_Y_ADDR[15:8];
                    end
                    3: begin
                        wr_addr = WINDOW_Y_ADDR[7:0];
                    end
                    4: begin
                        wr_data = sw[7:0];
                        wr_en = 1;
                        clrCycleCount = 1;
                        ns = writeButtons;
                    end
                endcase
            end

            writeButtons: begin
                incCycleCount = 1;
                ns = writeButtons;
                case (cycleCount)
                    0: begin
                        wr_addr = BUTTON_STATE_REG[15:8];
                    end
                    1: begin
                        wr_addr = BUTTON_STATE_REG[7:0];
                        wr_data = buttons;
                    end
                    2: begin
                        wr_data = buttons;
                        wr_en = 1;
                        clrCycleCount = 1;
                        ns = finished;
                    end
                endcase
            end

            finished: begin
                done = 1;
                ns = init;
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