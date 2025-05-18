#include <fstream>
#include "rv_utils.h"

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <hex_file>\n";
        return 1;
    }
    const char* hex_file = argv[1];

    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); 

    Vriscv_pipeline_top* top = new Vriscv_pipeline_top;
    load_hex_dynamic(top, hex_file);

    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("wave.vcd"); 
    
    std::vector<TestResult> test_results;
    int tests_passed = 0;
    int tests_failed = 0;

    top->clk = 0;
    top->rst = 1; 
    vluint64_t main_time = 0;

    for (int i = 0; i < 10; ++i) {
        top->eval(); 
        tfp->dump(main_time); 
        main_time++;
        top->clk = !top->clk; 
        top->eval();
        tfp->dump(main_time);
        main_time++;
        top->clk = !top->clk;
    }
    top->rst = 0; 

    printf("Reset finished. Starting execution...\n");

    while (main_time < 100) { 
        top->eval(); 
        tfp->dump(main_time); 

        main_time++;
        top->clk = !top->clk;
        top->eval();
        tfp->dump(main_time);

        if (main_time > 30 && !top->clk && main_time < 40) { 
            check_registers(top, {
                {1, 5,   "x1"},
                {2, 10,   "x2"},
                {3, (uint32_t)-1, "x3"}
            }, "ADDI test");
        }

        main_time++;
        top->clk = !top->clk;
        top->eval();
        top->clk = !top->clk;
    }

    tfp->dump(main_time);
    tfp->close();
    delete tfp;
    delete top;

    return tests_failed ? 1 : 0;
}