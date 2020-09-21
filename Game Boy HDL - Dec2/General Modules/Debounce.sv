/***************************************************************************
*
* Module: Debounce
*
* Author: Ammon Wolfert
* Date: November 26, 2019
*
* Description: Debounces a signal
*
****************************************************************************/
`default_nettype none

module debounce #(parameter INTERVAL=500000) (
    input wire logic        clk,
    input wire logic        reset,
    input wire logic        noisy,
    output logic            debounced
    );

    /////////////// Counter ///////////////
    logic       [$clog2(INTERVAL)-1:0]  timerCount;
    logic                               timerDone;
    logic                               clrTimer;

    assign timerDone = timerCount >= INTERVAL;

    CCounter #($clog2(INTERVAL)) timerModule (
        .clk    (clk),
        .reset  (reset),
        .clr    (clrTimer),
        .inc    (1'b1),
        .dout   (timerCount)
    );

    //////////// State Machine ////////////
    typedef enum logic[1:0] {s0, s1, s2, s3, ERR = 'X} State;
    State cs, ns;

    always_comb begin
        ns = ERR;
        clrTimer = 0;
        debounced = 0;

        case (cs)
            s0: begin
                if (noisy) begin
                    ns = s1;
                    clrTimer = 1;
                end else begin
                    ns = s0;
                end
            end
            s1: begin
                if (!noisy) begin
                    ns = s0;
                end else if (timerDone) begin
                    ns = s2;
                end else begin
                    ns = s1;
                end
            end
            s2: begin
                debounced = 1;
                if (!noisy) begin
                    ns = s3;
                    clrTimer = 1;
                end else begin
                    ns = s2;
                end
            end
            s3: begin
                debounced = 1;
                if (noisy) begin
                    ns = s2;
                end else if (timerDone) begin
                    ns = s0;
                end else begin
                    ns = s3;
                end
            end
        endcase
    end
    
    always_ff @(posedge clk) begin
        if (reset)
            cs <= s0;
        else
            cs <= ns;
    end
endmodule