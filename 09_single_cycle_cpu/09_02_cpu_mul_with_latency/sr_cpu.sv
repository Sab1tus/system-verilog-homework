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

module sr_cpu
(
    input           clk,      // clock
    input           rst,      // reset

    output  [31:0]  imAddr,   // instruction memory address
    input   [31:0]  imData,   // instruction memory data

    input   [ 4:0]  regAddr,  // debug access reg address
    output  [31:0]  regData   // debug access reg data
);
    // control wires

    wire        aluZero;
    wire        pcSrc;
    wire        regWrite;
    wire        aluSrc;
    wire        wdSrc;
    wire  [2:0] aluControl;

    wire instr_uses_rs1 = ~wdSrc;
    wire instr_uses_rs2 = ~wdSrc && ~aluSrc;

    // mul wires

    wire [31:0] multResult;
    wire        mult_vld;

    // instruction decode wires

    wire [ 6:0] cmdOp;
    wire [ 4:0] rd;
    wire [ 2:0] cmdF3;
    wire [ 4:0] rs1;
    wire [ 4:0] rs2;
    wire [ 6:0] cmdF7;
    wire [31:0] immI;
    wire [31:0] immB;
    wire [31:0] immU;

    // program counter

    wire [31:0] pc;
    wire [31:0] pcBranch = pc + immB;
    wire [31:0] pcPlus4  = pc + 32'd4;
    wire [31:0] pcNext   = pcSrc ? pcBranch : pcPlus4;

    // processor stalling

    wire raw_hazard_rs1 = instr_uses_rs1    && 
                          mul_p1_vld        && 
                         (mul_p1_rd == rs1) && 
                         (mul_p1_rd != '0);

    wire raw_hazard_rs2 = instr_uses_rs2    && 
                          mul_p1_vld        && 
                         (mul_p1_rd == rs2) && 
                         (mul_p1_rd != '0);    
    
    wire wb_hazard      = regWrite           && 
                          mul_p2_vld         && 
                         (rd         != '0)  && 
                         (mul_p2_rd  != '0)  &&
                         (aluControl != `ALU_MUL); 
    
    wire stall = raw_hazard_rs1 | raw_hazard_rs2 | wb_hazard;

    register_with_rst_and_en r_pc
    (
        .clk      ( clk       ),
        .rst      ( rst       ),
        .d        ( pcNext    ),
        .q        ( pc        ),
        .en       ( !stall    )
    );

    // program memory access

    assign imAddr = pc >> 2;
    wire [31:0] instr = imData;

    // instruction decode

    sr_decode id
    (
        .instr      ( instr       ),
        .cmdOp      ( cmdOp       ),
        .rd         ( rd          ),
        .cmdF3      ( cmdF3       ),
        .rs1        ( rs1         ),
        .rs2        ( rs2         ),
        .cmdF7      ( cmdF7       ),
        .immI       ( immI        ),
        .immB       ( immB        ),
        .immU       ( immU        )
    );

    // register file

    wire [31:0] rd0;
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] wd3;

    // register file for mux

    logic        rf_we3;
    logic [ 4:0] rf_a3;
    logic [31:0] rf_wd3;

    sr_register_file i_rf
    (
        .clk        ( clk         ),
        .a0         ( regAddr     ),
        .a1         ( rs1         ),
        .a2         ( rs2         ),
        .a3         ( rf_a3       ),
        .rd0        ( rd0         ),
        .rd1        ( rd1         ),
        .rd2        ( rd2         ),
        .wd3        ( rf_wd3      ),
        .we3        ( rf_we3      )
    );

    // alu

    wire [31:0] aluResult;

    sr_alu alu
    (
        .srcA       ( srcA        ),
        .srcB       ( srcB        ),
        .oper       ( aluControl  ),
        .zero       ( aluZero     ),
        .result     ( aluResult   )
    );

    // shift registers for mul results

    wire       mul_p1_vld, mul_p2_vld;
    wire [4:0] mul_p1_rd, mul_p2_rd;

    shift_register_with_valid 
    # (
        .width(5),
        .depth(1)
    ) pipe_1 (
        .clk      ( clk                       ),
        .rst      ( rst                       ),
        .in_vld   ( aluControl == `ALU_MUL &&
                    ~stall                    ),
        .in_data  ( rd                        ),
        .out_vld  ( mul_p1_vld                ),
        .out_data ( mul_p1_rd                 )
    );

    shift_register_with_valid 
    # (
        .width(5),
        .depth(1)
    ) pipe_2 (
        .clk      ( clk                       ),
        .rst      ( rst                       ),
        .in_vld   ( mul_p1_vld                ),
        .in_data  ( mul_p1_rd                 ),
        .out_vld  ( mul_p2_vld                ),
        .out_data ( mul_p2_rd                 )
    );

    // mul

    sr_mdu mdu
    (
        .clk    ( clk                      ),
        .rst    ( rst                      ),

        .i_vld  ( aluControl == `ALU_MUL &&
                  ~stall                   ),
        .srcA   ( srcA                     ),
        .srcB   ( forwarded_rd2            ),
        .o_vld  ( mult_vld                 ),
        .result ( multResult               ),
        .busy   (                          )
    );

    // mul muxes and forwarding

    wire forward_a = instr_uses_rs1    && 
                     mul_p2_vld        && 
                    (mul_p2_rd == rs1) && 
                    (mul_p2_rd != '0);

    wire forward_b = instr_uses_rs2    && 
                     mul_p2_vld        && 
                    (mul_p2_rd == rs2) && 
                    (mul_p2_rd != '0);

    wire [31:0] srcA           = forward_a ? multResult : rd1;
    wire [31:0] forwarded_rd2  = forward_b ? multResult : rd2;
    wire [31:0] srcB           = aluSrc    ? immI       : forwarded_rd2;

    // writeback mux

    always_comb begin
        if (mul_p2_vld && (mul_p2_rd != '0)) begin
            rf_we3 = 1'b1;
            rf_a3  = mul_p2_rd;
            rf_wd3 = multResult;
        end
        else if (regWrite && (rd != '0)  && 
                (aluControl != `ALU_MUL) && ~stall) begin
            rf_we3 = 1'b1;
            rf_a3  = rd;
            rf_wd3 = wdSrc ? immU : aluResult;            
        end
        else begin
            rf_we3 = '0;
            rf_a3  = '0;
            rf_wd3 = '0;
        end
    end

    // control

    sr_control sm_control
    (
        .cmdOp      ( cmdOp       ),
        .cmdF3      ( cmdF3       ),
        .cmdF7      ( cmdF7       ),
        .aluZero    ( aluZero     ),
        .pcSrc      ( pcSrc       ),
        .regWrite   ( regWrite    ),
        .aluSrc     ( aluSrc      ),
        .wdSrc      ( wdSrc       ),
        .aluControl ( aluControl  )
    );

    // debug register access

    assign regData = (regAddr != '0) ? rd0 : pc;

endmodule
