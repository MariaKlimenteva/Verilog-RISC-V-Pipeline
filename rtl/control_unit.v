module control_unit #(
    parameter ALU_OP_WIDTH = 4 
) (
    // --- Inputs (from instruction fields decoded in ID stage) ---
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7, // Only bit 5 (funct7[5]) is needed for ADD/SUB/SRAI/SRLI differentiation in base ISA

    // --- Outputs (Control signals for EX, MEM, WB stages) ---
    // These outputs go to the ID/EX pipeline register inputs
    output reg        RegWrite_o,   // Enable Register File Write in WB
    output reg        MemToReg_o,   // Selects Writeback data source (0=ALU, 1=Mem)
    output reg        MemRead_o,    // Enable Data Memory Read in MEM
    output reg        MemWrite_o,   // Enable Data Memory Write in MEM
    output reg        Branch_o,     // Indicates a branch type instruction (for EX stage)
    output reg        ALUSrc_o,     // Selects ALU Operand B source (0=rs2, 1=Immediate)
    output reg [ALU_OP_WIDTH-1:0] ALUOp_o // Specifies the operation for the ALU
    // output reg        Jump_o;    // Optional: Specific signal for JAL/JALR if needed
);

    // --- Define RISC-V Opcodes ---
    localparam OPCODE_LOAD   = 7'b0000011; // I-type
    localparam OPCODE_IMM    = 7'b0010011; // I-type
    localparam OPCODE_AUIPC  = 7'b0010111; // U-type
    localparam OPCODE_STORE  = 7'b0100011; // S-type
    // localparam OPCODE_AMO    = 7'b0101111; // Not implemented here
    localparam OPCODE_REG    = 7'b0110011; // R-type
    localparam OPCODE_LUI    = 7'b0110111; // U-type
    localparam OPCODE_BRANCH = 7'b1100011; // B-type
    localparam OPCODE_JALR   = 7'b1100111; // I-type
    localparam OPCODE_JAL    = 7'b1101111; // J-type
    // localparam OPCODE_SYSTEM = 7'b1110011; // Not implemented here

    // --- Define ALU Operation Codes ---
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
    // localparam ALU_OP_COPY_SRC1 = 4'b1010; // Needed for JAL/JALR PC+4 handling if done via ALU
    localparam ALU_OP_COPY_SRC2 = 4'b1011; // Needed for LUI

    // --- Combinational Logic for Control Signal Generation ---
    always @(*) begin
        // Default values (conservative/NOP-like behavior)
        RegWrite_o = 1'b0;
        MemToReg_o = 1'b0; // Default to ALU result (or don't care if RegWrite=0)
        MemRead_o  = 1'b0;
        MemWrite_o = 1'b0;
        Branch_o   = 1'b0;
        ALUSrc_o   = 1'b0; // Default to using rs2
        ALUOp_o    = ALU_OP_ADD; // Default ALUOp (e.g., ADD, or 'x' if ALU handles it)
        // Jump_o     = 1'b0;

        // Decode based on opcode
        case (opcode)
            OPCODE_REG: begin // R-type (ADD, SUB, AND, OR, etc.)
                RegWrite_o = 1'b1;
                MemToReg_o = 1'b0; // Result comes from ALU
                MemRead_o  = 1'b0;
                MemWrite_o = 1'b0;
                Branch_o   = 1'b0;
                ALUSrc_o   = 1'b0; // Use rs2 data for operand B
                // Determine specific ALU operation based on funct3 and funct7
                case (funct3)
                    3'b000: ALUOp_o = (funct7[5]) ? ALU_OP_SUB : ALU_OP_ADD; // funct7[5]=1 for SUB
                    3'b001: ALUOp_o = ALU_OP_SLL;
                    3'b010: ALUOp_o = ALU_OP_SLT;
                    3'b011: ALUOp_o = ALU_OP_SLTU;
                    3'b100: ALUOp_o = ALU_OP_XOR;
                    3'b101: ALUOp_o = (funct7[5]) ? ALU_OP_SRA : ALU_OP_SRL; // funct7[5]=1 for SRA
                    3'b110: ALUOp_o = ALU_OP_OR;
                    3'b111: ALUOp_o = ALU_OP_AND;
                    default: ALUOp_o = 4'bxxxx; // Undefined funct3 for R-type
                endcase
            end

            OPCODE_IMM: begin // I-type (ADDI, SLTI, ANDI, ORI, XORI, SLLI, SRLI, SRAI)
                RegWrite_o = 1'b1;
                MemToReg_o = 1'b0; // Result comes from ALU
                MemRead_o  = 1'b0;
                MemWrite_o = 1'b0;
                Branch_o   = 1'b0;
                ALUSrc_o   = 1'b1; // Use immediate for operand B
                // Determine specific ALU operation based on funct3
                case (funct3)
                    3'b000: ALUOp_o = ALU_OP_ADD;  // ADDI
                    3'b001: ALUOp_o = ALU_OP_SLL;  // SLLI (funct7 distinguishes, but shamt is in imm)
                    3'b010: ALUOp_o = ALU_OP_SLT;  // SLTI
                    3'b011: ALUOp_o = ALU_OP_SLTU; // SLTIU
                    3'b100: ALUOp_o = ALU_OP_XOR;  // XORI
                    3'b101: begin                 // SRLI / SRAI
                        if (funct7[5]) // Check funct7[5] for SRAI (bit 30 of instruction)
                            ALUOp_o = ALU_OP_SRA;
                        else
                            ALUOp_o = ALU_OP_SRL;
                    end
                    3'b110: ALUOp_o = ALU_OP_OR;   // ORI
                    3'b111: ALUOp_o = ALU_OP_AND;  // ANDI
                    default: ALUOp_o = 4'bxxxx; // Undefined funct3 for I-type immediate ops
                endcase
            end

            OPCODE_LOAD: begin // I-type (LW, LH, LB, etc.)
                RegWrite_o = 1'b1;
                MemToReg_o = 1'b1; // Result comes from Memory
                MemRead_o  = 1'b1; // Read from memory
                MemWrite_o = 1'b0;
                Branch_o   = 1'b0;
                ALUSrc_o   = 1'b1; // Use immediate for offset calculation
                ALUOp_o    = ALU_OP_ADD; // ALU calculates address (base + offset)
            end

            OPCODE_STORE: begin // S-type (SW, SH, SB)
                RegWrite_o = 1'b0; // No register write
                // MemToReg is don't care
                MemRead_o  = 1'b0;
                MemWrite_o = 1'b1; // Write to memory
                Branch_o   = 1'b0;
                ALUSrc_o   = 1'b1; // Use immediate for offset calculation
                ALUOp_o    = ALU_OP_ADD; // ALU calculates address (base + offset)
            end

            OPCODE_BRANCH: begin // B-type (BEQ, BNE, etc.)
                RegWrite_o = 1'b0; // No register write
                // MemToReg is don't care
                MemRead_o  = 1'b0;
                MemWrite_o = 1'b0;
                Branch_o   = 1'b1; // Indicate branch type
                ALUSrc_o   = 1'b0; // Use rs2 data for comparison
                // ALU performs subtraction for comparison; actual branch decision uses ALU zero flag and funct3 in EX
                ALUOp_o    = ALU_OP_SUB;
            end

            OPCODE_LUI: begin // U-type
                RegWrite_o = 1'b1;
                MemToReg_o = 1'b0; // Result effectively comes from ALU path
                MemRead_o  = 1'b0;
                MemWrite_o = 1'b0;
                Branch_o   = 1'b0;
                ALUSrc_o   = 1'b1; // Use immediate value
                ALUOp_o    = ALU_OP_COPY_SRC2; // ALU just passes immediate (shifted left by 12, handled by ImmGen)
            end

            OPCODE_AUIPC: begin // U-type
                RegWrite_o = 1'b1;
                MemToReg_o = 1'b0; // Result comes from ALU
                MemRead_o  = 1'b0;
                MemWrite_o = 1'b0;
                Branch_o   = 1'b0;
                ALUSrc_o   = 1'b1; // Use immediate value (shifted left by 12)
                // ALU adds PC + Immediate (PC needs to be routed to ALU src1)
                ALUOp_o    = ALU_OP_ADD;
            end

            OPCODE_JAL: begin // J-type
                RegWrite_o = 1'b1; // Writes PC+4 to rd
                // How PC+4 gets selected for writeback depends on detailed WB stage design.
                // Common ways: dedicated path, using MemToReg with a special value, or routing PC+4 via ALU.
                // Let's assume for this basic CU that MemToReg=0 is sufficient,
                // implying the result comes from the ALU path, and the WB stage/forwarding
                // handles selecting PC+4 when appropriate based on JAL's signature.
                // A more explicit design might add a dedicated 'JumpLink' signal.
                MemToReg_o = 1'b0; // Placeholder, assumes WB handles PC+4 selection
                MemRead_o  = 1'b0;
                MemWrite_o = 1'b0;
                Branch_o   = 1'b0; // Not a conditional branch
                ALUSrc_o   = 1'b0; // ALU not directly used for the value written back (PC+4)
                ALUOp_o    = ALU_OP_ADD; // ALU might be unused or used for target PC calc in some designs
                // Jump_o     = 1'b1;   // Set jump signal
            end

            OPCODE_JALR: begin // I-type (jump)
                RegWrite_o = 1'b1; // Writes PC+4 to rd
                MemToReg_o = 1'b0; // Placeholder, see JAL comment
                MemRead_o  = 1'b0;
                MemWrite_o = 1'b0;
                Branch_o   = 1'b0; // Not a conditional branch
                ALUSrc_o   = 1'b1; // Use immediate for target address calculation
                ALUOp_o    = ALU_OP_ADD; // ALU calculates target address (rs1 + offset)
                // Jump_o     = 1'b1;   // Set jump signal
            end

            default: begin
                // Handle unknown or unimplemented opcodes - treat as NOP
                RegWrite_o = 1'b0;
                MemToReg_o = 1'b0;
                MemRead_o  = 1'b0;
                MemWrite_o = 1'b0;
                Branch_o   = 1'b0;
                ALUSrc_o   = 1'b0;
                ALUOp_o    = 4'bxxxx; // Or a safe NOP ALU op
                // Jump_o     = 1'b0;
            end
        endcase
    end

endmodule