//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);

    // Task:
    //
    // Implement a pipelined module formula_1_pipe that computes the result
    // of the formula defined in the file formula_1_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_1_pipe has to be pipelined.
    //
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    //
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    //
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    //
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.org/fsm#state_0

    wire  [31:0] res_a, res_b, res_c;
    wire  [31:0] sum;
    wire         isqrt_1_vld;

    logic        res_vld_ff;
    logic [31:0] res_ff;

    isqrt isqrt_1 (
        .clk     ( clk         ),
        .rst     ( rst         ),
        .x_vld   ( arg_vld     ),
        .x       ( a           ),
        .y_vld   ( isqrt_1_vld ),
        .y       ( res_a       )        
    );

    isqrt isqrt_2 (
        .clk     ( clk         ),
        .rst     ( rst         ),
        .x_vld   ( arg_vld     ),
        .x       ( b           ),
        .y_vld   (             ),
        .y       ( res_b       )        
    );

    isqrt isqrt_3 (
        .clk     ( clk         ),
        .rst     ( rst         ),
        .x_vld   ( arg_vld     ),
        .x       ( c           ),
        .y_vld   (             ),
        .y       ( res_c       )         
    );

    assign sum = res_a + res_b + res_c;

    always_ff @ (posedge clk)
        if (rst)
            res_vld_ff <= '0;
        else 
            res_vld_ff <= isqrt_1_vld;


    always_ff @ (posedge clk) 
        if (isqrt_1_vld)
            res_ff <= sum;
    
    assign res_vld = res_vld_ff;
    assign res     = res_ff;

endmodule
