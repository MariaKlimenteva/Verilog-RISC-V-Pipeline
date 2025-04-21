module ex_mem_register #(
    parameter XLEN = 32,
    parameter NOP_RD_ADDR = 5'b00000 
) (
    input wire clk,
    input wire rst, 

    // --- Inputs from Execute Stage (EX) ---
    // Control Signals for MEM and WB stages
    input wire        ex_regwrite,    // Write to register file in WB? (Pass through)
    input wire        ex_memtoreg,    // MUX selector for WB data source (Pass through)
    input wire        ex_memread,     // Read from data memory in MEM? (Used in MEM)
    input wire        ex_memwrite,    // Write to data memory in MEM? (Used in MEM)
    input wire        ex_branch,      // Was this a branch? (Used for hazards, pass through if needed later)

    // Data/Results from EX stage
    input wire [XLEN-1:0] ex_alu_result,  // Result from ALU calculation
    input wire [XLEN-1:0] ex_rs2_data,    // Original rs2 data (needed for SW instruction)
    input wire [4:0]      ex_rd_addr,     // Destination register address (Pass through for WB)

    // --- Outputs to Memory Stage (MEM) ---
    // Control Signals
    output reg        mem_regwrite,
    output reg        mem_memtoreg,
    output reg        mem_memread,
    output reg        mem_memwrite,
    output reg        mem_branch,

    // Data/Results
    output reg [XLEN-1:0] mem_alu_result,
    output reg [XLEN-1:0] mem_rs2_data,
    output reg [4:0]      mem_rd_addr
);

    localparam NOP_REGWRITE = 1'b0;
    localparam NOP_MEMTOREG = 1'b0;
    localparam NOP_MEMREAD  = 1'b0;
    localparam NOP_MEMWRITE = 1'b0;
    localparam NOP_BRANCH   = 1'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_regwrite   <= NOP_REGWRITE;
            mem_memtoreg   <= NOP_MEMTOREG;
            mem_memread    <= NOP_MEMREAD;
            mem_memwrite   <= NOP_MEMWRITE;
            mem_branch     <= NOP_BRANCH;
            
            mem_alu_result <= {XLEN{1'b0}};
            mem_rs2_data   <= {XLEN{1'b0}};
            mem_rd_addr    <= NOP_RD_ADDR;
        end
        else begin
            mem_regwrite   <= ex_regwrite;
            mem_memtoreg   <= ex_memtoreg;
            mem_memread    <= ex_memread;
            mem_memwrite   <= ex_memwrite;
            mem_branch     <= ex_branch; 
            mem_alu_result <= ex_alu_result;
            mem_rs2_data   <= ex_rs2_data;  
            mem_rd_addr    <= ex_rd_addr;   
        end
    end

endmodule