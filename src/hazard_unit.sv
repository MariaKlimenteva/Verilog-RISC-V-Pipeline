`timescale 1ns / 1ps
module hazard_unit (
    input [4:0] id_rs1_addr,
    input [4:0] id_rs2_addr,     
    input [4:0] ex_rd_addr,      
    input       ex_regwrite,     
    input [4:0] mem_rd_addr,     
    input       mem_regwrite,    
    
    output      hu_ex_rs1,       
    output      hu_mem_rs1,      
    output      hu_ex_rs2,       
    output      hu_mem_rs2
);

    assign hu_ex_rs1  = (id_rs1_addr != 0) && ex_regwrite && (ex_rd_addr == id_rs1_addr);
    assign hu_mem_rs1 = (id_rs1_addr != 0) && mem_regwrite && (mem_rd_addr == id_rs1_addr) && !hu_ex_rs1;

    assign hu_ex_rs2  = (id_rs2_addr != 0) && ex_regwrite && (ex_rd_addr == id_rs2_addr);
    assign hu_mem_rs2 = (id_rs2_addr != 0) && mem_regwrite && (mem_rd_addr == id_rs2_addr) && !hu_ex_rs2;

endmodule