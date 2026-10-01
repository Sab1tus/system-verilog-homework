module sqrt_formula_distributor
# (
    parameter formula = 2,
              impl    = 1
)
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
    // Implement a module that will calculate formula 1 or formula 2
    // based on the parameter values. The module must be pipelined.
    // It should be able to accept new triple of arguments a, b, c arriving
    // at every clock cycle.
    //
    // The idea of the task is to implement hardware task distributor,
    // that will accept triplet of the arguments and assign the task
    // of the calculation formula 1 or formula 2 with these arguments
    // to the free FSM-based internal module.
    //
    // The first step to solve the task is to fill 03_04 and 03_05 files.
    //
    // Note 1:
    // Latency of the module "formula_1_isqrt" should be clarified from the corresponding waveform
    // or simply assumed to be equal 50 clock cycles.
    //
    // Note 2:
    // The task assumes idealized distributor (with 50 internal computational blocks),
    // because in practice engineers rarely use more than 10 modules at ones.
    // Usually people use 3-5 blocks and utilize stall in case of high load.
    //
    // Hint:
    // Instantiate sufficient number of "formula_1_impl_1_top", "formula_1_impl_2_top",
    // or "formula_2_top" modules to achieve desired performance.

    localparam N = 35;

    logic [ $clog2 (N) - 1:0] cnt;    

    logic        inst_arg_vld [N];
    logic [31:0] inst_a       [N];
    logic [31:0] inst_b       [N];
    logic [31:0] inst_c       [N];

    logic        inst_res_vld [N];
    logic [31:0] inst_res     [N];

    logic        res_vld_comb;
    logic [31:0] res_comb;

    //Counter 

    always_ff @ (posedge clk)
        if (rst)
            cnt <= '0;
        else if (arg_vld)
            if (cnt == N - 1)
                cnt <= '0;
            else 
                cnt <= cnt + 1'b1;

    //Instantiation of modules

    genvar i;

    generate
        for (i = 0; i < N; i++) begin
            
            //Registers

            always_ff @ (posedge clk)
                if (rst)
                    inst_arg_vld [i] <= 1'b0;
                else
                    inst_arg_vld [i] <= arg_vld && (cnt == i);

            always_ff @ (posedge clk)
                if (arg_vld && (cnt == i)) begin
                    inst_a [i] <= a;
                    inst_b [i] <= b;
                    inst_c [i] <= c;
                end


            `define CONNECTIONS              \
            .clk     ( clk              ),   \
            .rst     ( rst              ),   \   
            .arg_vld ( inst_arg_vld [i] ),   \
            .a       ( inst_a       [i] ),   \
            .b       ( inst_b       [i] ),   \
            .c       ( inst_c       [i] ),   \
            .res_vld ( inst_res_vld [i] ),   \
            .res     ( inst_res     [i] )    


            if (formula == 1 && impl == 1)
                formula_1_impl_1_top inst_form_1_impl_1 ( `CONNECTIONS );

            else if (formula == 1 && impl == 2) 
                formula_1_impl_2_top inst_form_1_impl_1 ( `CONNECTIONS );

            else if (formula == 2)
                formula_2_top        inst_form_1_impl_1 ( `CONNECTIONS );

            `undef CONNECTIONS
        end
    endgenerate

    //Result

    always_comb begin
        res_vld_comb = '0;
        res_comb     = '0;

        for (int j = 0; j < N; j++)
            if (inst_res_vld [j]) begin
                res_vld_comb = 1'b1;
                res_comb     = inst_res [j];
            end
    end

    assign res_vld = res_vld_comb;
    assign res     = res_comb;

endmodule
