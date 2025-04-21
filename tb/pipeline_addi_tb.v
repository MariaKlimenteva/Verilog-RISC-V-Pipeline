`timescale 1ns / 1ps

module pipeline_addi_tb;

    // --- Parameters ---
    // Match the parameters of the top module being tested
    localparam XLEN         = 32;
    localparam ALU_OP_WIDTH = 4;
    localparam MEM_DEPTH    = 1024;
    localparam IMEM_INIT_FILE = "addi_program.hex"; // Specific hex file for this test
    localparam DMEM_INIT_FILE = "";
    localparam RESET_VECTOR = 32'h00000000;
    localparam CLK_PERIOD   = 10; // Clock period in timescale units (e.g., 10 ns)

    // --- Testbench Signals ---
    reg clk;
    reg rst;

    // Wires to connect to DUT outputs for monitoring (optional)
    // wire [XLEN-1:0] debug_pc;
    // wire [XLEN-1:0] debug_wb_data;
    // wire [4:0]      debug_wb_addr;
    // wire            debug_wb_wen;

    // --- Instantiate the Design Under Test (DUT) ---
    riscv_pipeline_top #(
        .XLEN(XLEN),
        .ALU_OP_WIDTH(ALU_OP_WIDTH),
        .MEM_DEPTH(MEM_DEPTH),
        .IMEM_INIT_FILE(IMEM_INIT_FILE), // Use the specific hex file
        .DMEM_INIT_FILE(DMEM_INIT_FILE),
        .RESET_VECTOR(RESET_VECTOR)
    ) dut (
        .clk(clk),
        .rst(rst)
        // Connect debug outputs if defined in DUT
        // .debug_pc(debug_pc),
        // .debug_wb_data(debug_wb_data),
        // .debug_wb_addr(debug_wb_addr),
        // .debug_wb_wen(debug_wb_wen)
    );

    // --- Clock Generation ---
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk; // Generate clock with 50% duty cycle
    end

    // --- Test Sequence ---
    initial begin
        $display("--------------------------------------------------");
        $display("Starting ADDI Testbench");
        $display("Test Program: %s", IMEM_INIT_FILE);
        $display("--------------------------------------------------");

        // --- Setup Waveform Dumping (VCD) ---
        // Make sure the 'output' directory exists or specify a full path
        $dumpfile("output/pipeline_addi_waves.vcd");
        // Dump all signals within the DUT instance
        $dumpvars(0, dut);

        // --- Reset Sequence ---
        rst = 1'b1; // Assert reset
        #(CLK_PERIOD * 2); // Hold reset for a couple of clock cycles
        rst = 1'b0; // Deassert reset
        $display("T=%0t: Reset released.", $time);

        // --- Run Simulation ---
        // Instructions take 5 stages to complete.
        // Let's run enough cycles for 3 instructions to complete writeback.
        // Instruction 1 WB at end of cycle 5
        // Instruction 2 WB at end of cycle 6
        // Instruction 3 WB at end of cycle 7
        // Add a few extra cycles for observation.
        #(CLK_PERIOD * 10);

        // --- Verification (Check Register File Content) ---
        // We need access to the register file inside the DUT to check values.
        // The easiest way for simulation is to use hierarchical names.
        // Check the expected values based on addi_program.hex
        $display("--------------------------------------------------");
        $display("Verification Checks at T=%0t:", $time);

        // Check x1 (expected: 5 from ADDI x1, x0, 5)
        if (dut.reg_file.registers[1] === 32'd5) begin
            $display("PASS: Register x1 = %d (Expected 5)", dut.reg_file.registers[1]);
        end else begin
            $display("FAIL: Register x1 = %d (Expected 5)", dut.reg_file.registers[1]);
        end

        // Check x2 (expected: 10 from ADDI x2, x0, 10)
        if (dut.reg_file.registers[2] === 32'd10) begin
            $display("PASS: Register x2 = %d (Expected 10)", dut.reg_file.registers[2]);
        end else begin
            $display("FAIL: Register x2 = %d (Expected 10)", dut.reg_file.registers[2]);
        end

        // Check x3 (expected: -1 = 0xFFFFFFFF from ADDI x3, x0, -1)
        if (dut.reg_file.registers[3] === 32'hFFFFFFFF) begin
            $display("PASS: Register x3 = %h (Expected FFFFFFFF)", dut.reg_file.registers[3]);
        end else begin
            $display("FAIL: Register x3 = %h (Expected FFFFFFFF)", dut.reg_file.registers[3]);
        end
        $display("--------------------------------------------------");


        // --- Finish Simulation ---
        $display("Simulation Finished at T=%0t", $time);
        $finish;
    end

    // Optional: Monitor key signals during simulation
    /* initial begin
        $monitor("T=%0t PC=%h Instr=%h | WB_Addr=%d WB_Data=%h WB_WE=%b",
                 $time, dut.pc_out, dut.if_instruction, // Signals available earlier
                 dut.wb_rd_addr, dut.wb_write_data, dut.wb_regwrite // Signals from WB stage
                );
    end */

endmodule