`timescale 1ns / 1ps
module register_file #(
    parameter int REG_DEPTH = 32,
    parameter logic [4:0] ZERO_REG_ADDR = 5'b0
  ) (
    input logic clk,
    input logic rst,
    input logic [4:0] rs1_addr,
    input logic [4:0] rs2_addr,
    input logic we,
    input logic [4:0] rd_addr,
    input logic [XLEN-1:0] rd_wdata,

    output logic [XLEN-1:0] rs1_rdata,
    output logic [XLEN-1:0] rs2_rdata
  );
  reg [XLEN-1:0] registers [0:REG_DEPTH-1];

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      for (int i = 0; i < REG_DEPTH; i++) begin
        registers[i] <= '0;
      end
    end else begin
      if (we && (rd_addr != ZERO_REG_ADDR)) begin
        registers[rd_addr] <= rd_wdata;
      end
    end
  end

  assign rs1_rdata = (rs1_addr == ZERO_REG_ADDR) ? {XLEN{1'b0}} : registers[rs1_addr];
  assign rs2_rdata = (rs2_addr == ZERO_REG_ADDR) ? {XLEN{1'b0}} : registers[rs2_addr];
endmodule