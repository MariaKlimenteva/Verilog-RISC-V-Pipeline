`include "defs.vh"

module riscv_pipeline_top #(
    parameter MEM_DEPTH    = 1024,
    parameter DMEM_INIT_FILE = "", 
    parameter RESET_VECTOR = 32'h00000000
) (
    input logic clk,
    input logic rst 
);
    if_id_data  if_id_current, if_id_next;
    id_ex_data  id_ex_current, id_ex_next;
    ex_mem_data ex_mem_current, ex_mem_next;
    mem_wb_data mem_wb_current, mem_wb_next;

    logic [XLEN-1:0] pc_out;
    logic [XLEN-1:0] pc_plus_4;
    logic [XLEN-1:0] pc_next_target = {(XLEN){1'b0}};

    logic [XLEN-1:0] if_instruction;

    logic [XLEN-1:0] wb_write_data;

    logic take_branch;

    logic stall;

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
        .MEM_DEPTH(MEM_DEPTH)
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

    logic [4:0] id_rs1_addr;
    logic [4:0] id_rs2_addr;
    // logic [4:0] id_rd_addr;

    logic [XLEN-1:0] regfile_rs1_data;
    logic [XLEN-1:0] regfile_rs2_data;

    // ID logic 

    /* public */ register_file #() reg_file (
        .clk(clk), 
        .rst(rst),
        .rs1_addr(if_id_current.instruction[19:15]), 
        .rs2_addr(if_id_current.instruction[24:20]),
        .we(mem_wb_current.RegWrite), 
        .rd_addr(mem_wb_current.rd_addr),   
        .rd_wdata(wb_write_data),
        .rs1_rdata(regfile_rs1_data), 
        .rs2_rdata(regfile_rs2_data)
    );
    logic [1:0] forward_src1_alu;
    logic [1:0] forward_src2_alu;

    hazard_unit hu (
        .id_ex_rs1_addr(id_ex_current.rs1_addr),
        .id_ex_rs2_addr(id_ex_current.rs2_addr),     
        .ex_mem_rd_addr(ex_mem_current.rd_addr),      
        .ex_mem_regwrite(ex_mem_current.RegWrite),     
        .mem_wb_rd_addr(mem_wb_current.rd_addr),     
        .mem_wb_regwrite(mem_wb_current.RegWrite),    
        
        .forward_a(forward_src1_alu),
        .forward_b(forward_src2_alu)
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
        id_rs1_addr = if_id_current.instruction[19:15];
        id_rs2_addr = if_id_current.instruction[24:20];

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
            id_ex_next.rd_addr    = if_id_current.instruction[11:7];
        end
    end

    logic [XLEN-1:0] ex_alu_result;
    logic ex_alu_zero;

    // EX logic
    logic [XLEN-1:0] forwarded_rs1_data;
    logic [XLEN-1:0] forwarded_rs2_data_or_imm;
    // multiplexer for rs1
    always_comb begin
        case (forward_src1_alu)
            2'b00: forwarded_rs1_data = id_ex_current.rs1_data;
            2'b01: forwarded_rs1_data = wb_write_data;
            2'b10: forwarded_rs1_data = ex_mem_current.alu_result;
            default: forwarded_rs1_data = 'x;
        endcase
    end

    logic [XLEN-1:0] alu_operand_b_before_fwd;
    assign alu_operand_b_before_fwd = (id_ex_current.control.ALUSrc) ? 
                                        id_ex_current.immediate : id_ex_current.rs2_data;
    // multiplexer for rs2
    always_comb begin
        if (id_ex_current.control.ALUSrc) begin
            forwarded_rs2_data_or_imm = alu_operand_b_before_fwd;
        end else begin
            case (forward_src2_alu)
                2'b00: forwarded_rs2_data_or_imm = id_ex_current.rs2_data;
                2'b01: forwarded_rs2_data_or_imm = wb_write_data;
                2'b10: forwarded_rs2_data_or_imm = ex_mem_current.alu_result;
                default: forwarded_rs2_data_or_imm = 'x;
            endcase
        end
    end

    alu #() alu_unit (
        .src1(forwarded_rs1_data),      
        .src2(forwarded_rs2_data_or_imm), 
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
            ex_mem_next.rs1_data = id_ex_current.rs1_data;
            ex_mem_next.rs2_data   = id_ex_current.rs2_data; 
            ex_mem_next.rd_addr    = id_ex_current.rd_addr; 
        end
    end

    logic [XLEN-1:0] mem_read_data;

    data_memory #(
        .ADDR_WIDTH(XLEN),
        .DATA_WIDTH(XLEN),
        .MEM_DEPTH(MEM_DEPTH)
    ) data_mem (
        .clk(clk),
        .rst(rst),
        .we(ex_mem_current.MemWrite),
        .addr(ex_mem_current.alu_result),
        .wdata(ex_mem_current.rs2_data),
        .rdata(mem_read_data)
    );

    always_comb begin
        mem_wb_next = '{default:'0};
        mem_wb_next.valid = ex_mem_current.valid;

        if (ex_mem_current.valid) begin
            mem_wb_next.RegWrite = ex_mem_current.RegWrite;
            mem_wb_next.MemToReg = ex_mem_current.MemToReg;
            mem_wb_next.read_data = ex_mem_current.MemRead ? mem_read_data : 'x;    
            mem_wb_next.alu_result = ex_mem_current.alu_result; 
            mem_wb_next.rd_addr = ex_mem_current.rd_addr;
        end
    end

    assign wb_write_data = (mem_wb_current.MemToReg) ? mem_wb_current.read_data : mem_wb_current.alu_result;

    always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        if_id_current <= '{default: '0, instruction: NOP_INSTRUCTION};
        id_ex_current <= '{default: '0};
        ex_mem_current <= '{default: '0};
        mem_wb_current <= '{default: '0};
    end else if (stall) begin
        if_id_current <= if_id_current;
        id_ex_current <= id_ex_current;
        ex_mem_current <= ex_mem_current;
        mem_wb_current <= mem_wb_current;
    end else begin
        if_id_current <= if_id_next;
        id_ex_current <= id_ex_next;
        ex_mem_current <= ex_mem_next;
        mem_wb_current <= mem_wb_next;
    end
end
endmodule