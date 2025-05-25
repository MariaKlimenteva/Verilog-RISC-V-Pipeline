SRC_DIR := ./src
INCLUDE_DIR := ./include
TOP_MODULE_NAME = $(SRC_DIR)/riscv_pipeline_top.sv
TB_DIR := ./tb

OBJ_DIR_BASE := obj_dir

VERILATOR_FLAGS = -Wall -I$(SRC_DIR) -I$(INCLUDE_DIR) -Wno-UNUSED -Wno-UNDRIVEN --Wno-fatal \
		--Wno-width -cc --trace --public-flat-rw -CFLAGS "-std=c++11"

VERILOG_SRCS := $(wildcard $(SRC_DIR)/*.sv $(SRC_DIR)/*.v \
        $(INCLUDE_DIR)/*.vh $(INCLUDE_DIR)/*.svh)


addi: 
		verilator  $(VERILATOR_FLAGS)  --exe $(TB_DIR)/addi_tb.cpp $(SRC_DIR)/riscv_pipeline_top.sv
		make -C $(OBJ_DIR_BASE) -f Vriscv_pipeline_top.mk 

forwarding:
		verilator  $(VERILATOR_FLAGS)  --exe $(TB_DIR)/forwarding_tb.cpp $(SRC_DIR)/riscv_pipeline_top.sv
		make -C $(OBJ_DIR_BASE) -f Vriscv_pipeline_top.mk

lw_sw:
		verilator  $(VERILATOR_FLAGS)  --exe $(TB_DIR)/lw_sw_tb.cpp $(SRC_DIR)/riscv_pipeline_top.sv
		make -C $(OBJ_DIR_BASE) -f Vriscv_pipeline_top.mk

stall_bubble_lw:
		verilator  $(VERILATOR_FLAGS)  --exe $(TB_DIR)/stall_bubble_lw_tb.cpp $(SRC_DIR)/riscv_pipeline_top.sv
		make -C $(OBJ_DIR_BASE) -f Vriscv_pipeline_top.mk