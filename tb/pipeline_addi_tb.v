`timescale 1ns / 1ps

module pipeline_addi_tb;
    localparam XLEN         = 32;
    localparam ALU_OP_WIDTH = 4;
    localparam MEM_DEPTH    = 1024;
    localparam IMEM_INIT_FILE = "addi_program.hex"; 
    localparam DMEM_INIT_FILE = "";
    localparam RESET_VECTOR = 32'h00000000;
    localparam CLK_PERIOD   = 10; 

    reg clk;
    reg rst;

    riscv_pipeline_top #(
        .XLEN(XLEN),
        .ALU_OP_WIDTH(ALU_OP_WIDTH),
        .MEM_DEPTH(MEM_DEPTH),
        .IMEM_INIT_FILE(IMEM_INIT_FILE), 
        .DMEM_INIT_FILE(DMEM_INIT_FILE),
        .RESET_VECTOR(RESET_VECTOR)
    ) dut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk; 
    end

    initial begin
        $dumpfile("output/pipeline_addi_waves.vcd");
        $dumpvars(0, dut);

        rst = 1'b1; 
        #(CLK_PERIOD * 2); 
        rst = 1'b0; 
        #(CLK_PERIOD * 10);

        if (dut.reg_file.registers[1] === 32'd5) begin
            $display("%sPASS: Register x1 = %d (Expected 5)%s",
            "\033[32m",
            dut.reg_file.registers[1], "\033[0m");
        end else begin
            $display("%sFAIL: Register x1 = %d (Expected 5)%s", 
            "\033[1;31m",
            dut.reg_file.registers[1], "\033[0m");
        end

        if (dut.reg_file.registers[2] === 32'd10) begin
            $display("%sPASS: Register x2 = %d (Expected 10)%s", 
            "\033[32m", 
            dut.reg_file.registers[2], "\033[0m");
        end else begin
            $display("%sFAIL: Register x2 = %d (Expected 10)%s", 
            "\033[1;31m",
            dut.reg_file.registers[2], "\033[0m");
        end

        if (dut.reg_file.registers[3] === 32'hFFFFFFFF) begin
            $display("%sPASS: Register x3 = %h (Expected FFFFFFFF)%s", 
            "\033[32m",
            dut.reg_file.registers[3], "\033[0m");
        end else begin
            $display("%sFAIL: Register x3 = %h (Expected FFFFFFFF)%s", 
            "\033[1;31m",
            dut.reg_file.registers[3], "\033[0m");
        end
        $finish;
    end
endmodule