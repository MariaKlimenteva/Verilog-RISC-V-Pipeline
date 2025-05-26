`include "defs.vh"
`include "alu_opcodes.vh"
`include "rv_opcodes.vh"
`timescale 1ns / 1ps
module control_unit #() (
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    output control_signals control_out_s
);
    always_comb begin
        control_out_s = '{default: '0};
        case (opcode)
            `OPCODE_REG: begin // R-type: ADD/SUB/AND/OR/SLL/SRL/SRA/SLT/SLTU
                control_out_s.RegWrite = 1'b1;
                case (funct3)
                    3'b000: control_out_s.ALUOp = (funct7[5]) ? `ALU_OP_SUB : `ALU_OP_ADD;
                    3'b001: control_out_s.ALUOp = `ALU_OP_SLL;
                    3'b010: control_out_s.ALUOp = `ALU_OP_SLT;
                    3'b011: control_out_s.ALUOp = `ALU_OP_SLTU;
                    3'b100: control_out_s.ALUOp = `ALU_OP_XOR;
                    3'b101: control_out_s.ALUOp = (funct7[5]) ? `ALU_OP_SRA : `ALU_OP_SRL;
                    3'b110: control_out_s.ALUOp = `ALU_OP_OR;
                    3'b111: control_out_s.ALUOp = `ALU_OP_AND;
                    default: control_out_s.ALUOp = 4'bxxxx;
                endcase
            end

            `OPCODE_IMM: begin // I-type
                control_out_s.RegWrite = 1'b1;
                control_out_s.ALUSrc = 1'b1; 
                case (funct3)
                    3'b000: control_out_s.ALUOp = `ALU_OP_ADD;  // ADDI
                    3'b001: control_out_s.ALUOp = `ALU_OP_SLL;  // SLLI
                    3'b010: control_out_s.ALUOp = `ALU_OP_SLT;  // SLTI
                    3'b011: control_out_s.ALUOp = `ALU_OP_SLTU; // SLTIU
                    3'b100: control_out_s.ALUOp = `ALU_OP_XOR;  // XORI
                    3'b101: begin
                        if (funct7[5])
                            control_out_s.ALUOp = `ALU_OP_SRA; //SRAI
                        else
                            control_out_s.ALUOp = `ALU_OP_SRL; // SRLI
                    end
                    3'b110: control_out_s.ALUOp = `ALU_OP_OR;   // ORI
                    3'b111: control_out_s.ALUOp = `ALU_OP_AND;  // ANDI
                    default: control_out_s.ALUOp = 4'bxxxx;
                endcase
            end

            `OPCODE_LOAD: begin // I-type: LW/LH/LB/LBU/LHU
                control_out_s.RegWrite = 1'b1;
                control_out_s.MemToReg = 1'b1; 
                control_out_s.MemRead = 1'b1; 
                control_out_s.ALUSrc  = 1'b1;
                control_out_s.ALUOp   = `ALU_OP_ADD; 
            end

            `OPCODE_STORE: begin // S-type: SW/SH/SB
                control_out_s.MemWrite = 1'b1; 
                control_out_s.ALUSrc = 1'b1; 
                control_out_s.ALUOp = `ALU_OP_ADD; 
            end

            `OPCODE_BRANCH: begin // B-type: BEQ/BNE/BLT/BGE/BLTU/BGEU
                control_out_s.Branch = 1'b1; 
                case (funct3)
                    3'b000: control_out_s.BranchType = 3'b000; // BEQ
                    3'b001: control_out_s.BranchType = 3'b001; // BNE
                    3'b100: control_out_s.BranchType = 3'b100; // BLT
                    3'b101: control_out_s.BranchType = 3'b101; // BGE
                    3'b110: control_out_s.BranchType = 3'b110; // BLTU
                    3'b111: control_out_s.BranchType = 3'b111; // BGEU
                    default: control_out_s.BranchType = 3'b000;
                endcase
            end

            `OPCODE_LUI: begin // U-type: LUI
                control_out_s.RegWrite = 1'b1;
                control_out_s.ALUSrc = 1'b1; 
                control_out_s.ALUOp = `ALU_OP_COPY_SRC2;
            end

            `OPCODE_AUIPC: begin // U-type: AUIPC
                control_out_s.RegWrite = 1'b1;
                control_out_s.ALUSrc = 1'b1;
                control_out_s.ALUOp = `ALU_OP_ADD;
            end

            `OPCODE_JAL: begin // J-type: JAL
                control_out_s.RegWrite = 1'b1; 
                control_out_s.Jump = 1'b1; 
            end

            `OPCODE_JALR: begin // I-type: JALR
                control_out_s.RegWrite = 1'b1;
                control_out_s.Jump = 1'b1; 
                control_out_s.Jalr = 1'b1;
            end

            default: begin
                control_out_s.ALUOp = `ALU_OP_X;
            end
        endcase
    end
endmodule