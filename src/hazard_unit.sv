`timescale 1ns / 1ps
module hazard_unit (
    input [4:0] id_ex_rs1_addr,
    input [4:0] id_ex_rs2_addr, 
    input [4:0] ex_rd_addr,
    input [4:0] id_rs1_addr,
    input [4:0] id_rs2_addr,    
    input [4:0] ex_mem_rd_addr,      
    input [4:0] mem_wb_rd_addr,

    input ex_mem_regwrite,
    input mem_read,     
    input mem_wb_regwrite, 
    input PCSrcE,  
    
    output logic [1:0] forward_a,
    output logic [1:0] forward_b,
    output logic stallD,
    output logic flushE,
    output logic flushD
);
    logic stall_lw;

    assign stall_lw = mem_read && ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr));
    assign stallD = stall_lw;
    assign flushE = stall_lw | PCSrcE;
    assign flushD = PCSrcE;

    always_comb begin
        forward_a = 2'b00;
        forward_b = 2'b00;
        if (ex_mem_regwrite && (ex_mem_rd_addr != 5'b00000) && (ex_mem_rd_addr == id_ex_rs1_addr)) begin
            forward_a = 2'b10;
        end
        else if (mem_wb_regwrite && (mem_wb_rd_addr != 5'b00000) && (mem_wb_rd_addr == id_ex_rs1_addr)) begin
            forward_a = 2'b01;
        end
        
        if (ex_mem_regwrite && (ex_mem_rd_addr != 5'b00000) && (ex_mem_rd_addr == id_ex_rs2_addr)) begin
            forward_b = 2'b10;
        end
        else if (mem_wb_regwrite && (mem_wb_rd_addr != 5'b00000) && (mem_wb_rd_addr == id_ex_rs2_addr)) begin
            forward_b = 2'b01;
        end
    end
endmodule