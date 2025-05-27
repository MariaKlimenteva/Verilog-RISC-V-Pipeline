#pragma once
#include <vector>
#include <string>
#include <iostream>
#include <sstream>
#include "Vriscv_pipeline_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#define COLOR_RED    "\033[31m"
#define COLOR_GREEN  "\033[32m"
#define COLOR_RESET  "\033[0m"

#define MEM_DEPTH 1024

struct RegCheck {
    int         reg_num;
    uint32_t    expected;
    std::string reg_name;
};

struct TestResult {
    const char* reg_name;
    int expected;
    int actual;
    bool passed;
};

inline void check_registers(Vriscv_pipeline_top* top, const std::vector<RegCheck>& checks, const std::string& test_name = "")
{
    if (!test_name.empty()) {
        std::cout << "\n=== Checking registers for test: " << test_name << " ===" << std::endl;
    }
    bool all_passed = true;
    for (const auto& check : checks) {
        uint32_t actual = top->riscv_pipeline_top__DOT__reg_file__DOT__registers[check.reg_num];
        
        if (actual != check.expected) {
            std::cout << COLOR_RED << "[FAIL] "
                      << check.reg_name << " (x" << check.reg_num << "): "
                      << "expected " << check.expected
                      << ", got " << actual 
                      << COLOR_RESET << std::endl;
            all_passed = false;
        } else {
            std::cout << COLOR_GREEN << "[PASS] "
                      << check.reg_name << " (x" << check.reg_num << "): "
                      << actual 
                      << COLOR_RESET << std::endl;
        }
    }

    if (all_passed) {
        std::cout << COLOR_GREEN << "All register checks passed!" << COLOR_RESET << std::endl;
    } else {
        std::cout << COLOR_RED << "Some register checks failed!" << COLOR_RESET << std::endl;
    }
}

inline void check_memory(Vriscv_pipeline_top* top, uint32_t base_reg_num, int32_t offset, uint32_t expected_value, const std::string& mem_name = "")
{
    uint32_t base_addr = top->riscv_pipeline_top__DOT__reg_file__DOT__registers[base_reg_num];

    uint32_t addr = base_addr + offset;
    // auto memory_base = top->riscv_pipeline_top__DOT__data_mem__DOT__mem[0];
    uint8_t byte_value = static_cast<uint8_t>((top->riscv_pipeline_top__DOT__data_mem__DOT__mem[0]+addr) & (uint8_t)0xFF); 

    // uint8_t byte_value = *(memory_base + addr);

    if (byte_value != expected_value) {
        std::cout << COLOR_RED << "[FAIL] "
                  << "Memory at " << base_addr << " + " << offset
                  << ": expected " << static_cast<int>(expected_value)
                  << ", got " << static_cast<int>(byte_value)
                  << COLOR_RESET << std::endl;
    } else {
        std::cout << COLOR_GREEN << "[PASS] "
                  << "Memory at " << base_addr << " + " << offset
                  << ": value " << static_cast<int>(byte_value)
                  << COLOR_RESET << std::endl;
    }
}

inline void load_hex_dynamic(Vriscv_pipeline_top* top, const std::string& filename) {
    std::ifstream file(filename);
    std::string line;
    uint32_t value;
    size_t addr = 0;

    if (!file.is_open()) {
        std::cerr << "Error: Cannot open HEX file " << filename << std::endl;
        exit(1);
    }

    while (std::getline(file, line)) {
        std::string trimmed = line;
        trimmed.erase(0, trimmed.find_first_not_of(" \t\r\n")); 
        trimmed.erase(trimmed.find_last_not_of(" \t\r\n") + 1); 

        if (trimmed.empty() || trimmed[0] == '#' || trimmed[0] == '/' || trimmed[0] == ';') {
            continue; 
        }

        std::istringstream iss(trimmed);
        if (iss >> std::hex >> value) {
            if (addr >= MEM_DEPTH) break;
            top->riscv_pipeline_top__DOT__i_mem__DOT__mem[addr] = value;
            addr++;
        } else {
            std::cerr << "Warning: Invalid line in HEX file: " << line << std::endl;
        }
    }

    std::cout << "Loaded " << addr << " instructions from " << filename << std::endl;
}