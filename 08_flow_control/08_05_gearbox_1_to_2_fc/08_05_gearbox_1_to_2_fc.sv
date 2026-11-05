//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_1_to_2_fc
# (
    parameter width = 8
)
(
    input                   clk,
    input                   rst,
    input                   up_valid,
    output                  up_ready,
    input  [   width - 1:0] up_data,
    output                  down_valid,
    output [ 2*width - 1:0] down_data,
    input                   down_ready
);

    // Task:
    // Implement a module that generates one token from of two tokens.
    // Example:
    // "01", "10" => "0110"
    //
    // The module must use signals valid-ready for transfer tokens.

    wire up_handshake   = up_valid   & up_ready;
    wire down_handshake = down_valid & down_ready;

    logic [width - 1:0] first_half, second_half;
    logic               half_vld, first_half_vld, second_half_vld;

    wire empty = ~(first_half_vld & second_half_vld);

    always_ff @ (posedge clk) begin
        if (rst)
            half_vld <= '0;
        else if (up_handshake)
            half_vld <= ~half_vld;
    end

    always_ff @ (posedge clk) begin
        if (rst)
            first_half_vld <= '0;                     
        else if (up_handshake & ~half_vld)
            first_half_vld <= 1'b1;
        else if (down_handshake & half_vld)
            first_half_vld <= '0;             
    end

    always_ff @ (posedge clk) begin
        if (rst)
            second_half_vld <= '0;     
        else if (up_handshake & half_vld)
            second_half_vld <= 1'b1;
        else if (down_handshake & ~half_vld)
            second_half_vld <= '0;               
    end

    always_ff @ (posedge clk) begin
        if (up_handshake & ~half_vld)
            first_half  <= up_data;
        else if (up_handshake & half_vld)
            second_half <= up_data;
    end

    assign down_valid  = first_half_vld & second_half_vld;
    assign down_data   = { first_half, second_half };

    assign up_ready    = empty | down_ready;

endmodule
