/***************************************************************************
*
* Module: CLRegister
*
* Author: Ammon Wolfert
* Date: November 29, 2019
*
* Description: Clearable Loadable Register
*
****************************************************************************/
`default_nettype none

module CLRegister #(parameter WID=8)(
    input wire logic                clk,
    input wire logic                reset,
    input wire logic                clr,
    input wire logic                load,
    input wire logic    [WID-1:0]   din,
    output logic        [WID-1:0]   dout
    );

    always_ff @(posedge clk) begin
        if (reset || clr) begin
            dout <= 0;
        end else if (load) begin
            dout <= din;
        end
    end

endmodule
