//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_floats_using_fsm (
    input                          clk,
    input                          rst,

    input                          valid_in,
    input        [0:2][FLEN - 1:0] unsorted,

    output logic                   valid_out,
    output logic [0:2][FLEN - 1:0] sorted,
    output logic                   err,
    output                         busy,

    // f_less_or_equal interface
    output logic      [FLEN - 1:0] f_le_a,
    output logic      [FLEN - 1:0] f_le_b,
    input                          f_le_res,
    input                          f_le_err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order using FSM.
    //
    // Requirements:
    // The solution must have latency equal to the three clock cycles.
    // The solution should use the inputs and outputs to the single "f_less_or_equal" module.
    // The solution should NOT create instances of any modules.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res1
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    enum logic [1:0]
    {
        IDLE = 2'd0,
        S1   = 2'd1,
        S2   = 2'd2,
        S3   = 2'd3
    }
    state, next_state;

    //FSM
    always_comb begin
        next_state = state;

        case (state)
        IDLE :  if (valid_in)  next_state = S1;
        S1   :                 next_state = S2;
        S2   :                 next_state = S3;
        S3   :                 next_state = IDLE;
        endcase        
    end

    always_ff @ (posedge clk)
        if (rst)
            state <= IDLE;
        else
            state <= next_state;

    assign busy = (state != IDLE);    

    //Sorting
    always_comb begin
        f_le_a = '0;
        f_le_b = '0;
    
        case (state)
        S1  : begin 
            f_le_a = sorted[0]; 
            f_le_b = sorted[1]; 
        end
        S2  : begin 
            f_le_a = sorted[1]; 
            f_le_b = sorted[2]; 
        end
        S3  : begin 
            f_le_a = sorted[0]; 
            f_le_b = sorted[1]; 
        end
        endcase
    end

    always_ff @ (posedge clk)
        if (rst)
            sorted <= '0;
        else
            case(state)
            IDLE : if ( valid_in)               sorted       <=    unsorted                ;
            S1   : if (~f_le_res) { sorted [0], sorted [1] } <=  { sorted [1], sorted [0] };
            S2   : if (~f_le_res) { sorted [1], sorted [2] } <=  { sorted [2], sorted [1] };
            S3   : if (~f_le_res) { sorted [0], sorted [1] } <=  { sorted [1], sorted [0] };
            endcase  

    //Result
    always_ff @ (posedge clk)
        if (rst)
            err <= '0;
        else if (state == IDLE)
            err <= '0;
        else if (~err & f_le_err)
            err <= 1'b1; 

    always_ff @ (posedge clk)
        if (rst)
            valid_out <= '0;
        else
            valid_out <= (state == S3);  

endmodule
