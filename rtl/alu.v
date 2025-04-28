module alu #(
    parameter XLEN = 32,
    parameter ALU_OP_WIDTH  = 4
  )(
    input wire [XLEN-1:0] src1,
    input wire [XLEN-1:0] src2,
    input wire [ALU_OP_WIDTH-1:0] alu_op,

    output reg [XLEN-1:0] result,
    output wire zero 
  );
  localparam ALU_OP_ADD  = 4'b0000;
  localparam ALU_OP_SUB  = 4'b0001;
  localparam ALU_OP_AND  = 4'b0010;
  localparam ALU_OP_OR   = 4'b0011;
  localparam ALU_OP_XOR  = 4'b0100;
  localparam ALU_OP_SLT  = 4'b0101; 
  localparam ALU_OP_SLTU = 4'b0110; 
  localparam ALU_OP_SLL  = 4'b0111; 
  localparam ALU_OP_SRL  = 4'b1000; 
  localparam ALU_OP_SRA  = 4'b1001; 
  localparam ALU_OP_COPY_SRC1 = 4'b1010;
  localparam ALU_OP_COPY_SRC2 = 4'b1011; 

  localparam SHAMT_WIDTH = $clog2(XLEN);
  wire [SHAMT_WIDTH-1:0] shamt = src2[SHAMT_WIDTH-1:0];

  always @(*)
  begin
    result = {XLEN{1'bx}};
    case (alu_op)
      ALU_OP_ADD:
        result = src1 + src2;
      ALU_OP_SUB:
        result = src1 - src2;
      ALU_OP_AND:
        result = src1 & src2;
      ALU_OP_OR:
        result = src1 | src2;
      ALU_OP_XOR:
        result = src1 ^ src2;
      ALU_OP_SLL:
        result = src1 << shamt;
      ALU_OP_SRL:
        result = src1 >> shamt;
      ALU_OP_SRA:
        result = $signed(src1) >>> shamt;

      ALU_OP_SLT:  
        if ($signed(src1) < $signed(src2))
          result = {{XLEN-1{1'b0}}, 1'b1}; 
        else
          result = {XLEN{1'b0}}; 

      ALU_OP_SLTU: 
        if (src1 < src2)
          result = {{XLEN-1{1'b0}}, 1'b1}; 
        else
          result = {XLEN{1'b0}}; 

      ALU_OP_COPY_SRC1:
        result = src1; 
      ALU_OP_COPY_SRC2:
        result = src2; 

      default:
      begin
        result = {XLEN{1'bx}};
      end
    endcase
  end
  assign zero = (result == {XLEN{1'b0}});
endmodule
