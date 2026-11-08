module alu_decoder
    import cpu_types::*;
(
    input opcode_t    opcode,
    input logic [2:0] funct3,
    input logic       funct7_5,
    output alu_op_t   alu_op
);

    always_comb begin
        alu_op = ALU_ADD;
        case (opcode)
            OP_LUI: alu_op = ALU_PASS_B;
            OP_R, OP_IMM: begin
                case (funct3)
                    3'b000: alu_op = (opcode == OP_R && funct7_5) ? ALU_SUB : ALU_ADD;
                    3'b001: alu_op = ALU_SLL;
                    3'b010: alu_op = ALU_SLT;
                    3'b011: alu_op = ALU_SLTU;
                    3'b100: alu_op = ALU_XOR;
                    3'b101: alu_op = funct7_5 ? ALU_SRA : ALU_SRL;
                    3'b110: alu_op = ALU_OR;
                    3'b111: alu_op = ALU_AND;
                    default:;
                endcase
            end
            default:;
        endcase
    end
endmodule
