//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module conv_first_to_last_no_ready
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    input                up_first,
    input  [width - 1:0] up_data,

    output               down_valid,
    output               down_last,
    output [width - 1:0] down_data
);
    // Task:
    // Implement a module that converts 'first' input status signal
    // to the 'last' output status signal.
    //
    // See README for full description of the task with timing diagram.

    logic               vld_reg;
    logic [width - 1:0] data_reg;

    always_ff @ (posedge clock) begin
        if (reset) begin
            vld_reg  <= '0;
        end
        else if (up_valid) begin
            data_reg <= up_data;
            vld_reg  <= 1'b1;
        end
    end

    assign down_valid = up_valid & vld_reg;
    assign down_last  = up_first;
    assign down_data  = data_reg;


endmodule
