//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module round_robin_arbiter_with_2_requests
(
    input        clk,
    input        rst,
    input  [1:0] requests,
    output [1:0] grants
);
    // Task:
    // Implement a "arbiter" module that accepts up to two requests
    // and grants one of them to operate in a round-robin manner.
    //
    // The module should maintain an internal register
    // to keep track of which requester is next in line for a grant.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // requests -> 01 00 10 11 11 00 11 00 11 11
    // grants   -> 01 00 10 01 10 00 01 00 10 01

    logic [1:0] grants_comb;
    logic       next_in_line;

    always_comb begin
        if (~(requests[0] & requests[1]))
            grants_comb = requests;
        else
            grants_comb = next_in_line ? 2'b10 : 2'b01;
    end

    assign grants = grants_comb;

    always_ff @ (posedge clk)
        if (rst)
            next_in_line <= '0;
        else if (|grants)
            next_in_line <= grants [0];

endmodule
