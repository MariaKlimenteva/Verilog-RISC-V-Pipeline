# Verilog-RISC-V-Pipeline

## Simple instructions
Addi and add work (I and R - type instructions) (addi_program.hex)

### How to run:
```
./run_verilator.sh addi
```
It uses NOPs to avoid conflicts because I don't have hazard unit yet.

## RAW conflicts for simple instructions (addi, add, sub, etc.)
hazard unit simple logic: forwarding

## DMem module
Uses for instructions that work with memory - load & store

## Conflicts with lw, sw
Stall + bubble

## Jump and branches development
Branch module to calculate when branch should be taken

## Control conflicts with BEQ
Stall + bubble

### How to run all tests
```
./run_verilator.sh
```