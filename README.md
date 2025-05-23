# Verilog-RISC-V-Pipeline

3. hazards forwarding
4. branches, jal/jalr, load/store - datamemory?


## First stage of development
Addi and add work (I and R - type instructions) (addi_program.hex)

### How to run:
```
./run_verilator.sh
```
It uses NOPs to avoid conflicts because I don't have hazard unit yet.

## Second stage: DMem module
uses for instructions that work with memory - load & store

## Third stage: hazard unit
1. Data hazards : forwarding
2. Control hazards : branches, jumps


