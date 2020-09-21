/***************************************************************************
*
* Module: mod_counter
*
* Author: Ammon Wolfert
* Class: ECEN 220, Section 2, Fall 2019
* Date: October 18th 2019
*
* Description: Counts to (parameter - 1) and then rolls over
*
*
****************************************************************************/

`default_nettype none

module mod_counter #(parameter MOD_VALUE=10) (
    input wire logic clk, reset, increment,
    output logic rolling_over,
    output logic[$clog2(MOD_VALUE)-1:0] count
    );

    assign rolling_over = (increment) && (count == MOD_VALUE - 1);

    always_ff @(posedge clk)
    begin
        if (rolling_over || reset)
            count <= 0;
        else if (increment)
            count <= count + 1;
    end

endmodule
