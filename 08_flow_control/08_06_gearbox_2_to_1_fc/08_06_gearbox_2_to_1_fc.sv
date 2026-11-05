//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_2_to_1_fc
# (
    parameter width = 8
)
(
    input                    clk,
    input                    rst,

    input                    up_valid,
    output                   up_ready,
    input   [ 2*width - 1:0] up_data,

    output                   down_valid,
    input                    down_ready,
    output  [   width - 1:0] down_data
);

    // Task:
    // Implement a module that generates tokens from of one token.
    // Example:
    // "0110" => "01", "10"
    //
    // The module must use signals valid-ready for transfer tokens.

    wire up_handshake   = up_valid   & up_ready;
    wire down_handshake = down_valid & down_ready;

    logic [width - 1:0] first_half, second_half;
    logic               first_half_vld, second_half_vld;

    wire empty = ~first_half_vld & ~second_half_vld;

    always_ff @ (posedge clk) begin
        if (rst)
            first_half_vld <= 1'b0;
        else if (up_handshake)
            first_half_vld <= 1'b1;
        else if (down_handshake)
            first_half_vld <= 1'b0;
    end

    always_ff @ (posedge clk) begin
        if (rst)
            second_half_vld <= 1'b0;
        else if (up_handshake)
            second_half_vld <= 1'b1;
        else if (down_handshake & ~first_half_vld)
            second_half_vld <= 1'b0;
    end

    always_ff @ (posedge clk) begin
        if (up_handshake) begin
            first_half  <= up_data [width +: width]; 
            second_half <= up_data [    0 +: width];
        end
    end


    assign down_valid = first_half_vld | second_half_vld;
    assign down_data  = first_half_vld ? first_half : second_half;

    assign up_ready   = empty | (~first_half_vld & down_ready);

endmodule
