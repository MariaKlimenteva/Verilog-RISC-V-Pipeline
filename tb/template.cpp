#include <fstream>
#include <vector>
#include "rv_utils.h"

struct TestCase {
    std::string name;
    int check_time;
    std::vector<RegCheck> checks;
};

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <hex_file> [test_config]\n";
        return 1;
    }

    // Инициализация симуляции
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Vriscv_pipeline_top* top = new Vriscv_pipeline_top;
    load_hex_dynamic(top, argv[1]);

    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("wave.vcd");

    // Определение тестов (можно загружать из файла)
    std::vector<TestCase> test_cases = {
        {
            "First ADDI test",
            50,
            {
                {1, 5, "x1"},
                {2, 10, "x2"},
                {3, (uint32_t)-1, "x3"}
            }
        },
        {
            "Second ADDI Test",
            60,
            {
                {3, 10, "x3_after_second_addi"}
            }
        },
        {
            "Test 3",
            100,
            {
                {3, 15, "x3 = x2 + x1"}
            }
        }
    };

    // Сброс процессора
    top->clk = 0;
    top->rst = 1;
    vluint64_t main_time = 0;

    for (int i = 0; i < 10; ++i) {
        top->eval();
        tfp->dump(main_time++);
        top->clk = !top->clk;
        top->eval();
        tfp->dump(main_time++);
        top->clk = !top->clk;
    }
    top->rst = 0;

    printf("Reset finished. Starting execution...\n");

    // Статистика тестов
    std::vector<TestResult> all_test_results;
    int tests_passed = 0;
    int tests_failed = 0;

    // Выполнение тестов
    for (const auto& test_case : test_cases) {
        bool stage_checked = false;

        while (!stage_checked && main_time < 5000) {
            // Тактирование
            top->clk = !top->clk;
            top->eval();
            tfp->dump(main_time++);

            // Проверка условия для теста
            if (main_time > test_case.check_time && !top->clk && !stage_checked) {
                printf("\nChecking after estimated time for '%s' @ time %llu\n",
                      test_case.name.c_str(), main_time);

                // Используем вашу функцию check_registers
                std::vector<TestResult> results;
                for (const auto& check : test_case.checks) {
                    uint32_t actual = top->riscv_pipeline_top__DOT__reg_file__DOT__registers[check.reg_num];
                    bool passed = (actual == check.expected);
                    results.push_back({check.reg_name.c_str(), (int)check.expected, (int)actual, passed});

                    if (passed) tests_passed++;
                    else tests_failed++;
                }

                // Красивый вывод результатов
                for (const auto& res : results) {
                    std::cout << (res.passed ? COLOR_GREEN : COLOR_RED) << "["
                              << (res.passed ? "PASS" : "FAIL") << "] "
                              << res.reg_name << ": expected " << res.expected
                              << ", got " << res.actual << COLOR_RESET << std::endl;
                }

                if (results.size() > 1) {
                    bool all_passed = std::all_of(results.begin(), results.end(),
                        [](const TestResult& r) { return r.passed; });
                    std::cout << (all_passed ? COLOR_GREEN : COLOR_RED)
                              << (all_passed ? "All register checks passed!" : "Some register checks failed!")
                              << COLOR_RESET << std::endl;
                }

                stage_checked = true;
                all_test_results.insert(all_test_results.end(), results.begin(), results.end());
            }

            top->clk = !top->clk;
            top->eval();
            tfp->dump(main_time++);
        }
    }

    // Завершение работы
    tfp->dump(main_time);
    tfp->close();
    delete tfp;
    delete top;

    // Итоговый отчёт
    std::cout << "\n=== Test Summary ===" << std::endl;
    std::cout << "Total checks: " << (tests_passed + tests_failed) << std::endl;
    std::cout << "Passed: " << COLOR_GREEN << tests_passed << COLOR_RESET << std::endl;
    std::cout << "Failed: " << (tests_failed ? COLOR_RED : COLOR_GREEN) 
              << tests_failed << COLOR_RESET << std::endl;

    return tests_failed ? 1 : 0;
}