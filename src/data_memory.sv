`include "defs.vh"
`timescale 1ns / 1ps

module data_memory #(
    parameter DATA_WIDTH = XLEN,
    parameter ADDR_WIDTH = XLEN,
    parameter MEM_DEPTH  = 1024
)(
    input logic clk,
    input logic rst,
    input logic we,
    input logic valid,
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] wdata,
    input logic [3:0] byte_enable,

    output logic [DATA_WIDTH-1:0] rdata
);
    logic [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    localparam BYTE = 8;

    assign rdata = mem[addr[ADDR_WIDTH-1:2]];

    initial begin
        foreach(mem[i]) begin
            mem[i] = '0;
        end
    end

    always_ff @(negedge clk) begin
        if (we && valid) begin
            for (int i = 0; i < DATA_WIDTH/BYTE; i++) begin
                if (byte_enable[i]) begin
                    mem[addr[ADDR_WIDTH-1:2]][BYTE*i +: BYTE] <= wdata[BYTE*i +: BYTE];
                end
            end
        end
    end
endmodule