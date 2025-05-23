`ifndef RV_OPCODES_VH
`define RV_OPCODES_VH

`define OPCODE_LOAD     7'b0000011 // I-type
`define OPCODE_IMM      7'b0010011 // I-type
`define OPCODE_AUIPC    7'b0010111 // U-type
`define OPCODE_STORE    7'b0100011 // S-type
`define OPCODE_REG      7'b0110011 // R-type
`define OPCODE_LUI      7'b0110111 // U-type
`define OPCODE_BRANCH   7'b1100011 // B-type
`define OPCODE_JALR     7'b1100111 // I-type
`define OPCODE_JAL      7'b1101111 // J-type 

`endif