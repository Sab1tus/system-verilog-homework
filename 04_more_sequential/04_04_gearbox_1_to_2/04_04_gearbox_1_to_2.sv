//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_1_to_2
# (
    parameter width = 0
)
(
    input                    clk,
    input                    rst,

    input                    up_vld,    // upstream
    input  [    width - 1:0] up_data,

    output                   down_vld,  // downstream
    output [2 * width - 1:0] down_data
);
    // Task:
    // Implement a module that transforms a stream of data
    // from 'width' to the 2*'width' data width.
    //
    // The module should be capable to accept new data at each
    // clock cycle and produce concatenated 'down_data'
    // at each second clock cycle.
    //
    // The module should work properly with reset 'rst'
    // and valid 'vld' signals

    logic [2 * width - 1: 0] down_res;
    logic                    first_half;
    logic                    vld;

    always_ff @(posedge clk) begin
        if (rst) begin
            vld        <= '0;
            first_half <= 1'b1;
            down_res   <= '0;
        end
        else begin
            vld <= '0;        
            if (up_vld) begin
                if (first_half) begin
                    down_res [2 * width - 1: width] <= up_data;
                    first_half                      <= 1'b0;
                end
                else begin
                    down_res [    width - 1:     0] <= up_data;
                    first_half                      <= 1'b1;
                    vld                             <= 1'b1;
                end
            end
        end
    end

    assign down_data = down_res;
    assign down_vld  = vld;

endmodule
