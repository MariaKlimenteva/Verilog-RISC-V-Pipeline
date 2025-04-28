#!/bin/bash

RTL_DIR="rtl"       # Папка с исходниками RTL
TB_DIR="tb"         # Папка с тестбенчами
OUTPUT_DIR="output" # Папка для результатов компиляции и симуляции
IVERILOG_FLAGS="-g2012" # Флаги для iverilog 

COLOR_BLUE='\033[0;34m'
COLOR_GREEN='\033[0;32m'
COLOR_RED_BOLD='\033[1;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

shopt -s nullglob
test_count=0
fail_count=0

for testbench_file in "$TB_DIR"/*.v; do
    test_count=$((test_count + 1))
    echo -e "${COLOR_YELLOW}--> Running test: $testbench_file${COLOR_NC}\n"

    test_name=$(basename "$testbench_file" .v)
    sim_output_file="$OUTPUT_DIR/${test_name}_sim"

    if iverilog -o "$sim_output_file" "$RTL_DIR"/*.v "$testbench_file" $IVERILOG_FLAGS; then
        if vvp "$sim_output_file"; then
            echo -e "${COLOR_GREEN}Simulation OK.${COLOR_NC}"
        else
            echo -e "${COLOR_RED_BOLD}!!! ERROR: Simulation FAILED for $test_name.${COLOR_NC}\n"
            fail_count=$((fail_count + 1))
        fi
    else
        echo -e "${COLOR_RED_BOLD}!!! ERROR: Compilation FAILED for $test_name.c"
        fail_count=$((fail_count + 1))
    fi
done

shopt -u nullglob

if [ $test_count -eq 0 ]; then
    echo "Warning: No testbenches (.v files) found in $TB_DIR/"
else
    echo -e "${COLOR_YELLOW}Tests completed: $test_count${COLOR_NC}\n"
    if [ $fail_count -eq 0 ]; then
        echo -e "${COLOR_YELLOW}All tests passed!${COLOR_NC}\n"
    else
        echo "Number of failed tests: $fail_count"
        exit 1
    fi
fi
exit 0