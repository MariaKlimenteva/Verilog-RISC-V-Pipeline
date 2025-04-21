module register_file #(
    parameter XLEN = 32,
    parameter REG_DEPTH = 32,
    parameter ZERO_REG_ADDR = 5'b0
  ) (
    input wire clk,
    input wire rst,

    input wire [4:0] rs1_addr,
    output wire [XLEN-1:0] rs1_rdata,

    input wire [4:0] rs2_addr,
    output wire [XLEN-1:0] rs2_rdata,

    input wire we,
    input wire [4:0] rd_addr,
    input wire [XLEN-1:0] rd_wdata
  );
  localparam ADDR_WIDTH = $clog2(REG_DEPTH);

  reg [XLEN-1:0] registers [0:REG_DEPTH-1];

  // --- Write Logic ---
  always @(posedge clk or posedge rst)
  begin
    if (rst)
    begin
      // Reset: Initialize all registers to zero
      integer i;
      for (i = 0; i < REG_DEPTH; i = i + 1)
      begin
        registers[i] <= {XLEN{1'b0}};
      end
    end
    else
    begin
      if (we && (rd_addr != ZERO_REG_ADDR))
      begin
        registers[rd_addr] <= rd_wdata; 
      end
    end
  end

  // --- Read Logic ---
  assign rs1_rdata = (rs1_addr == ZERO_REG_ADDR) ? {XLEN{1'b0}} : registers[rs1_addr];
  assign rs2_rdata = (rs2_addr == ZERO_REG_ADDR) ? {XLEN{1'b0}} : registers[rs2_addr];
endmodule
