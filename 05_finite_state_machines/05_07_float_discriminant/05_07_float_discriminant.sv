//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module float_discriminant (
    input                     clk,
    input                     rst,

    input                     arg_vld,
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,
    input        [FLEN - 1:0] c,

    output logic              res_vld,
    output logic [FLEN - 1:0] res,
    output logic              res_negative,
    output logic              err,

    output logic              busy
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs their discriminant.
    // The resulting value res should be calculated as a discriminant of the quadratic polynomial.
    // That is, res = b^2 - 4ac == b*b - 4*a*c
    //
    // Note:
    // If any argument is not a valid number, that is NaN or Inf, the "err" flag should be set.
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    localparam [FLEN - 1:0] four    = 64'h4010_0000_0000_0000;

    logic      [FLEN - 1:0] temp_reg;

    //Input error detection
    wire                    has_err = (&a[FLEN - 2 -: 11]) | 
                                      (&b[FLEN - 2 -: 11]) | 
                                      (&c[FLEN - 2 -: 11]);

    //States
    enum logic [2:0] {
        IDLE,
        WAIT_AC,
        WAIT_BB,
        WAIT_4AC,
        WAIT_RES
    } state, next_state;

    //Multiplication module interface
    logic  [FLEN - 1:0]  mult_a, mult_b;
    logic                mult_up_valid;
    logic  [FLEN - 1:0]  mult_res;
    logic                mult_down_valid;
    logic                mult_busy, mult_err;



    //Substraction module interface
    logic  [FLEN - 1:0]  sub_a, sub_b;
    logic                sub_up_valid;
    logic  [FLEN - 1:0]  sub_res;
    logic                sub_down_valid;
    logic                sub_busy, sub_err;

    //Modules' instantiation
    f_mult mult_inst (
        .clk        ( clk               ),
        .rst        ( rst               ),
        .a          ( mult_a            ),
        .b          ( mult_b            ),
        .up_valid   ( mult_up_valid     ),
        .res        ( mult_res          ),
        .down_valid ( mult_down_valid   ),
        .busy       ( mult_busy         ),
        .error      ( mult_err          )
    );

    f_sub sub_inst (
        .clk        ( clk               ),
        .rst        ( rst               ),
        .a          ( sub_a             ),
        .b          ( sub_b             ),
        .up_valid   ( sub_up_valid      ),
        .res        ( sub_res           ),
        .down_valid ( sub_down_valid    ),
        .busy       ( sub_busy          ),
        .error      ( sub_err           )
    );


    //FSM
    always_comb begin
        next_state = state;

        case (state)
        IDLE     :   if (        arg_vld) next_state = WAIT_AC ;
        WAIT_AC  :   if (mult_down_valid) next_state = WAIT_BB ;
        WAIT_BB  :   if (mult_down_valid) next_state = WAIT_4AC;  
        WAIT_4AC :   if (mult_down_valid) next_state = WAIT_RES;
        WAIT_RES :   if ( sub_down_valid) next_state = IDLE    ;           
        endcase
    end

    always_ff @ (posedge clk)
        if (rst)
            state <= IDLE;
        else
            state <= next_state;

    assign busy = (state != IDLE);  

    //Datapath
    always_comb begin
        mult_up_valid = '0;
        sub_up_valid  = '0;
        mult_a        = '0;
        mult_b        = '0;
        sub_a         = '0;
        sub_b         = '0;

        case (state)
        IDLE     :   if (        arg_vld) begin mult_up_valid = 1'b1        ;
                                                mult_a        = a           ;
                                                mult_b        = c           ;
                    end
        WAIT_AC  :   if (mult_down_valid) begin mult_up_valid = 1'b1        ;
                                                mult_a        = b           ;
                                                mult_b        = b           ;
                    end            
        WAIT_BB  :   if (mult_down_valid) begin mult_up_valid = 1'b1        ;
                                                mult_a        = temp_reg    ;
                                                mult_b        = four        ;
                    end              
        WAIT_4AC :   if (mult_down_valid) begin sub_up_valid  = 1'b1        ;      
                                                sub_a         = temp_reg    ;
                                                sub_b         = mult_res    ;
                    end    
        endcase
    end

    //Trigger for temporary results' register
    always_ff @ (posedge clk) begin
    if (state == WAIT_AC && mult_down_valid) 
        temp_reg <= mult_res;

    if (state == WAIT_BB && mult_down_valid) 
        temp_reg <= mult_res;
    end

    //Result
    always_ff @ (posedge clk)
        if (rst)
            err <= '0;
        else if (state == IDLE)
            if (arg_vld)
                err <= has_err;
            else
                err <= '0; 

    always_ff @ (posedge clk)
        if (rst)
            res_vld <= '0;
        else
            res_vld <= (state == WAIT_RES && sub_down_valid);  
        
    always_ff @ (posedge clk)
        if (rst) begin
            res          <= '0;
            res_negative <= '0;
        end
        else if (state == IDLE) begin
            res          <= '0;
            res_negative <= '0;
        end
        else if (state == WAIT_RES && sub_down_valid) begin
            res          <= sub_res;
            res_negative <= sub_res [FLEN - 1];     
        end

endmodule
