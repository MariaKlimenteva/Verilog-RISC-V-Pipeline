`include "alu_opcodes.vh"
`include "defs.vh"
`timescale 1ns / 1ps
module alu #()(
    input logic [XLEN-1:0] src1,
    input logic [XLEN-1:0] src2,
    input logic [ALU_OP_WIDTH-1:0] alu_op,

    output logic [XLEN-1:0] result,
    output logic zero 
  );
  localparam SHAMT_WIDTH = $clog2(XLEN);
  logic [SHAMT_WIDTH-1:0] shamt = src2[SHAMT_WIDTH-1:0];

  always @(*)
  begin
    result = {XLEN{1'bx}};
    case (alu_op)
      `ALU_OP_ADD:
        result = src1 + src2;
      `ALU_OP_SUB:
        result = src1 - src2;
      `ALU_OP_AND:
        result = src1 & src2;
      `ALU_OP_OR:
        result = src1 | src2;
      `ALU_OP_XOR:
        result = src1 ^ src2;
      `ALU_OP_SLL:
        result = src1 << shamt;
      `ALU_OP_SRL:
        result = src1 >> shamt;
      `ALU_OP_SRA:
        result = $signed(src1) >>> shamt;

      `ALU_OP_SLT:  
        if ($signed(src1) < $signed(src2))
          result = {{XLEN-1{1'b0}}, 1'b1}; 
        else
          result = {XLEN{1'b0}}; 

      `ALU_OP_SLTU: 
        if (src1 < src2)
          result = {{XLEN-1{1'b0}}, 1'b1}; 
        else
          result = {XLEN{1'b0}}; 

      `ALU_OP_COPY_SRC1:
        result = src1; 
      `ALU_OP_COPY_SRC2:
        result = src2; 

      default:
      begin
        result = {XLEN{1'bx}};
      end
    endcase
  end
  assign zero = (result == {XLEN{1'b0}});
endmodule