`ifndef ALU_OPCODES_VH
`define ALU_OPCODES_VH

`define ALU_OP_ADD          4'b0000
`define ALU_OP_SUB          4'b0001
`define ALU_OP_AND          4'b0010
`define ALU_OP_OR           4'b0011
`define ALU_OP_XOR          4'b0100
`define ALU_OP_SLT          4'b0101
`define ALU_OP_SLTU         4'b0110
`define ALU_OP_SLL          4'b0111
`define ALU_OP_SRL          4'b1000
`define ALU_OP_SRA          4'b1001
`define ALU_OP_COPY_SRC1    4'b1010 
`define ALU_OP_COPY_SRC2    4'b1011 
`define ALU_OP_X            4'bxxxx

`endif