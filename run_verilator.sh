#!/bin/bash

TEST_NAME=$1

ALL_TESTS=("addi" "forwarding" "lw_sw" "stall_bubble_lw" "branch_jump" "load_store_byte")

if [ -z "$1" ]; then
  echo "Run all tests..."
  for TEST in "${ALL_TESTS[@]}"; do
    echo "Run test: $TEST"
    make $TEST
    obj_dir/Vriscv_pipeline_top hex/$TEST.hex
  done
else
  TEST_NAME=$1
  echo "Run test: $TEST_NAME"
  make $TEST_NAME
  obj_dir/Vriscv_pipeline_top hex/$TEST_NAME.hex
fi