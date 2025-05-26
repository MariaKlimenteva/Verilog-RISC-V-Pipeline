`timescale 1ns / 1ps
module hazard_unit (
    input id_ex_data ex_data,
    input if_id_data decode_data,
    input ex_mem_data mem_data,
    input mem_wb_data wb_data,
    input PCSrcE,  
    
    output logic [1:0] forward_a,
    output logic [1:0] forward_b,
    output logic stallD,
    output logic flushE,
    output logic flushD
);
    logic stall_lw;

    assign stall_lw = ex_data.control.MemRead && ((ex_data.rd_addr == decode_data.instruction[19:15]) 
                        || (ex_data.rd_addr == decode_data.instruction[24:20]));
    assign stallD = stall_lw;
    assign flushE = stall_lw | PCSrcE;
    assign flushD = PCSrcE;

    always_comb begin
        forward_a = 2'b00;
        forward_b = 2'b00;
        if (mem_data.control.RegWrite && (mem_data.rd_addr != 5'b00000) && 
                (mem_data.rd_addr == ex_data.rs1_addr)) begin
            forward_a = 2'b10;
        end
        else if (wb_data.control.RegWrite && (wb_data.rd_addr != 5'b00000) &&
                (wb_data.rd_addr == ex_data.rs1_addr)) begin
            forward_a = 2'b01;
        end
        
        if (mem_data.control.RegWrite && (mem_data.rd_addr != 5'b00000) && 
                (mem_data.rd_addr == ex_data.rs2_addr)) begin
            forward_b = 2'b10;
        end
        else if (wb_data.control.RegWrite && (wb_data.rd_addr != 5'b00000) && 
                (wb_data.rd_addr == ex_data.rs2_addr)) begin
            forward_b = 2'b01;
        end
    end
endmodule