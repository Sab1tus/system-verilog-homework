//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module parallel_to_serial
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,

    input                      parallel_valid,
    input        [width - 1:0] parallel_data,

    output                     busy,
    output logic               serial_valid,
    output logic               serial_data
);
    // Task:
    // Implement a module that converts multi-bit parallel value to the single-bit serial data.
    //
    // The module should accept 'width' bit input parallel data when 'parallel_valid' input is asserted.
    // At the same clock cycle as 'parallel_valid' is asserted, the module should output
    // the least significant bit of the input data. In the following clock cycles the module
    // should output all the remaining bits of the parallel_data.
    // Together with providing correct 'serial_data' value, module should also assert the 'serial_valid' output.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.

    logic [             width - 1:  0] parallel_input, serial_res;
    logic [$clog2 (width + 1) - 1:  0] cnt;
    logic                              vld, active;

    //Saving input

    always_ff @ (posedge clk) 
        if (rst)
            parallel_input <= '0;
        else if (parallel_valid)
            parallel_input <= parallel_data;

    //Active flag

    always_ff @ (posedge clk)
        if (rst)
            active <= '0;
        else if (parallel_valid)
            active <= 1'b1;
        else if (active && cnt == width - 1'b1)
            active <= '0;

    //Counter

    always_ff @ (posedge clk)
        if (rst)
            cnt <= '0;
        else if (parallel_valid)
            cnt <= cnt + 1'b1;
        else if (active) begin
            if (cnt == width - 1'b1)
                cnt <= '0;
            else
                cnt <= cnt + 1'b1;
        end

    //Result 
    
    always_ff @ (posedge clk)
        if (rst)
            serial_data <= '0;
        else if (parallel_valid)
            serial_data <= parallel_data [0];
        else if (active)
            serial_data <= parallel_input [cnt];

    always_ff @ (posedge clk)
        if (rst)
            vld <= '0;
        else if (parallel_valid || active)
            vld <= 1'b1;
        else
            vld <= '0;

    assign busy         = active && ~cnt;    
    assign serial_valid = vld;

endmodule
