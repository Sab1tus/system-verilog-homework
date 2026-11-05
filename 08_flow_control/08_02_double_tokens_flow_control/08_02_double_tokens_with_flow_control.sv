//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module double_tokens_with_flow_control
(
    input  clk,
    input  rst,

    input  up_valid,
    output up_ready,
    input  up_token,

    output down_valid,
    input  down_ready,
    output down_data
);

  // Task:
  // Implement module double input signals (tokens). The module must use signals valid-ready for
  // transfer tokens. If the module receives more than 100 sequential tokens then it must set up_ready = 0;

    logic [7:0] cnt;
    logic       overflow;

    wire up_handshake   = up_valid   & up_ready;
    wire down_handshake = down_valid & down_ready;

    always_ff @ (posedge clk) begin
        if (rst) begin
            cnt      <= '0;
            overflow <= '0;
        end
        else begin
            if (up_handshake & up_token & (cnt >= 8'd200))
                overflow <= 1'b1;

            if (up_handshake & down_handshake & up_token)
                cnt <= cnt + 1'b1;
            else if (up_handshake & ~down_handshake & up_token)
                cnt <= cnt + 2'd2;
            else if (down_handshake & (cnt > 0) & (~up_handshake | ~up_token))
                cnt <= cnt - 1'b1;
        end
    end

    assign down_data  = (up_valid & up_token) | (cnt > 0);

    assign down_valid = ~overflow;

    assign up_ready   = (cnt < 8'd200);

endmodule
