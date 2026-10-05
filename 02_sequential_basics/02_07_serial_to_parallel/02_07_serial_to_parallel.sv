//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_to_parallel
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,

    input                      serial_valid,
    input                      serial_data,

    output logic               parallel_valid,
    output logic [width - 1:0] parallel_data
);
    // Task:
    // Implement a module that converts single-bit serial data to the multi-bit parallel value.
    //
    // The module should accept one-bit values with valid interface in a serial manner.
    // After accumulating 'width' bits and receiving last 'serial_valid' input,
    // the module should assert the 'parallel_valid' at the same clock cycle
    // and output 'parallel_data' value.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.

    logic [        width  - 2:  0] preliminary_res;
    logic [$clog2 (width) - 1:  0] cnt;
    logic                              vld;
    
    always_ff @ (posedge clk)
        if (rst)
            preliminary_res <= '0;
        else if (serial_valid && cnt != width - 1'b1)
            preliminary_res [cnt] <= serial_data;

    always_ff @ (posedge clk)
        if (rst)
            cnt <= '0;
        else if (serial_valid) begin
            if (cnt == width - 1'b1)
                cnt <= '0;
            else 
                cnt <= cnt + 1'b1;
        end

    assign parallel_valid = serial_valid && (cnt == width - 1'b1);
    assign parallel_data  = { serial_data, preliminary_res };

endmodule
