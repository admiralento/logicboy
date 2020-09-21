/***************************************************************************
*
* Module: CCounter
*
* Author: Ammon Wolfert
* Date: November 29, 2019
*
* Description: Clearable Counter
*
****************************************************************************/
`default_nettype none

module CCounter #(parameter WID=8)(
    input wire logic                clk,
    input wire logic                reset,
    input wire logic                clr,
    input wire logic                inc,
    output logic        [WID-1:0]   dout
    );

    always_ff @(posedge clk) begin
        if (reset || clr) begin
            dout <= 0;
        end else if (inc) begin
            dout <= dout + 1;
        end
    end

endmodule
