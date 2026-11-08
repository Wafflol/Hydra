package cpu_types;
    typedef enum logic [3:0] {
        ALU_ADD,
        ALU_SUB,
        ALU_AND,
        ALU_OR,
        ALU_XOR,
        ALU_SLL,
        ALU_SRL,
        ALU_SRA,
        ALU_SLT,
        ALU_SLTU,
        ALU_PASS_B
    } alu_op_t;

    typedef enum logic [2:0] {
        IMM_I,
        IMM_S,
        IMM_B,
        IMM_U,
        IMM_J
    } imm_type_t;

    typedef enum logic [6:0] {
        OP_LOAD   = 7'b0000011,
        OP_FENCE  = 7'b0001111,
        OP_IMM    = 7'b0010011,
        OP_AUIPC  = 7'b0010111,
        OP_STORE  = 7'b0100011,
        OP_R      = 7'b0110011,
        OP_LUI    = 7'b0110111,
        OP_BRANCH = 7'b1100011,
        OP_JALR   = 7'b1100111,
        OP_JAL    = 7'b1101111,
        OP_SYSTEM = 7'b1110011
    } opcode_t;

    typedef enum logic [1:0] {
        RESULT_ALU,
        RESULT_MEM,
        RESULT_PC4
    } result_t;
endpackage
