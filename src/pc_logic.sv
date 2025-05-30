`timescale 1ns / 1ps
module pc_logic #(
    parameter RESET_VECTOR = 32'h00000000
  ) (
    input logic clk,
    input logic rst,
    input logic [XLEN-1:0] branch_target_in,
    input logic take_branch,
    input logic jump,
    input logic branch,
    input logic stallF,

    output logic [XLEN-1:0] pc_out,
    output logic [XLEN-1:0] pc_plus_4
  );

  logic [XLEN-1:0] current_pc;
  logic [XLEN-1:0] next_pc;

  always_comb begin : select_next_pc
    if (jump || branch && take_branch) begin
      next_pc = branch_target_in;
    end else begin
      next_pc = current_pc + 4;
    end
  end

  always_ff @( posedge clk or posedge rst ) begin
    if (rst) begin
      current_pc <= RESET_VECTOR;
    end else if (!stallF) begin
      current_pc <= next_pc;
    end
  end

  assign pc_out = current_pc;
  assign pc_plus_4 = current_pc + 4;
endmodule