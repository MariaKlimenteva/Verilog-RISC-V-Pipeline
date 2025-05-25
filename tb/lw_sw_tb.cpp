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
    int check_time_1 = 4150;
    int check_time_2 = 4500;

    bool checked_1 = false;
    bool checked_2 = false;
    bool checked_3 = false; 

    while (main_time < 5000) { 
        top->eval(); 
        tfp->dump(main_time); 

        main_time++;
        top->clk = !top->clk;
        top->eval();
        tfp->dump(main_time);

        if (main_time > check_time_1 && !top->clk && !checked_1) { 
            printf("Checking after estimated time for first ADDI @ time %lu\n", main_time);
            
            check_registers(top, {
                {6, 1656},  
            }, "Check load word and store, TEST 1");
            checked_1 = true;
        }

        if (main_time > check_time_2 && !top->clk && !checked_2) {
            check_registers (top, {
                {6, 999},
                {2, 0}
            }, "Check for rewrite, TEST 2");
            checked_2 = true;
        }

        main_time++;
        top->clk = !top->clk;
        top->clk = !top->clk;
    }

    tfp->dump(main_time);
    tfp->close();
    delete tfp;
    delete top;

    return tests_failed ? 1 : 0;
}