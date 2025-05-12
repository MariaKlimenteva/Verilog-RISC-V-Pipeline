RTL_DIR = ./rtl
VERILATOR_FLAGS = -Wall -I$(RTL_DIR) -Wno-UNUSED -Wno-UNDRIVEN
TB_SRC = tb/addi_verilator.cpp
VERILOG_SRC =  rtl/*.sv

lint:
		verilator --lint-only $(VERILATOR_FLAGS) riscv_pipeline_top.sv


sim:
		verilator --Wno-fatal $(VERILATOR_FLAGS) --Wno-width -cc --trace --exe tb/addi_verilator.cpp \
		rtl/riscv_pipeline_top.sv rtl/register_file.sv \
    	rtl/defs.vh rtl/alu_opcodes.vh rtl/rv_opcodes.vh \
		-CFLAGS "-std=c++11" \
		--public-flat-rw

test_addi: 
		make sim
		make -C obj_dir -f Vriscv_pipeline_top.mk