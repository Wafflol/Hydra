module tb_control_unit();
    import cpu_types::*;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic funct7_5, reg_write, alu_src_a, alu_src_b, mem_write, branch, jump;
    imm_type_t imm_type;
    alu_op_t alu_op;
    result_t result_src;

    control_unit control_unit(.*);

    // Set the inputs, then check every output against the expected values
    task automatic check(
        input string      name,
        input logic [6:0] op,
        input logic [2:0] f3,
        input logic       f7_5,
        input logic       e_reg_write,
        input imm_type_t  e_imm_type,
        input logic       e_alu_src_a,
        input logic       e_alu_src_b,
        input alu_op_t    e_alu_op,
        input logic       e_mem_write,
        input result_t    e_result_src,
        input logic       e_branch,
        input logic       e_jump
        );
        opcode   = op;
        funct3   = f3;
        funct7_5 = f7_5;
        #1;
        assert (reg_write === e_reg_write)
        else $error("%s: reg_write=%b expected %b", name, reg_write, e_reg_write);
        assert (imm_type === e_imm_type)
        else $error("%s: imm_type=%s expected %s", name, imm_type.name(), e_imm_type.name());
        assert (alu_src_a === e_alu_src_a)
        else $error("%s: alu_src_a=%b expected %b", name, alu_src_a, e_alu_src_a);
        assert (alu_src_b === e_alu_src_b)
        else $error("%s: alu_src_b=%b expected %b", name, alu_src_b, e_alu_src_b);
        assert (alu_op === e_alu_op)
        else $error("%s: alu_op=%s expected %s", name, alu_op.name(), e_alu_op.name());
        assert (mem_write === e_mem_write)
        else $error("%s: mem_write=%b expected %b", name, mem_write, e_mem_write);
        assert (result_src === e_result_src)
        else $error("%s: result_src=%s expected %s", name, result_src.name(), e_result_src.name());
        assert (branch === e_branch)
        else $error("%s: branch=%b expected %b", name, branch, e_branch);
        assert (jump === e_jump)
        else $error("%s: jump=%b expected %b", name, jump, e_jump);
    endtask

    // R-type: everything fixed except alu_op
    task automatic check_r(input string name, input logic [2:0] f3, input logic f7_5, input alu_op_t e_alu_op);
        check(name, OP_R, f3, f7_5, 1, IMM_I, 0, 0, e_alu_op, 0, RESULT_ALU, 0, 0);
    endtask

    // I-type ALU: same as R-type but operand B is the immediate
    task automatic check_i(input string name, input logic [2:0] f3, input logic f7_5, input alu_op_t e_alu_op);
        check(name, OP_IMM, f3, f7_5, 1, IMM_I, 0, 1, e_alu_op, 0, RESULT_ALU, 0, 0);
    endtask

    initial begin
        // ========================================================================
        // Part A: one test per opcode (main decoder table)
        //                         reg_w imm_type src_a src_b alu_op      mem_w result_src  br  jmp
        // ========================================================================
        check("R (ADD)", OP_R,      3'b000, 0, 1, IMM_I, 0, 0, ALU_ADD,    0, RESULT_ALU, 0, 0);
        check("ADDI",    OP_IMM,    3'b000, 0, 1, IMM_I, 0, 1, ALU_ADD,    0, RESULT_ALU, 0, 0);
        check("LW",      OP_LOAD,   3'b010, 0, 1, IMM_I, 0, 1, ALU_ADD,    0, RESULT_MEM, 0, 0);
        check("SW",      OP_STORE,  3'b010, 0, 0, IMM_S, 0, 1, ALU_ADD,    1, RESULT_ALU, 0, 0);
        check("BEQ",     OP_BRANCH, 3'b000, 0, 0, IMM_B, 1, 1, ALU_ADD,    0, RESULT_ALU, 1, 0);
        check("JAL",     OP_JAL,    3'b000, 0, 1, IMM_J, 1, 1, ALU_ADD,    0, RESULT_PC4, 0, 1);
        check("JALR",    OP_JALR,   3'b000, 0, 1, IMM_I, 0, 1, ALU_ADD,    0, RESULT_PC4, 0, 1);
        check("LUI",     OP_LUI,    3'b000, 0, 1, IMM_U, 0, 1, ALU_PASS_B, 0, RESULT_ALU, 0, 0);
        check("AUIPC",   OP_AUIPC,  3'b000, 0, 1, IMM_U, 1, 1, ALU_ADD,    0, RESULT_ALU, 0, 0);

        // No-ops and unknown opcodes: nothing may write registers or memory
        check("FENCE",   OP_FENCE,  3'b000, 0, 0, IMM_I, 0, 0, ALU_ADD,    0, RESULT_ALU, 0, 0);
        check("SYSTEM",  OP_SYSTEM, 3'b000, 0, 0, IMM_I, 0, 0, ALU_ADD,    0, RESULT_ALU, 0, 0);
        check("unknown", 7'b1111111, 3'b000, 0, 0, IMM_I, 0, 0, ALU_ADD,   0, RESULT_ALU, 0, 0);

        // funct bits must not change the ALU op for non-ALU instructions
        check("LW f7=1", OP_LOAD,   3'b010, 1, 1, IMM_I, 0, 1, ALU_ADD,    0, RESULT_MEM, 0, 0);
        check("BLT",     OP_BRANCH, 3'b100, 0, 0, IMM_B, 1, 1, ALU_ADD,    0, RESULT_ALU, 1, 0);

        // ========================================================================
        // Part B: ALU decoding (funct3 / funct7_5)
        // ========================================================================
        check_r("ADD",  3'b000, 0, ALU_ADD);
        check_r("SUB",  3'b000, 1, ALU_SUB);
        check_r("SLL",  3'b001, 0, ALU_SLL);
        check_r("SLT",  3'b010, 0, ALU_SLT);
        check_r("SLTU", 3'b011, 0, ALU_SLTU);
        check_r("XOR",  3'b100, 0, ALU_XOR);
        check_r("SRL",  3'b101, 0, ALU_SRL);
        check_r("SRA",  3'b101, 1, ALU_SRA);
        check_r("OR",   3'b110, 0, ALU_OR);
        check_r("AND",  3'b111, 0, ALU_AND);

        // ADDI with a negative immediate has bit 30 set; it must stay ADD
        check_i("ADDI neg", 3'b000, 1, ALU_ADD);
        check_i("SLLI",     3'b001, 0, ALU_SLL);
        check_i("SLTI",     3'b010, 0, ALU_SLT);
        check_i("SLTIU",    3'b011, 0, ALU_SLTU);
        check_i("XORI",     3'b100, 0, ALU_XOR);
        check_i("SRLI",     3'b101, 0, ALU_SRL);
        check_i("SRAI",     3'b101, 1, ALU_SRA);
        check_i("ORI",      3'b110, 0, ALU_OR);
        check_i("ANDI",     3'b111, 0, ALU_AND);

        $display("ALL CONTROL UNIT TESTS PASSED");
        $finish;
    end
endmodule
