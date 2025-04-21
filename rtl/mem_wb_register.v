module mem_wb_register #(
    parameter XLEN = 32,
    parameter NOP_RD_ADDR = 5'b00000 
) (
    input wire clk,
    input wire rst, 

    // --- Inputs from Memory Stage (MEM) ---
    // Control Signals for WB stage
    input wire        mem_regwrite, // Write to register file in WB? (Pass through)
    input wire        mem_memtoreg, // MUX selector for WB data source (Pass through)

    // Data Results from MEM stage
    input wire [XLEN-1:0] mem_read_data,  // Data read from Data Memory (for LW, LH, LB)
    input wire [XLEN-1:0] mem_alu_result, // Result from ALU (passed through EX/MEM)
    input wire [4:0]      mem_rd_addr,    // Destination register address (passed through EX/MEM)

    // --- Outputs to Writeback Stage (WB) ---
    // Control Signals
    output reg        wb_regwrite,
    output reg        wb_memtoreg,

    // Data Results
    output reg [XLEN-1:0] wb_read_data,
    output reg [XLEN-1:0] wb_alu_result,
    output reg [4:0]      wb_rd_addr
);

    localparam NOP_REGWRITE = 1'b0;
    localparam NOP_MEMTOREG = 1'b0; 

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset control signals to safe NOP values
            wb_regwrite   <= NOP_REGWRITE;
            wb_memtoreg   <= NOP_MEMTOREG;
            // Reset data/address outputs
            wb_read_data  <= {XLEN{1'b0}};
            wb_alu_result <= {XLEN{1'b0}};
            wb_rd_addr    <= NOP_RD_ADDR; // Target x0
        end
        else begin
            // Pass control signals needed for WB
            wb_regwrite   <= mem_regwrite;
            wb_memtoreg   <= mem_memtoreg;
            // Pass data values needed for WB
            wb_read_data  <= mem_read_data;  // Pass data read from memory
            wb_alu_result <= mem_alu_result; // Pass ALU result
            wb_rd_addr    <= mem_rd_addr;    // Pass destination address
        end
    end
endmodule