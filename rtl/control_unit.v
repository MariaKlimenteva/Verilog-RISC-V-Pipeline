module control_unit #(
    parameter ALU_OP_WIDTH = 4 
) (
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,

    output reg        RegWrite_o,   
    output reg        MemToReg_o,   
    output reg        MemRead_o,    
    output reg        MemWrite_o,   
    output reg        Branch_o,     
    output reg        ALUSrc_o,     
    output reg [ALU_OP_WIDTH-1:0] ALUOp_o,
    output reg        Jump_o
);

    // RISC-V Opcodes 
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

    // Define ALU opcodes
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
    // localparam ALU_OP_COPY_SRC1 = 4'b1010; // for JAL/JALR PC+4 handling if done via ALU
    localparam ALU_OP_COPY_SRC2 = 4'b1011; // for LUI

    always @(*) begin
        RegWrite_o = 1'b0;
        MemToReg_o = 1'b0; 
        MemRead_o  = 1'b0;
        MemWrite_o = 1'b0;
        Branch_o   = 1'b0;
        ALUSrc_o   = 1'b0; 
        ALUOp_o    = ALU_OP_ADD; 
        Jump_o     = 1'b0;

        case (opcode)
            OPCODE_REG: begin // R-type: ADD/SUB/AND/OR/SLL/SRL/SRA/SLT/SLTU
                RegWrite_o = 1'b1;
                case (funct3)
                    3'b000: ALUOp_o = (funct7[5]) ? ALU_OP_SUB : ALU_OP_ADD;
                    3'b001: ALUOp_o = ALU_OP_SLL;
                    3'b010: ALUOp_o = ALU_OP_SLT;
                    3'b011: ALUOp_o = ALU_OP_SLTU;
                    3'b100: ALUOp_o = ALU_OP_XOR;
                    3'b101: ALUOp_o = (funct7[5]) ? ALU_OP_SRA : ALU_OP_SRL;
                    3'b110: ALUOp_o = ALU_OP_OR;
                    3'b111: ALUOp_o = ALU_OP_AND;
                    default: ALUOp_o = 4'bxxxx;
                endcase
            end

            OPCODE_IMM: begin // I-type
                RegWrite_o = 1'b1;
                ALUSrc_o   = 1'b1; 
                case (funct3)
                    3'b000: ALUOp_o = ALU_OP_ADD;  // ADDI
                    3'b001: ALUOp_o = ALU_OP_SLL;  // SLLI
                    3'b010: ALUOp_o = ALU_OP_SLT;  // SLTI
                    3'b011: ALUOp_o = ALU_OP_SLTU; // SLTIU
                    3'b100: ALUOp_o = ALU_OP_XOR;  // XORI
                    3'b101: begin
                        if (funct7[5])
                            ALUOp_o = ALU_OP_SRA; //SRAI
                        else
                            ALUOp_o = ALU_OP_SRL; // SRLI
                    end
                    3'b110: ALUOp_o = ALU_OP_OR;   // ORI
                    3'b111: ALUOp_o = ALU_OP_AND;  // ANDI
                    default: ALUOp_o = 4'bxxxx;
                endcase
            end

            OPCODE_LOAD: begin // I-type: LW/LH/LB/LBU/LHU
                RegWrite_o = 1'b1;
                MemToReg_o = 1'b1; 
                MemRead_o  = 1'b1; 
                ALUSrc_o   = 1'b1;
                ALUOp_o    = ALU_OP_ADD; 
            end

            OPCODE_STORE: begin // S-type: SW/SH/SB
                MemWrite_o = 1'b1; 
                ALUSrc_o   = 1'b1; 
                ALUOp_o    = ALU_OP_ADD; 
            end

            OPCODE_BRANCH: begin // B-type: BEQ/BNE/BLT/BGE/BLTU/BGEU
                Branch_o   = 1'b1; 
                ALUOp_o    = ALU_OP_SUB;
            end

            OPCODE_LUI: begin // U-type: LUI
                RegWrite_o = 1'b1;
                ALUSrc_o   = 1'b1; 
                ALUOp_o    = ALU_OP_COPY_SRC2;
            end

            OPCODE_AUIPC: begin // U-type: AUIPC
                RegWrite_o = 1'b1;
                ALUSrc_o   = 1'b1;
                ALUOp_o    = ALU_OP_ADD;
            end

            OPCODE_JAL: begin // J-type: JAL
                RegWrite_o = 1'b1; 
                Jump_o     = 1'b1; 
            end

            OPCODE_JALR: begin // I-type: JALR
                RegWrite_o = 1'b1;
                ALUSrc_o   = 1'b1;
                ALUOp_o    = ALU_OP_ADD;
                Jump_o     = 1'b1; 
            end

            default: begin
                // Handle unknown or unimplemented opcodes - treat as NOP
                RegWrite_o = 1'b0;
                MemToReg_o = 1'b0;
                MemRead_o  = 1'b0;
                MemWrite_o = 1'b0;
                Branch_o   = 1'b0;
                ALUSrc_o   = 1'b0;
                ALUOp_o    = 4'bxxxx;
                Jump_o     = 1'b0;
            end
        endcase
    end
endmodule