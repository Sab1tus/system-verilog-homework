module put_in_order
# (
    parameter width    = 16,
              n_inputs = 4
)
(
    input                       clk,
    input                       rst,

    input  [ n_inputs - 1 : 0 ] up_vlds,
    input  [ n_inputs - 1 : 0 ]
           [ width    - 1 : 0 ] up_data,

    output                      down_vld,
    output [ width   - 1 : 0 ]  down_data
);

    // Task:
    //
    // Implement a module that accepts many outputs of the computational blocks
    // and outputs them one by one in order. Input signals "up_vlds" and "up_data"
    // are coming from an array of non-pipelined computational blocks.
    // These external computational blocks have a variable latency.
    //
    // The order of incoming "up_vlds" is not determent, and the task is to
    // output "down_vld" and corresponding data in a round-robin manner,
    // one after another, in order.
    //
    // Comment:
    // The idea of the block is kinda similar to the "parallel_to_serial" block
    // from Homework 2, but here block should also preserve the output order.

    logic [ $clog2 (n_inputs) - 1:0] ptr;

    logic [   width - 1:0] buf_data [n_inputs];

    logic [n_inputs -1 :0] buf_vld;

    logic                  down_vld_comb;
    logic [   width - 1:0] down_data_comb;

    //Buffer logic

    always_comb begin
        down_vld_comb  = '0;
        down_data_comb = '0;    

        if (buf_vld [ptr]) begin
            down_vld_comb  = 1'b1;
            down_data_comb = buf_data [ptr];
        end

        else if (up_vlds[ptr]) begin
            down_vld_comb  = 1'b1;
            down_data_comb = up_data [ptr];
        end
    end

    assign down_vld  = down_vld_comb;
    assign down_data = down_data_comb;

    //Data pointer

    always_ff @ (posedge clk)
        if (rst)
            ptr <= '0;
        else if (down_vld_comb)
            if (ptr == n_inputs - 1)
                ptr <= '0; 
            else
                ptr <= ptr + 1'b1;

    always_ff @ (posedge clk) begin
        if (rst)
            buf_vld <= '0;
        else 
            for (int i = 0; i < n_inputs; i++) begin

                if (ptr == i)
                    if (buf_vld [i])  
                        buf_vld [i] <= up_vlds [i];
                    else              
                        buf_vld [i] <= '0;
                else if (up_vlds [i]) 
                    buf_vld [i] <= 1'b1;

            end
    end

    //Get data into buffer in case it's not current channel or the data've been read

    always_ff @ (posedge clk) 
        for (int i = 0; i < n_inputs; i++) begin

            if (up_vlds [i] && (ptr != i || buf_vld [i])) 
                buf_data [i] <= up_data [i];

        end


endmodule
