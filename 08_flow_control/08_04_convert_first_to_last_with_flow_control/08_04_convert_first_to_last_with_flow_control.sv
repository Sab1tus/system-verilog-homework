//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module convert_first_to_last_with_flow_control
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    output               up_ready,
    input                up_first,
    input  [width - 1:0] up_data,

    output               down_valid,
    input                down_ready,
    output               down_last,
    output [width - 1:0] down_data
);

    // Task:
    // Implement a module that converts 'first' input status signal
    // to the 'last' output status signal.
    //
    // The module should respect and set correct valid and ready signals
    // to control flow from the upstream and to the downstream.

    logic               has_data;
    logic [width - 1:0] data_reg;

    wire handshake = up_valid & up_ready;

    always_ff @ (posedge clock) begin
        if (reset) begin
            has_data <= '0;
            data_reg <= '0;
        end
        else if (handshake) begin
            has_data <= 1'b1;
            data_reg <= up_data;
        end
    end

    assign up_ready   = ~has_data | down_ready;

    assign down_valid = has_data & up_valid;
    assign down_data  = data_reg;
    assign down_last  = up_first;

endmodule
