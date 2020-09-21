/***************************************************************************
*
* Module: DrawButtons
*
* Author: Ammon Wolfert
* Date: May 25,, 2020
*
* Description: Reads the button registers and writes it to the screen
*
****************************************************************************/
`default_nettype none

module DrawButtons(
    input wire logic            clk,
    input wire logic            reset,
    input wire logic            start,
    output logic                draw,
    output logic                done,
    input wire logic    [7:0]   rd_data,
    output logic        [7:0]   rd_addr,
    output logic        [7:0]   x_out,
    output logic        [7:0]   y_out,
    output logic        [1:0]   color,
    output logic        [15:0]  percievedSwitches   //DEBUGGING
    );
    ///////// Configuration Signals ///////
    localparam                  BUTTON_REGISTER_ADDRESS = 16'hFFFF;
    localparam                  LOWER_SWITCH_REGISTER_ADDRESS = 16'hE8A6;
    localparam                  HIGHER_SWITCH_REGISTER_ADDRESS = 16'hE8A5;
    localparam                  VGA_X = 160;
    localparam                  VGA_Y = 140;
    
    ///////////// Registers ///////////////
    logic               [7:0]   buttonRegister;
    logic                       loadButtonReg;
    
    logic               [7:0]   switchesRegister [2];
    logic                       loadSwitchReg;
      
    logic               [15:0]  fullSwitchState;
    
    always_ff @(posedge clk) begin
        if (reset) buttonRegister <= 0;
        else if (loadButtonReg) buttonRegister <= rd_data;
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin
            switchesRegister[0] <= 0;
            switchesRegister[1] <= 0;
        end else if (loadSwitchReg) begin
            switchesRegister[0] <= rd_data;
            switchesRegister[1] <= switchesRegister[0];
        end
    end
    
    assign fullSwitchState = {switchesRegister[1], switchesRegister[0]};
    assign percievedSwitches = fullSwitchState;
    
    ///////////// Counters ////////////////
    logic               [7:0]   cycleCount;
    logic                       clrCycleCount;
    logic                       incCycleCount;

    CCounter #(8) cycleCounter (
        .clk    (clk),
        .reset  (reset),
        .clr    (clrCycleCount),
        .inc    (incCycleCount),
        .dout   (cycleCount)
    );

    ////////// Address Access Varibles /////////

    ////////////// State Machine ///////////////
    typedef enum logic[2:0] {init, getRegisters, drawSwitches, drawButtons, finished, ERR = 'X} State;
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

        incCycleCount = 0;
        clrCycleCount = 0;
        
        loadButtonReg = 0;
        loadSwitchReg = 0;

        case (cs)
            init: begin
                /*
                    Wait for the start signal before preceding.
                */
                if (start) begin
                    ns = getRegisters;
                    clrCycleCount = 1;
                end else begin
                    ns = init;
                end
            end

            getRegisters: begin
                /*
                    Retrieve the sprite's pointer to the color data.
                */
                incCycleCount = 1;
                ns = getRegisters;
                case (cycleCount)
                    0: begin
                        rd_addr = BUTTON_REGISTER_ADDRESS[15:8];
                    end
                    1: begin
                        rd_addr = BUTTON_REGISTER_ADDRESS[7:0];
                    end
                    2: begin
                        loadButtonReg = 1;
                        rd_addr = HIGHER_SWITCH_REGISTER_ADDRESS[15:8];
                    end
                    3: begin
                        rd_addr = HIGHER_SWITCH_REGISTER_ADDRESS[7:0];
                    end
                    4: begin
                        loadSwitchReg = 1;
                        rd_addr = LOWER_SWITCH_REGISTER_ADDRESS[15:8];
                    end
                    5: begin
                        rd_addr = LOWER_SWITCH_REGISTER_ADDRESS[7:0];
                    end
                    6: begin
                        loadSwitchReg = 1;
                        clrCycleCount = 1;
                        ns = drawSwitches;
                    end
                endcase
            end

            drawSwitches: begin
                incCycleCount = 1;
                x_out = (VGA_X - 1) - (15 - cycleCount);
                y_out = 0;
                draw = 1;
                color = {2{fullSwitchState[15 - cycleCount]}};
                if (cycleCount == 15) begin
                    ns = drawButtons;
                    clrCycleCount = 1;
                end else begin
                    ns = drawSwitches;
                end
            end
            
            drawButtons: begin
                incCycleCount = 1;
                x_out = (VGA_X - 1) - (4 - cycleCount);
                y_out = 1;
                draw = 1;
                color = {2{buttonRegister[4 - cycleCount]}};
                if (cycleCount == 4) begin
                    ns = finished;
                end else begin
                    ns = drawButtons;
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

