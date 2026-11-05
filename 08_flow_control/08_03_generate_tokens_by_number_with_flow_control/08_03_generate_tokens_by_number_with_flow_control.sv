//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module generate_tokens_by_number_with_flow_control
#(
    WIDTH = 4
)
(
    input                 clk,
    input                 rst,

    input                 up_valid,
    output                up_ready,
    input  [WIDTH-1 : 0]  n_tokens,

    output                down_valid,
    input                 down_ready,
    output                down_token
);

    // Task:
    // Implement a module that recive an integer N_tokens and generate N_tokens pulses. The module must use signals valid-ready for
    // transfer tokens.


    logic [WIDTH-1 : 0] cnt;

    wire up_handshake   = up_valid   & up_ready;
    wire down_handshake = down_valid & down_ready;

    always_ff @(posedge clk) begin
        if (rst)
            cnt <= '0;
        else if (up_handshake)
            cnt <= n_tokens;
        else if (down_handshake)
            cnt <= cnt - 1'b1;
    end

    assign up_ready   = (cnt == '0);

    assign down_valid = (cnt > '0);
    assign down_token = (cnt > '0);

endmodule
