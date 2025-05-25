`include "defs.vh"
`timescale 1ns / 1ps

module data_memory #(
    parameter DATA_WIDTH = XLEN,
    parameter ADDR_WIDTH = XLEN,
    parameter MEM_DEPTH  = 1024,
    parameter string INIT_FILE = ""
)(
    input logic clk,
    input logic rst,
    input logic we,
    input logic valid,
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] wdata,

    output logic [DATA_WIDTH-1:0] rdata
);
    logic [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    assign rdata = mem[addr[ADDR_WIDTH-1:2]];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end else begin
            foreach(mem[i]) begin
                mem[i] = '0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (we && valid) begin
            mem[addr[ADDR_WIDTH-1:2]] <= wdata;
        end
    end
endmodule