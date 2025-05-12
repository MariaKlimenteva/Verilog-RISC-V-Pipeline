#include "Vriscv_pipeline_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <fstream>
#include <iostream>
#include <vector>

#define COLOR_RED     "\033[31m"
#define COLOR_GREEN   "\033[32m"
#define COLOR_RESET   "\033[0m"


int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); 

    Vriscv_pipeline_top* top = new Vriscv_pipeline_top;

    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("wave.vcd"); 

    struct TestResult {
        const char* reg_name;
        int expected;
        int actual;
        bool passed;
    };
    
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

        if (main_time > 30 && !top->clk) { 
            printf("Time %lu: Checking registers...\n", main_time/2);

            test_results.push_back({
                "x1", 5, 
                top->riscv_pipeline_top__DOT__reg_file__DOT__registers[1],
                top->riscv_pipeline_top__DOT__reg_file__DOT__registers[1] == 5
            });

            test_results.push_back({
                "x2", 10, 
                top->riscv_pipeline_top__DOT__reg_file__DOT__registers[2],
                top->riscv_pipeline_top__DOT__reg_file__DOT__registers[2] == 10
            });

            test_results.push_back({
                "x3", -1, 
                top->riscv_pipeline_top__DOT__reg_file__DOT__registers[3],
                top->riscv_pipeline_top__DOT__reg_file__DOT__registers[3] == -1
            });

            // if (main_time > 40) { 
            //     printf("Finished checks. Exiting simulation.\n");
            //     break;
            // }
        }

        main_time++;
        top->clk = !top->clk;
        tfp->dump(main_time);

        top->eval();
        main_time++;
        tfp->dump(main_time);
        top->clk = !top->clk;
    }

    printf("\n=== TEST SUMMARY ===\n");
    for (const auto& result : test_results) {
        if (result.passed) {
            tests_passed++;
            printf("[%sPASS%s] %s: expected %d, got %d\n", 
                   COLOR_GREEN, COLOR_RESET, 
                   result.reg_name, result.expected, result.actual);
        } else {
            tests_failed++;
            printf("[%sFAIL%s] %s: expected %d, got %d\n", 
                   COLOR_RED, COLOR_RESET, 
                   result.reg_name, result.expected, result.actual);
        }
    }

    printf("\nTotal tests: %d\n", tests_passed + tests_failed);
    printf("%sPassed: %d%s\n", COLOR_GREEN, tests_passed, COLOR_RESET);
    printf("%sFailed: %d%s\n", COLOR_RED, tests_failed, COLOR_RESET);
    
    if (tests_failed == 0) {
        printf("%sALL TESTS PASSED!%s\n", COLOR_GREEN, COLOR_RESET);
    } else {
        printf("%sSOME TESTS FAILED!%s\n", COLOR_RED, COLOR_RESET);
    }

    tfp->dump(main_time);
    tfp->close();
    delete tfp;
    delete top;

    return tests_failed ? 1 : 0;
}