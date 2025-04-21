module if_id_register #(
    parameter XLEN = 32,
    parameter NOP_INSTRUCTION = 32'h00000013
  ) (
    input wire clk,
    input wire rst,

    input wire [XLEN-1:0] if_instruction,
    input wire [XLEN-1:0] if_pc_plus_4,

    output reg [XLEN-1:0] id_instruction,
    output reg [XLEN-1:0] id_pc_plus_4
  );
  always @(posedge clk or posedge rst)
  begin
    if (rst)
    begin
      id_instruction <= NOP_INSTRUCTION;
      id_pc_plus_4   <= {XLEN{1'b0}};
    end
    else
    begin
      id_instruction <= if_instruction;
      id_pc_plus_4   <= if_pc_plus_4;
    end
  end
endmodule