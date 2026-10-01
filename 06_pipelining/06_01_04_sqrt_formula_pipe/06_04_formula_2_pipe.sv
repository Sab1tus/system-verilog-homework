//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe
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
    // Implement a pipelined module formula_2_pipe that computes the result
    // of the formula defined in the file formula_2_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_2_pipe has to be pipelined.
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

    wire  [31:0] res_c, res_isqrt_bc;
    wire  [15:0] res_total;
    wire  [31:0] b_shift, a_shift;
    wire  [31:0] sum_bc, sum_abc;
    wire         isqrt_1_vld, isqrt_2_vld;

    logic        res_vld_1_ff, res_vld_2_ff;
    logic [31:0] res_bc_ff, res_abc_ff;

    isqrt isqrt_1 (
        .clk     ( clk          ),
        .rst     ( rst          ),
        .x_vld   ( arg_vld      ),
        .x       ( c            ),
        .y_vld   ( isqrt_1_vld  ),
        .y       ( res_c        )        
    );

    shift_register_with_valid # (
        .width (32),
        .depth (16)
    ) shift_reg_1 (
        .clk      ( clk         ),
        .rst      ( rst         ),
        .in_vld   ( arg_vld     ),
        .in_data  ( b           ),
        .out_vld  (             ),
        .out_data ( b_shift     )
    );

    assign sum_bc = b_shift + res_c;

    always_ff @ (posedge clk)
        if (rst)
            res_vld_1_ff <= '0;
        else 
            res_vld_1_ff <= isqrt_1_vld;   
    
    always_ff @ (posedge clk) 
        if (isqrt_1_vld)
            res_bc_ff <= sum_bc;

    isqrt isqrt_2 (
        .clk     ( clk          ),
        .rst     ( rst          ),
        .x_vld   ( res_vld_1_ff ),
        .x       ( res_bc_ff    ),
        .y_vld   ( isqrt_2_vld  ),
        .y       ( res_isqrt_bc )        
    );

    shift_register_with_valid # (
        .width (32),
        .depth (33)
    ) shift_reg_2 (
        .clk      ( clk         ),
        .rst      ( rst         ),
        .in_vld   ( arg_vld     ),
        .in_data  ( a           ),
        .out_vld  (             ),
        .out_data ( a_shift     )
    );

    assign sum_abc = a_shift + res_isqrt_bc;

    always_ff @ (posedge clk)
        if (rst)
            res_vld_2_ff <= '0;
        else 
            res_vld_2_ff <= isqrt_2_vld;   
    
    always_ff @ (posedge clk) 
        if (isqrt_2_vld)
            res_abc_ff <= sum_abc;

    isqrt isqrt_3 (
        .clk     ( clk          ),
        .rst     ( rst          ),
        .x_vld   ( res_vld_2_ff ),
        .x       ( res_abc_ff   ),
        .y_vld   ( res_vld      ),
        .y       ( res_total    )         
    );

    assign res = 32' (res_total);

endmodule
