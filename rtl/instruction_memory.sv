`include "defs.vh"
`timescale 1ns / 1ps

module instruction_memory #(
    parameter int ADDR_WIDTH = XLEN,
    parameter int MEM_DEPTH  = 1024,
    parameter string INIT_FILE  = ""
  ) (
    input logic [ADDR_WIDTH-1:0] addr,
    output logic [XLEN-1:0] instr
  );

  localparam int INDEX_WIDTH = $clog2(MEM_DEPTH);

  logic [XLEN-1:0] mem [0:MEM_DEPTH-1];

  initial begin
    /* verilator lint_off WIDTH */
    if (INIT_FILE != "") begin
    /* verilator lint_on WIDTH */
      $display("IMEM: Initializing from %s", INIT_FILE);
      $readmemh(INIT_FILE, mem);
    end else begin
      for (int i = 0; i < MEM_DEPTH; i++) begin
        mem[i] = '0;
      end
      $display("Instruction Memory initialized with default values (no INIT_FILE specified).");
    end
  end

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