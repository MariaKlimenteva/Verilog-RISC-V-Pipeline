`include "defs.vh"
`timescale 1ns / 1ps

module instruction_memory #(
    parameter int ADDR_WIDTH = XLEN,
    parameter int MEM_DEPTH  = 1024
  ) (
    input logic [ADDR_WIDTH-1:0] addr,
    output logic [XLEN-1:0] instr
  );

  localparam int INDEX_WIDTH = $clog2(MEM_DEPTH);

  logic [XLEN-1:0] mem [0:MEM_DEPTH-1];

  logic [INDEX_WIDTH-1:0] word_index;
  generate
    if (ADDR_WIDTH >= 2) begin : gen_addr_normal
        assign word_index = addr[INDEX_WIDTH + 1:2];
    end else begin : gen_addr_small
        assign word_index = {INDEX_WIDTH{1'b0}};
    end
  endgenerate

  assign instr = mem[word_index];
endmodule