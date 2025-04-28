`timescale 1ns / 1ps

module riscv_pipeline_top #(
    parameter XLEN         = 32,
    parameter ALU_OP_WIDTH = 4,
    parameter MEM_DEPTH    = 1024,
    parameter IMEM_INIT_FILE = "program.hex", 
    parameter DMEM_INIT_FILE = "", 
    parameter RESET_VECTOR = 32'h00000000
) (
    input wire clk,
    input wire rst 
);
    // IF Stage
    wire [XLEN-1:0] pc_out;
    wire [XLEN-1:0] if_pc_plus_4;
    wire            if_pc_write_enable = 1'b1;
    wire [XLEN-1:0] if_next_pc_select_in = {XLEN{1'b0}};
    wire [XLEN-1:0] if_instruction;

    // IF/ID Register Outputs
    wire [XLEN-1:0] id_instruction;
    wire [XLEN-1:0] id_pc_plus_4;

    // ID Stage
    wire id_ex_regwrite;
    wire id_ex_memtoreg;
    wire id_ex_memread;
    wire id_ex_memwrite;
    wire id_ex_branch;
    wire id_ex_alusrc;
    wire [ALU_OP_WIDTH-1:0] id_ex_aluop;
    // RegFile outputs
    wire [XLEN-1:0] id_rs1_data;
    wire [XLEN-1:0] id_rs2_data;
    // ImmGen output
    wire [XLEN-1:0] id_immediate;
    // Register addresses (from id_instruction)
    wire [4:0] id_rs1_addr;
    wire [4:0] id_rs2_addr;
    wire [4:0] id_rd_addr;

    // ID/EX Register Outputs
    wire ex_regwrite;
    wire ex_memtoreg;
    wire ex_memread;
    wire ex_memwrite;
    wire ex_branch;
    wire ex_alusrc;
    wire [ALU_OP_WIDTH-1:0] ex_aluop;
    wire [XLEN-1:0] ex_pc_plus_4;
    wire [XLEN-1:0] ex_rs1_data;
    wire [XLEN-1:0] ex_rs2_data;
    wire [XLEN-1:0] ex_immediate;
    wire [4:0]      ex_rs1_addr; 
    wire [4:0]      ex_rs2_addr; 
    wire [4:0]      ex_rd_addr;

    // EX Stage
    wire [XLEN-1:0] ex_alu_operand_b;
    wire [XLEN-1:0] ex_alu_result;
    wire            ex_alu_zero; 

    // EX/MEM Register Outputs
    wire mem_regwrite;
    wire mem_memtoreg;
    wire mem_memread;
    wire mem_memwrite;
    // wire mem_branch; // Pass through if needed
    wire [XLEN-1:0] mem_alu_result;
    wire [XLEN-1:0] mem_rs2_data;
    wire [4:0]      mem_rd_addr;

    // MEM Stage
    wire [XLEN-1:0] mem_read_data; // Data read from DMem

    // MEM/WB Register Outputs
    wire wb_regwrite;
    wire wb_memtoreg;
    wire [XLEN-1:0] wb_read_data;
    wire [XLEN-1:0] wb_alu_result;
    wire [4:0]      wb_rd_addr;

    // WB Stage
    wire [XLEN-1:0] wb_write_data; // Final data to write to RegFile


    // Fetch (IF)
    pc_logic #(
        .XLEN(XLEN),
        .RESET_VECTOR(RESET_VECTOR)
    ) pc_reg (
        .clk(clk),
        .rst(rst),
        .pc_write_enable(if_pc_write_enable),
        .next_pc_select_in(if_next_pc_select_in), 
        .pc_out(pc_out)
    );

    assign if_pc_plus_4 = pc_out + 4;

    instruction_memory #(
        .XLEN(XLEN),
        .ADDR_WIDTH(XLEN), 
        .MEM_DEPTH(MEM_DEPTH),
        .INIT_FILE(IMEM_INIT_FILE)
    ) i_mem (
        .addr(pc_out), 
        .instr(if_instruction)
    );

    // IF/ID Pipeline Register

    if_id_register #(
        .XLEN(XLEN)
        // .NOP_INSTRUCTION(...) // Use default or specify
    ) if_id_reg (
        .clk(clk),
        .rst(rst),
        .if_instruction(if_instruction),
        .if_pc_plus_4(if_pc_plus_4),
        .id_instruction(id_instruction),
        .id_pc_plus_4(id_pc_plus_4)
    );

    // Instruction Decode / Register Fetch (ID)
    assign id_rs1_addr = id_instruction[19:15];
    assign id_rs2_addr = id_instruction[24:20];
    assign id_rd_addr  = id_instruction[11:7];

    register_file #(
        .XLEN(XLEN)
    ) reg_file (
        .clk(clk),
        .rst(rst),
        .rs1_addr(id_rs1_addr),
        .rs1_rdata(id_rs1_data),
        .rs2_addr(id_rs2_addr),
        .rs2_rdata(id_rs2_data),
        .we(wb_regwrite),       
        .rd_addr(wb_rd_addr),   
        .rd_wdata(wb_write_data)
    );

    immediate_generator #(
        .XLEN(XLEN)
    ) imm_gen (
        .instr(id_instruction),
        .immediate(id_immediate)
    );

    control_unit #(
        .ALU_OP_WIDTH(ALU_OP_WIDTH)
    ) ctrl_unit (
        .opcode(id_instruction[6:0]),
        .funct3(id_instruction[14:12]),
        .funct7(id_instruction[31:25]),
        .RegWrite_o(id_ex_regwrite),
        .MemToReg_o(id_ex_memtoreg),
        .MemRead_o(id_ex_memread),
        .MemWrite_o(id_ex_memwrite),
        .Branch_o(id_ex_branch),
        .ALUSrc_o(id_ex_alusrc),
        .ALUOp_o(id_ex_aluop)
    );

    id_ex_register #(
        .XLEN(XLEN),
        .ALU_OP_WIDTH(ALU_OP_WIDTH)
    ) id_ex_reg (
        .clk(clk),
        .rst(rst),
        .id_regwrite(id_ex_regwrite),
        .id_memtoreg(id_ex_memtoreg),
        .id_memread(id_ex_memread),
        .id_memwrite(id_ex_memwrite),
        .id_branch(id_ex_branch),
        .id_alusrc(id_ex_alusrc),
        .id_aluop(id_ex_aluop),
        .id_pc_plus_4(id_pc_plus_4),
        .id_rs1_data(id_rs1_data),
        .id_rs2_data(id_rs2_data),
        .id_immediate(id_immediate),
        .id_rs1_addr(id_rs1_addr), 
        .id_rs2_addr(id_rs2_addr),
        .id_rd_addr(id_rd_addr),
        .ex_regwrite(ex_regwrite),
        .ex_memtoreg(ex_memtoreg),
        .ex_memread(ex_memread),
        .ex_memwrite(ex_memwrite),
        .ex_branch(ex_branch),
        .ex_alusrc(ex_alusrc),
        .ex_aluop(ex_aluop),
        .ex_pc_plus_4(ex_pc_plus_4),
        .ex_rs1_data(ex_rs1_data),
        .ex_rs2_data(ex_rs2_data),
        .ex_immediate(ex_immediate),
        .ex_rs1_addr(ex_rs1_addr),
        .ex_rs2_addr(ex_rs2_addr),
        .ex_rd_addr(ex_rd_addr)
    );

    // Execute (EX)
    assign ex_alu_operand_b = (ex_alusrc == 1'b1) ? ex_immediate : ex_rs2_data;
    alu #(
        .XLEN(XLEN),
        .ALU_OP_WIDTH(ALU_OP_WIDTH)
    ) alu_unit (
        .src1(ex_rs1_data),      
        .src2(ex_alu_operand_b), 
        .alu_op(ex_aluop),
        .result(ex_alu_result),
        .zero(ex_alu_zero)
    );

    ex_mem_register #(
        .XLEN(XLEN)
    ) ex_mem_reg (
        .clk(clk),
        .rst(rst),
        .ex_regwrite(ex_regwrite),
        .ex_memtoreg(ex_memtoreg),
        .ex_memread(ex_memread),
        .ex_memwrite(ex_memwrite),
        .ex_branch(ex_branch), 
        .ex_alu_result(ex_alu_result),
        .ex_rs2_data(ex_rs2_data), 
        .ex_rd_addr(ex_rd_addr),
        .mem_regwrite(mem_regwrite),
        .mem_memtoreg(mem_memtoreg),
        .mem_memread(mem_memread),
        .mem_memwrite(mem_memwrite),
        .mem_branch(mem_branch),
        .mem_alu_result(mem_alu_result),
        .mem_rs2_data(mem_rs2_data),
        .mem_rd_addr(mem_rd_addr)
    );

    // Memory Access (MEM)
    assign mem_read_data = {XLEN{1'bx}}; 

    /* // Uncomment and adapt when adding Data Memory
    data_memory #(
        .XLEN(XLEN),
        .ADDR_WIDTH(XLEN),
        .MEM_DEPTH(MEM_DEPTH),
        .INIT_FILE(DMEM_INIT_FILE)
    ) d_mem (
        .clk(clk),
        // .rst(rst), // DMem might not need reset signal
        .addr(mem_alu_result), // Address comes from ALU result
        .wdata(mem_rs2_data),  // Write data comes from rs2
        .mem_read(mem_memread),
        .mem_write(mem_memwrite),
        .rdata(mem_read_data) // Output data read from memory
    );
    */

    // MEM/WB Pipeline Register
    mem_wb_register #(
        .XLEN(XLEN)
    ) mem_wb_reg (
        .clk(clk),
        .rst(rst),
        .mem_regwrite(mem_regwrite),
        .mem_memtoreg(mem_memtoreg),
        .mem_read_data(mem_read_data), 
        .mem_alu_result(mem_alu_result),
        .mem_rd_addr(mem_rd_addr),
        .wb_regwrite(wb_regwrite),
        .wb_memtoreg(wb_memtoreg),
        .wb_read_data(wb_read_data),
        .wb_alu_result(wb_alu_result),
        .wb_rd_addr(wb_rd_addr)
    );

    // Writeback (WB)
    assign wb_write_data = (wb_memtoreg == 1'b1) ? wb_read_data : wb_alu_result;
endmodule