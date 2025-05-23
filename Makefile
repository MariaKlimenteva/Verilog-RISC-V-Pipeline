SRC_DIR = ./src
INCLUDE_DIR = ./include
VERILATOR_FLAGS = -Wall -I$(SRC_DIR) -I$(INCLUDE_DIR) -Wno-UNUSED -Wno-UNDRIVEN
TB_SRC = tb/addi_verilator.cpp
VERILOG_SRC =  src/*.sv

lint:
		verilator --lint-only $(VERILATOR_FLAGS) riscv_pipeline_top.sv


sim:
		verilator --Wno-fatal $(VERILATOR_FLAGS) --Wno-width -cc --trace --exe tb/addi_verilator.cpp \
		src/riscv_pipeline_top.sv src/register_file.sv \
    	include/defs.vh include/alu_opcodes.vh include/rv_opcodes.vh \
		-CFLAGS "-std=c++11" \
		--public-flat-rw

test_addi: 
		make sim
		make -C obj_dir -f Vriscv_pipeline_top.mk