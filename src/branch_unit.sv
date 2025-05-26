`include "defs.vh"
`timescale 1ns / 1ps
module branch_unit (
    input logic [XLEN-1:0] rs1_data,
    input logic [XLEN-1:0] rs2_data,
    input logic [XLEN-1:0] pc_current,
    input logic [XLEN-1:0] immediate,
    input logic [2:0] branch_type,
    input logic is_jalr,

    output logic branch_taken,
    output logic [XLEN-1:0] branch_target,
    output logic [XLEN-1:0] return_code_j
);
    always_comb begin
        case (branch_type)
            3'b000: branch_taken = (rs1_data == rs2_data);  // beq
            3'b001: branch_taken = (rs1_data != rs2_data);  // bne
            3'b100: branch_taken = $signed(rs1_data) < $signed(rs2_data);  // blt
            3'b101: branch_taken = $signed(rs1_data) >= $signed(rs2_data); // bge
            3'b110: branch_taken = (rs1_data < rs2_data);  // bltu
            3'b111: branch_taken = (rs1_data >= rs2_data); // bgeu
            default: branch_taken = 0;
        endcase
    end

    always_comb begin
        if (is_jalr) begin
            branch_target = (rs1_data + immediate) & ~1;  // JALR 
        end else if (branch_taken) begin
            branch_target = pc_current + immediate; // JAL/Branch
        end
    end
    assign return_code_j = pc_current + 4;
endmodule