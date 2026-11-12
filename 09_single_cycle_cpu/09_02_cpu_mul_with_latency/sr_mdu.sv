//
//  schoolRISCV - small RISC-V CPU
//
//  Originally based on Sarah L. Harris MIPS CPU
//  & schoolMIPS project.
//
//  Copyright (c) 2017-2020 Stanislav Zhelnio & Aleksandr Romanov.
//
//  Modified in 2024 by Yuri Panchul & Mike Kuskov
//  for systemverilog-homework project.
//

`include "sr_cpu.svh"

module sr_mdu
# (
    parameter n_delay = 2
)
(
    input               clk,
    input               rst,

    input               i_vld,
    input        [31:0] srcA,
    input        [31:0] srcB,
    output              o_vld,
    output logic [31:0] result,
    output              busy
);

    wire [63:0] mult_res = srcA * srcB;

    shift_register_with_valid # (
        .width ( 64      ),
        .depth ( n_delay )
    ) shift_reg (
        .clk      ( clk      ),
        .rst      ( rst      ),
        .in_vld   ( i_vld    ),
        .in_data  ( mult_res ),
        .out_vld  ( o_vld    ),
        .out_data ( result   )
    );

endmodule

//----------------------------------------------------------------------------

/* module shift_register
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input  [width - 1:0] in_data,
    output [width - 1:0] out_data
);
    logic [width - 1:0] data [0:depth - 1];

    always_ff @ (posedge clk)
    begin
        data [0] <= in_data;

        for (int i = 1; i < depth; i ++)
            data [i] <= data [i - 1];
    end

    assign out_data = data [depth - 1];

endmodule
 */

 module shift_register_with_valid
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input                rst,

    input                in_vld,
    input  [width - 1:0] in_data,

    output               out_vld,
    output [width - 1:0] out_data
);

    logic [width - 1:0] data [0:depth - 1];
    logic [depth - 1:0] vld;

    always_ff @ (posedge clk) begin
        if (rst)
            vld <= '0;
        else begin
            vld [0] <= in_vld;  
            for (int i = 1; i < depth; i++)
                vld  [i] <= vld  [i - 1];                     
        end
    end

    always_ff @ (posedge clk) begin
        if (in_vld)
            data [0] <= in_data;

        for (int i = 1; i < depth; i++) begin
            if (vld [i - 1])
                data [i] <= data [i - 1];   
        end
             
    end 

    assign out_vld  = vld  [depth - 1];
    assign out_data = data [depth - 1];

endmodule
