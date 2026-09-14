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

    logic [             width - 1:  0] preliminary_res, parallel_res;
    logic [$clog2 (width + 1) - 1:  0] cnt;
    logic                vld;

    always_ff @ (posedge clk) begin
        if (rst) begin
            vld             <= '0;
            preliminary_res <= '0;
            cnt             <= '0;
        end
        else begin
            vld <= '0;
            if (serial_valid)
                if (cnt == width - 1'b1) begin
                    parallel_res <= { serial_data, preliminary_res[width - 2:0] };
                    vld          <= 1'b1;
                    cnt          <= '0;
                end        
                else begin
                    preliminary_res [cnt] <= serial_data;
                    cnt                   <= cnt + 1'b1;
                end
        end
    end

    assign parallel_data  = parallel_res;
    assign parallel_valid = vld;

endmodule
