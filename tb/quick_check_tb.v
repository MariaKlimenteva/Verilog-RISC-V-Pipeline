`timescale 1ns / 1ps
module quick_check_tb;

    localparam XLEN           = 32;
    localparam MEM_DEPTH      = 128; 
    localparam IMEM_INIT_FILE = "full_instr_test.hex";
    localparam CLK_PERIOD     = 10;
    localparam SIM_CYCLES     = 80; 

    reg clk;
    reg rst;

    riscv_pipeline_top #(
        .XLEN(XLEN), .MEM_DEPTH(MEM_DEPTH),
        .IMEM_INIT_FILE(IMEM_INIT_FILE)
    ) dut ( .clk(clk), .rst(rst) );

    initial begin clk = 0; forever #(CLK_PERIOD/2) clk = ~clk; end

    initial begin
        $dumpfile("output/quick_check_waves.vcd");
        $dumpvars(0, dut);
        rst = 1; #(CLK_PERIOD * 2); rst = 0;
        #(CLK_PERIOD * SIM_CYCLES);

        $display("--- Verification Checks ---");
        check_reg(1, 32'd10);         // ADDI
        check_reg(2, 32'd20);         // ADDI
        check_reg(3, 32'd100);        // ADDI
        check_reg(5, 32'd30);         // ADD
        check_reg(6, 32'd10);         // SUB
        check_reg(7, 32'hA);          // ANDI
        check_reg(8, 32'd0);          // SLTI
        check_reg(9, 32'hABC00000);   // LUI
        // Проверки для LW/SW и JAL/JALR опущены для краткости,
        // т.к. требуют DMem и анализа PC+4 в VCD/более сложного тестбенча.
        $display("--- Quick Check Finished ---");
        $finish;
    end

    task check_reg (input [4:0] addr, input [XLEN-1:0] expected_value);
        #1;
        if (dut.reg_file.registers[addr] === expected_value)
            $display("\033[32mPASS: x%0d = %h (Expected %h)\033[0m", addr, dut.reg_file.registers[addr], expected_value);
        else
            $display("\033[1;31mFAIL: x%0d = %h (Expected %h)\033[0m", addr, dut.reg_file.registers[addr], expected_value);
    endtask

endmodule