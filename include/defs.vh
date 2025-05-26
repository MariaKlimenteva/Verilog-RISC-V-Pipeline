`ifndef PIPELINE_DEFS_VH
`define PIPELINE_DEFS_VH

`timescale 1ns / 1ps

parameter XLEN = 32;
parameter ALU_OP_WIDTH = 4;
parameter logic [XLEN-1:0] NOP_INSTRUCTION = 32'h00000013;

typedef struct packed {
    logic [ALU_OP_WIDTH-1:0] ALUOp;
    logic ALUSrc;
    logic MemRead;
    logic MemWrite;
    logic MemToReg;
    logic RegWrite;
    logic Branch;
    logic Jump;
    logic Jalr;
    logic [2:0] BranchType;
    logic [31:0] return_code_j;
} control_signals;

typedef struct packed {
    logic [31:0] instruction;
    logic [31:0] pc_plus_4;
    logic valid;
} if_id_data;

typedef struct packed {
    control_signals control;

    logic [31:0] pc_plus_4;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] immediate;
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;
    logic valid;
} id_ex_data;

typedef struct packed {
    control_signals control;

    logic [31:0] alu_result;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [4:0]  rd_addr;
    logic valid;
} ex_mem_data;

typedef struct packed {
    control_signals control;
    logic [31:0] read_data;  
    logic [31:0] alu_result; 
    logic [4:0]  rd_addr;
    logic valid;
} mem_wb_data;

`endif // PIPELINE_DEFS_VH