//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module sort_two_floats_ab (
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,

    output logic [FLEN - 1:0] res0,
    output logic [FLEN - 1:0] res1,
    output                    err
);

    logic a_less_or_equal_b;

    f_less_or_equal i_floe (
        .a   ( a                 ),
        .b   ( b                 ),
        .res ( a_less_or_equal_b ),
        .err ( err               )
    );

    always_comb begin : a_b_compare
        if ( a_less_or_equal_b ) begin
            res0 = a;
            res1 = b;
        end
        else
        begin
            res0 = b;
            res1 = a;
        end
    end

endmodule

//----------------------------------------------------------------------------
// Example - different style
//----------------------------------------------------------------------------

module sort_two_floats_array
(
    input        [0:1][FLEN - 1:0] unsorted,
    output logic [0:1][FLEN - 1:0] sorted,
    output                         err
);

    logic u0_less_or_equal_u1;

    f_less_or_equal i_floe
    (
        .a   ( unsorted [0]        ),
        .b   ( unsorted [1]        ),
        .res ( u0_less_or_equal_u1 ),
        .err ( err                 )
    );

    always_comb
        if (u0_less_or_equal_u1)
            sorted = unsorted;
        else
              {   sorted [0],   sorted [1] }
            = { unsorted [1], unsorted [0] };

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_three_floats (
    input        [0:2][FLEN - 1:0] unsorted,
    output logic [0:2][FLEN - 1:0] sorted,
    output                         err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order.
    // The module should be combinational with zero latency.
    // The solution can use up to three instances of the "f_less_or_equal" module.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res2
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    logic [FLEN - 1:0]     min, mid, max;
    logic               cmp1, cmp2, cmp3;
    logic               err1, err2, err3;   
    
    f_less_or_equal i_floe_1
    (
        .a   ( unsorted [0]        ),
        .b   ( unsorted [1]        ),
        .res ( cmp1                ),
        .err ( err1                )
    );

    always_comb
        if (cmp1)
              {          max,          min }
            = { unsorted [1], unsorted [0] };
        else
              {          max,          min }
            = { unsorted [0], unsorted [1] };

    f_less_or_equal i_floe_2
    (
        .a   ( max                 ),
        .b   ( unsorted [2]        ),
        .res ( cmp2                ),
        .err ( err2                )
    );
    
    always_comb
        if (cmp2)
              { mid,    sorted[2] }
            = { max, unsorted [2] };
        else
              {          mid,    sorted[2] }
            = { unsorted [2],          max };
    
    f_less_or_equal i_floe_3
    (
        .a   ( min                 ),
        .b   ( mid                 ),
        .res ( cmp3                ),
        .err ( err3                )
    );

    always_comb
        if (cmp3)
              { sorted[0], sorted[1] }
            = {       min,       mid };
        else
              { sorted[0], sorted[1] }
            = {       mid,       min };

    assign err = err1 | err2 | err3;

endmodule
