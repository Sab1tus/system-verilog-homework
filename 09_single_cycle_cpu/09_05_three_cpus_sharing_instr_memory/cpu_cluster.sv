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

module cpu_cluster
#(
    parameter nCPUs = 3
)
(
    input                        clk,      // clock
    input                        rst,      // reset

    input   [nCPUs - 1:0][31:0]  rstPC,    // program counter set on reset
    input   [nCPUs - 1:0][ 4:0]  regAddr,  // debug access reg address
    output  [nCPUs - 1:0][31:0]  regData   // debug access reg data
);


    localparam N_BANKS  = 4;
    localparam ROM_SIZE = 64;
    localparam ADDR_W   = $clog2(ROM_SIZE);

    wire  [31:0] imAddr    [nCPUs];
    logic [31:0] imData    [nCPUs];
    logic        imDataVld [nCPUs];

    wire [1:0] cpu_req_bank [nCPUs];
    generate
        for (genvar i = 0; i < nCPUs; i++) begin : gen_req_bank
            assign cpu_req_bank [i] = imAddr [i][1:0];
        end
    endgenerate

    logic [7:0] bank_req [N_BANKS];
    wire  [7:0] bank_gnt [N_BANKS];

    always_comb begin
        for (int b = 0; b < N_BANKS; b++) begin
            bank_req [b] = 8'b0;
            if (!rst)
                for (int i = 0; i < nCPUs; i++) begin
                    if (cpu_req_bank [i] == b[1:0])
                        bank_req [b][i] = 1'b1;
                end
        end
    end

    generate
        for (genvar b = 0; b < N_BANKS; b++) begin : gen_bank_arbiters
            round_robin_arbiter_8 arbiter
            (
                .clk ( clk          ),
                .rst ( rst          ),
                .req ( bank_req [b] ),
                .gnt ( bank_gnt [b] )
            );
        end
    endgenerate

    logic [ADDR_W - 1:0] bank_a  [N_BANKS];
    wire  [        31:0] bank_rd [N_BANKS];

    always_comb begin
        for (int b = 0; b < N_BANKS; b++) begin
            bank_a [b] = '0;
            if (bank_gnt [b][0])      bank_a [b] = imAddr [0][ADDR_W - 1:0];
            else if (bank_gnt [b][1]) bank_a [b] = imAddr [1][ADDR_W - 1:0];
            else if (bank_gnt [b][2]) bank_a [b] = imAddr [2][ADDR_W - 1:0];
        end
    end

    generate
        for (genvar b = 0; b < N_BANKS; b++) begin : gen_memory_banks
            instruction_rom
            #(
                .SIZE   ( ROM_SIZE ),
                .ADDR_W ( ADDR_W   )
            )
            bank_rom
            (
                .a  ( bank_a  [b]  ),
                .rd ( bank_rd [b]  )
            );
        end
    endgenerate

    always_comb begin
        for (int i = 0; i < nCPUs; i++) begin
            int b;
            b = cpu_req_bank [i];

            if (!rst && (| bank_gnt [b][2:0]) && (bank_a [b] == imAddr [i][ADDR_W - 1:0])) begin
                imDataVld [i] = 1'b1;
                imData    [i] = bank_rd [b];
            end else begin
                imDataVld [i] = '0;
                imData    [i] = 32'h00000013;
            end
        end
    end

    generate
        for (genvar i = 0; i < nCPUs; i++) begin : gen_cpus
            sr_cpu cpu
            (
                .clk       ( clk            ),
                .rst       ( rst            ),
                .rstPC     ( rstPC     [i]  ),
                .imAddr    ( imAddr    [i]  ),
                .imData    ( imData    [i]  ),
                .imDataVld ( imDataVld [i]  ),
                .regAddr   ( regAddr   [i]  ),
                .regData   ( regData   [i]  )
            );
        end
    endgenerate


endmodule
