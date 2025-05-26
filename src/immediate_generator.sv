`timescale 1ns / 1ps
`include "rv_opcodes.vh"
module immediate_generator #() (
    input wire [31:0] instr,
    output reg [XLEN-1:0] immediate
);
    always @(*) begin
        immediate = {XLEN{1'b0}}; 
        case (instr[6:0]) 
            `OPCODE_LOAD, `OPCODE_IMM, `OPCODE_JALR: begin // I-type immediate
                immediate = {{(XLEN-12){instr[31]}}, instr[31:20]};
            end

            `OPCODE_STORE: begin // S-type immediate
                immediate = {{(XLEN-12){instr[31]}}, instr[31:25], instr[11:7]};
            end

            `OPCODE_BRANCH: begin // B-type immediate
                immediate = {{(XLEN-13){instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end

            `OPCODE_LUI, `OPCODE_AUIPC: begin // U-type immediate
                immediate = {instr[31:12], 12'b0};
            end

            `OPCODE_JAL: begin // J-type immediate
                immediate = {{(XLEN-21){instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end
            default: immediate = {XLEN{1'b0}};
        endcase
    end
endmodule