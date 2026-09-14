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

    always_ff @ (posedge clk) begin
        if (rst) begin
            vld             <= '0;
            parallel_input  <= '0;
            cnt             <= '0;
            active          <= '0;
        end
        else begin
            vld <= '0;
            if (parallel_valid) begin
                parallel_input  <= parallel_data;
                serial_data     <= parallel_data [0];
                vld             <= 1'b1;
                active          <= 1'b1;
                cnt             <= cnt + 1'b1;
            end
            else if (active) begin
                serial_data <= parallel_input [cnt];            
                vld         <= 1'b1;                   
                if (cnt == width - 1'b1) begin
                    active <= '0;
                    cnt    <= '0;
                end
                else
                    cnt <= cnt + 1'b1;                                     
            end
        end
    end

    assign busy         = active && ~cnt;    
    assign serial_valid = vld;


endmodule
