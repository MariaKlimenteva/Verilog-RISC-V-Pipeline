SRC_DIR := ./src
INCLUDE_DIR := ./include
TOP_MODULE := $(SRC_DIR)/riscv_pipeline_top.sv

VERILATOR_FLAGS = -Wall -I$(SRC_DIR) -I$(INCLUDE_DIR) -Wno-UNUSED -Wno-UNDRIVEN --Wno-fatal \
		--Wno-width -cc --trace -CFLAGS "-std=c++11" --public-flat-rw
TB_SRC = tb/addi_verilator.cpp

VERILOG_SRCS := $(wildcard $(SRC_DIR)/*.sv $(SRC_DIR)/*.v \
                          $(INCLUDE_DIR)/*.vh $(INCLUDE_DIR)/*.svh)

sim: 
		verilator  $(VERILATOR_FLAGS)  --exe $(TB_SRC) $(TOP_MODULE)  

test_addi: 
		make sim
		make -C obj_dir -f Vriscv_pipeline_top.mk