module float_discriminant_distributor (
    input                           clk,
    input                           rst,

    input                           arg_vld,
    input        [FLEN - 1:0]       a,
    input        [FLEN - 1:0]       b,
    input        [FLEN - 1:0]       c,

    output logic                    res_vld,
    output logic [FLEN - 1:0]       res,
    output logic                    res_negative,
    output logic                    err,

    output logic                    busy
);

    // Task:
    //
    // Implement a module that will calculate the discriminant based
    // on the triplet of input number a, b, c. The module must be pipelined.
    // It should be able to accept a new triple of arguments on each clock cycle
    // and also, after some time, provide the result on each clock cycle.
    // The idea of the task is similar to the task 04_11. The main difference is
    // in the underlying module 03_08 instead of formula modules.
    //
    // Note 1:
    // Reuse your file "03_08_float_discriminant.sv" from the Homework 03.
    //
    // Note 2:
    // Latency of the module "float_discriminant" should be clarified from the waveform.

    localparam N = 10;

    logic [ $clog2 (N) - 1:0] cnt;    

    logic               inst_arg_vld      [N];
    logic [FLEN - 1:0]  inst_a            [N];
    logic [FLEN - 1:0]  inst_b            [N];
    logic [FLEN - 1:0]  inst_c            [N];

    logic [FLEN - 1:0]  inst_res          [N];
    logic               inst_res_vld      [N];
    logic               inst_res_negative [N];
    logic               inst_err          [N];
    logic               inst_busy         [N];  

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


            float_discriminant inst_float_discriminant ( 
                .clk            ( clk                   ),   
                .rst            ( rst                   ),    
                .arg_vld        ( inst_arg_vld      [i] ),   
                .a              ( inst_a            [i] ),   
                .b              ( inst_b            [i] ),   
                .c              ( inst_c            [i] ),   
                .res_vld        ( inst_res_vld      [i] ),   
                .res            ( inst_res          [i] ),   
                .res_negative   ( inst_res_negative [i] ),
                .err            ( inst_err          [i] ),
                .busy           ( inst_busy         [i] )
            );

        end
    endgenerate

    //Result

    always_comb begin
        res_vld      = '0;
        res          = '0;
        res_negative = '0;
        err          = '0;
        busy         = '0;

        for (int j = 0; j < N; j++)
            if (inst_res_vld [j]) begin
                res_vld      = 1'b1;
                res          = inst_res          [j];
                res_negative = inst_res_negative [j];
                err          = inst_err          [j];
                busy         = inst_busy         [j];
            end
    end

endmodule

