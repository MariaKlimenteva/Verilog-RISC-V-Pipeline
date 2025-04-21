module immediate_generator #(
    parameter XLEN = 32
) (
    input wire [31:0] instr,
    output reg [XLEN-1:0] immediate
);
    localparam OPCODE_LOAD   = 7'b0000011; // I-type (LB, LH, LW, LBU, LHU)
    localparam OPCODE_IMM    = 7'b0010011; // I-type (ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI)
    localparam OPCODE_AUIPC  = 7'b0010111; // U-type
    localparam OPCODE_STORE  = 7'b0100011; // S-type (SB, SH, SW)
    localparam OPCODE_AMO    = 7'b0101111; // R-type (ignore immediate for basic ALU ops)
    localparam OPCODE_REG    = 7'b0110011; // R-type (ignore immediate)
    localparam OPCODE_LUI    = 7'b0110111; // U-type
    localparam OPCODE_BRANCH = 7'b1100011; // B-type (BEQ, BNE, BLT, BGE, BLTU, BGEU)
    localparam OPCODE_JALR   = 7'b1100111; // I-type
    localparam OPCODE_JAL    = 7'b1101111; // J-type
    localparam OPCODE_SYSTEM = 7'b1110011; // SYSTEM (ECALL, EBREAK, CSR*) - may have I-imm for CSR

    always @(*) begin
        // for R-type or unknown instructions)
        immediate = {XLEN{1'b0}}; // Default to 0

        case (instr[6:0]) 
            OPCODE_LOAD, OPCODE_IMM, OPCODE_JALR: begin // I-type immediate
                // Immediate: instr[31:20]
                // Sign extend from bit 11 (instr[31])
                immediate = {{(XLEN-12){instr[31]}}, instr[31:20]};
            end

            OPCODE_STORE: begin // S-type immediate
                // Immediate: {instr[31:25], instr[11:7]}
                // Sign extend from bit 11 (instr[31])
                immediate = {{(XLEN-12){instr[31]}}, instr[31:25], instr[11:7]};
            end

            OPCODE_BRANCH: begin // B-type immediate
                // Immediate: {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0} (13 bits total)
                // Sign extend from bit 12 (instr[31])
                immediate = {{(XLEN-13){instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end

            OPCODE_LUI, OPCODE_AUIPC: begin // U-type immediate
                // Immediate: {instr[31:12], 12'b0}
                // No sign extension needed in the traditional sense; forms upper 20 bits
                immediate = {instr[31:12], 12'b0};
            end

            OPCODE_JAL: begin // J-type immediate
                // Immediate: {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0} (21 bits total)
                // Sign extend from bit 20 (instr[31])
                immediate = {{(XLEN-21){instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end
            default: immediate = {XLEN{1'b0}};
        endcase
    end

endmodule