module id_ex_register #(
    parameter XLEN = 32,
    parameter ALU_OP_WIDTH = 4,
    parameter NOP_ALUOP = 4'bxxxx,
    parameter NOP_RD_ADDR = 5'b00000
  )(
    input wire clk,
    input wire rst, 

    // --- Inputs from Decode Stage (ID) ---
    // Control Signals
    input wire                     id_regwrite,    // Write to register file in WB?
    input wire                     id_memtoreg,    // MUX selector for WB data source (ALU result or Memory data)
    input wire                     id_memread,     // Read from data memory in MEM?
    input wire                     id_memwrite,    // Write to data memory in MEM?
    input wire                     id_branch,      // Is this a branch instruction? (Used for control hazard)
    input wire                     id_alusrc,      // MUX selector for ALU operand B (rs2 or immediate)
    input wire [ALU_OP_WIDTH-1:0]  id_aluop,

    // Data/Operands
    input wire [XLEN-1:0] id_pc_plus_4,   // PC+4 value for JAL/JALR return address calculation
    input wire [XLEN-1:0] id_rs1_data,    // Data from read port 1 of RegFile
    input wire [XLEN-1:0] id_rs2_data,    // Data from read port 2 of RegFile
    input wire [XLEN-1:0] id_immediate,   // Sign-extended immediate value
    input wire [4:0]      id_rs1_addr,    // Address of rs1 (for forwarding logic)
    input wire [4:0]      id_rs2_addr,    // Address of rs2 (for forwarding logic)
    input wire [4:0]      id_rd_addr,     // Destination register address (where result is written)


    // --- Outputs to Execute Stage (EX) ---
    // Control Signals (passed through)
    output reg                     ex_regwrite,
    output reg                     ex_memtoreg,
    output reg                     ex_memread,
    output reg                     ex_memwrite,
    output reg                     ex_branch,
    output reg                     ex_alusrc,
    output reg [ALU_OP_WIDTH-1:0]  ex_aluop,

    // Data/Operands (passed through)
    output reg [XLEN-1:0] ex_pc_plus_4,
    output reg [XLEN-1:0] ex_rs1_data,
    output reg [XLEN-1:0] ex_rs2_data,
    output reg [XLEN-1:0] ex_immediate,
    output reg [4:0]      ex_rs1_addr,
    output reg [4:0]      ex_rs2_addr,
    output reg [4:0]      ex_rd_addr
  );

  localparam NOP_REGWRITE = 1'b0;
  localparam NOP_MEMTOREG = 1'b0; 
  localparam NOP_MEMREAD  = 1'b0;
  localparam NOP_MEMWRITE = 1'b0;
  localparam NOP_BRANCH   = 1'b0;
  localparam NOP_ALUSRC   = 1'b0; 

  always @(posedge clk or posedge rst)
  begin
    if (rst)
    begin
      // Reset all control signals to 'NOP'
      ex_regwrite  <= NOP_REGWRITE;
      ex_memtoreg  <= NOP_MEMTOREG;
      ex_memread   <= NOP_MEMREAD;
      ex_memwrite  <= NOP_MEMWRITE;
      ex_branch    <= NOP_BRANCH;
      ex_alusrc    <= NOP_ALUSRC;
      ex_aluop     <= NOP_ALUOP;
      
      ex_pc_plus_4 <= {XLEN{1'b0}};
      ex_rs1_data  <= {XLEN{1'b0}};
      ex_rs2_data  <= {XLEN{1'b0}};
      ex_immediate <= {XLEN{1'b0}};
      ex_rs1_addr  <= 5'b00000;
      ex_rs2_addr  <= 5'b00000;
      ex_rd_addr   <= NOP_RD_ADDR; 
    end
    else
    begin
      // Pass control signals
      ex_regwrite  <= id_regwrite;
      ex_memtoreg  <= id_memtoreg;
      ex_memread   <= id_memread;
      ex_memwrite  <= id_memwrite;
      ex_branch    <= id_branch;
      ex_alusrc    <= id_alusrc;
      ex_aluop     <= id_aluop;
      // Pass data/operands
      ex_pc_plus_4 <= id_pc_plus_4;
      ex_rs1_data  <= id_rs1_data;
      ex_rs2_data  <= id_rs2_data;
      ex_immediate <= id_immediate;
      ex_rs1_addr  <= id_rs1_addr;
      ex_rs2_addr  <= id_rs2_addr;
      ex_rd_addr   <= id_rd_addr;
    end
  end
endmodule
