/***************************************************************************
*
* Module: ButtonDebounce
*
* Author: Ammon Wolfert
* Date: November 26, 2019
*
* Description: Returns the debounced state of all the buttons.
*
****************************************************************************/
`default_nettype none

module ButtonDebounce #(parameter INTERVAL=500000) (
    input wire logic            clk,
    input wire logic            reset,
    input wire logic            btnu,
    input wire logic            btnl,
    input wire logic            btnr,
    input wire logic            btnd,
    input wire logic            btnc,
    output logic        [7:0]   buttonState
    );

    debounce #(INTERVAL) center (clk, reset, btnc, buttonState[0]);
    debounce #(INTERVAL) up (clk, reset, btnu, buttonState[1]);
    debounce #(INTERVAL) down (clk, reset, btnd, buttonState[2]);
    debounce #(INTERVAL) right (clk, reset, btnr, buttonState[3]);
    debounce #(INTERVAL) left (clk, reset, btnl, buttonState[4]);
    assign buttonState[7:5] = 3'b000;

endmodule
