module control_unit
    import cpu_types::*;
(
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic       funct7_5,

    output logic      reg_write,
    output imm_type_t imm_type,
    output logic      alu_src_a,
    output logic      alu_src_b,
    output alu_op_t   alu_op,
    output logic      mem_write,
    output result_t   result_src,
    output logic      branch,
    output logic      jump
);

    alu_op_t alu_decoder_out;

    alu_decoder alu_decoder(
        .opcode(opcode_t'(opcode)),
        .funct3,
        .funct7_5,
        .alu_op(alu_decoder_out)
    );

    always_comb begin : op
        reg_write  = 1'b0;
        imm_type   = IMM_I;
        alu_src_a  = 1'b0;
        alu_src_b  = 1'b0;
        alu_op     = ALU_ADD;
        mem_write  = 1'b0;
        result_src = RESULT_ALU;
        branch     = 1'b0;
        jump       = 1'b0;

        case (opcode)
            OP_R: begin
                reg_write = 1'b1;
                alu_op = alu_decoder_out;
            end
            OP_IMM: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                alu_op = alu_decoder_out;
            end
            OP_LOAD: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                result_src = RESULT_MEM;
            end
            OP_STORE: begin
                imm_type = IMM_S;
                alu_src_b = 1'b1;
                mem_write = 1'b1;
            end
            OP_BRANCH: begin
                imm_type = IMM_B;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                branch = 1'b1;
            end
            OP_JAL: begin
                reg_write = 1'b1;
                imm_type = IMM_J;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                result_src = RESULT_PC4;
                jump = 1'b1;
            end
            OP_JALR: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                result_src = RESULT_PC4;
                jump = 1'b1;
            end
            OP_LUI: begin
                reg_write = 1'b1;
                imm_type = IMM_U;
                alu_src_b = 1'b1;
                alu_op = ALU_PASS_B;
            end
            OP_AUIPC: begin
                reg_write = 1'b1;
                imm_type = IMM_U;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
            end
            OP_FENCE:; // no-op
            OP_SYSTEM:; // no-op
            default : ;
        endcase
    end
endmodule
