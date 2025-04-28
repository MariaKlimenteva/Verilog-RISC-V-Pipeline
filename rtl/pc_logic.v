module pc_logic #(
    parameter XLEN = 32,
    parameter RESET_VECTOR = 32'h00000000
  ) (
    input wire clk,
    input wire rst,

    input wire pc_write_enable,
    input wire [XLEN-1:0] next_pc_select_in,
    input wire pc_sel,

    output wire [XLEN-1:0] pc_out
  );

  reg [XLEN-1:0] current_pc;
  wire [XLEN-1:0] pc_plus_4;
  wire [XLEN-1:0] next_pc;

  assign pc_plus_4 = current_pc + 4;

  // если pc_sel=1, берем адрес перехода, иначе берем pc+4
  // assign next_pc = (pc_sel == 1'b1) ? next_pc_select_in : pc_plus_4;
  assign next_pc = pc_plus_4;

  always @(posedge clk or posedge rst)
  begin
    if (rst)
    begin
      current_pc <= RESET_VECTOR;
    end
    else
    begin
      if (pc_write_enable)
      begin
        current_pc <= next_pc;
      end
    end
  end

  assign pc_out = current_pc;
endmodule
