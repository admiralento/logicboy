/***************************************************************************
*
* Module: ShiftRegister
*
* Author: Ammon Wolfert
* Date: November 29, 2019
*
* Description: N-Sized Shift Clearable Loadable Shift Register
*
****************************************************************************/
`default_nettype none

module ShiftRegister #(parameter WID=8, parameter LEN=2)(
    input wire logic                clk,
    input wire logic                reset,
    input wire logic                clr,
    input wire logic                load,
    input wire logic    [WID-1:0]   din,
    output logic        [WID-1:0]   dout    [LEN]
    );

    always_ff @(posedge clk) begin
        integer i;
        if (reset || clr) begin
            for (int i = 0; i < LEN; i++) begin
                dout[i] <= 0;
            end
        end else if (load) begin
            dout[0] <= din;
            for (int i = 1; i < LEN; i++) begin
                dout[i] <= dout[i-1];
            end
        end
    end

endmodule
