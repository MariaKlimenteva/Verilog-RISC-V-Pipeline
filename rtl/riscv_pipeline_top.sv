`include "defs.vh"

module riscv_pipeline_top #(
    parameter MEM_DEPTH    = 1024,
    parameter IMEM_INIT_FILE = "addi_program.hex", 
    parameter DMEM_INIT_FILE = "", 
    parameter RESET_VECTOR = 32'h00000000
) (
    input logic clk,
    input logic rst 
);
    /* verilator lint_off UNUSED */
    /* verilator lint_off UNDRIVEN */
    if_id_data  if_id_current, if_id_next;
    id_ex_data  id_ex_current, id_ex_next;
    ex_mem_data ex_mem_current, ex_mem_next;
    mem_wb_data mem_wb_current, mem_wb_next;

    logic [XLEN-1:0] pc_out;
    logic [XLEN-1:0] pc_plus_4;
    logic [XLEN-1:0] pc_next_target = {(XLEN){1'b0}};

    logic [XLEN-1:0] if_instruction;
    // logic [XLEN-1:0] id_instruction;

    logic [XLEN-1:0] mem_read_data;

    logic wb_regwrite;
    logic [4:0] wb_rd_addr;
    logic [XLEN-1:0] wb_write_data;

    logic take_branch;
    /* verilator lint_off UNDRIVEN */
    /* verilator lint_off UNUSED */

    pc_logic #(
        .RESET_VECTOR(RESET_VECTOR)
    ) pc_reg (
        .clk(clk),
        .rst(rst),
        .branch_target_in(pc_next_target), 
        .take_branch(take_branch),
        .pc_out(pc_out),
        .pc_plus_4(pc_plus_4)
    );
    
    instruction_memory #(
        .ADDR_WIDTH(XLEN), 
        .MEM_DEPTH(MEM_DEPTH),
        .INIT_FILE(IMEM_INIT_FILE)
    ) i_mem (
        .addr(pc_out), 
        .instr(if_instruction)
    );

    // IF logic
    always_comb begin
        if_id_next.instruction = if_instruction;
        if_id_next.pc_plus_4   = pc_plus_4;
        if_id_next.valid       = !rst; 
    end
    
    // IF/ID Register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            if_id_current <= '{default: '0, instruction: NOP_INSTRUCTION}; 
        else
            if_id_current <= if_id_next;
    end

    logic [4:0] id_rs1_addr;
    logic [4:0] id_rs2_addr;
    logic [4:0] id_rd_addr;

    logic [XLEN-1:0] regfile_rs1_data;
    logic [XLEN-1:0] regfile_rs2_data;

    // ID logic 
    assign id_rs1_addr = if_id_current.instruction[19:15];
    assign id_rs2_addr = if_id_current.instruction[24:20];
    assign id_rd_addr  = if_id_current.instruction[11:7];

    /* public */ register_file #() reg_file (
        .clk(clk), .rst(rst),
        .rs1_addr(id_rs1_addr), .rs2_addr(id_rs2_addr),
        .we(mem_wb_current.RegWrite), .rd_addr(mem_wb_current.rd_addr),   
        .rd_wdata(wb_write_data),
        .rs1_rdata(regfile_rs1_data), .rs2_rdata(regfile_rs2_data)
    );

    logic [XLEN-1:0] immgen_immediate;
    control_signals cu_control;

    immediate_generator #() imm_gen (
        .instr(if_id_current.instruction), 
        .immediate(immgen_immediate)
    );

    control_unit #() ctrl_unit (
        .opcode(if_id_current.instruction[6:0]),
        .funct3(if_id_current.instruction[14:12]),
        .funct7(if_id_current.instruction[31:25]),
        .control_out_s(cu_control)
    );

    always_comb begin
        id_ex_next = '{default: '0}; 
        id_ex_next.valid = if_id_current.valid; 

        if (if_id_current.valid) begin 
            id_ex_next.control    = cu_control;     
            id_ex_next.pc_plus_4  = if_id_current.pc_plus_4;
            id_ex_next.rs1_data   = regfile_rs1_data; 
            id_ex_next.rs2_data   = regfile_rs2_data; 
            id_ex_next.immediate  = immgen_immediate;
            id_ex_next.rs1_addr   = id_rs1_addr;
            id_ex_next.rs2_addr   = id_rs2_addr;
            id_ex_next.rd_addr    = id_rd_addr;
        end
    end
       
    // ID/EX Register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            id_ex_current <= '{default: '0}; 
        else
            id_ex_current <= id_ex_next;
    end

    logic [XLEN-1:0] src1_alu;
    logic [XLEN-1:0] src2_alu;
    logic [XLEN-1:0] ex_alu_result;
    logic ex_alu_zero;
    
    // EX logic
    assign src1_alu = id_ex_current.rs1_data;
    assign src2_alu = (id_ex_current.control.ALUSrc) ? id_ex_current.immediate : id_ex_current.rs2_data;

    alu #() alu_unit (
        .src1(src1_alu),      
        .src2(src2_alu), 
        .alu_op(id_ex_current.control.ALUOp),
        .result(ex_alu_result),
        .zero(ex_alu_zero)
    );

    always_comb begin
        ex_mem_next = '{default:'0};
        ex_mem_next.valid = id_ex_current.valid;

        if (id_ex_current.valid) begin
            ex_mem_next.RegWrite = id_ex_current.control.RegWrite;
            ex_mem_next.MemToReg = id_ex_current.control.MemToReg;
            ex_mem_next.MemRead  = id_ex_current.control.MemRead;
            ex_mem_next.MemWrite = id_ex_current.control.MemWrite;
            ex_mem_next.Branch   = id_ex_current.control.Branch; 
            ex_mem_next.alu_result = ex_alu_result; 
            ex_mem_next.rs2_data   = id_ex_current.rs2_data; 
            ex_mem_next.rd_addr    = id_ex_current.rd_addr; 
        end
    end

    // EX/MEM Register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            ex_mem_current <= '{default: '0};
        else
            ex_mem_current <= ex_mem_next;
    end
    assign mem_read_data = {XLEN{1'bx}};

    always_comb begin
        mem_wb_next = '{default:'0};
        mem_wb_next.valid = ex_mem_current.valid;

        if (ex_mem_current.valid) begin
            mem_wb_next.RegWrite = ex_mem_current.RegWrite;
            mem_wb_next.MemToReg = ex_mem_current.MemToReg;
            mem_wb_next.read_data = mem_read_data;    
            mem_wb_next.alu_result = ex_mem_current.alu_result; 
            mem_wb_next.rd_addr = ex_mem_current.rd_addr;
        end
    end

    assign wb_write_data = (mem_wb_current.MemToReg) ? mem_wb_current.read_data : mem_wb_current.alu_result;

    // MEM/WB Register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            mem_wb_current <= '{default: '0};
        else
            mem_wb_current <= mem_wb_next;
    end
endmodule