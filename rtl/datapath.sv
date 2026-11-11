module datapath
    import cpu_types::*;
(
    input logic clk,
    input logic rst_n,
    input logic en
);

    if_id_t if_id_d;
    id_ex_t id_ex_e;
    ex_mem_t ex_mem_m;
    mem_wb_t mem_wb_w;

    // Execute Registers
    logic [31:0] alu_result_e;
    logic pc_src_e;

    // Writeback Registers
    logic [31:0] result_w;
    logic [4:0] rd_w;
    logic reg_write_w;

    // ====================================================
    // FETCH
    // ====================================================
    logic [31:0] instr_f, pc_f, pc_plus4_f, pc_next;

    fetch fetch(
        .clk,
        .rst_n,
        .en,
        .pc_src_e,
        .alu_result_e,
        .pc_f(pc_f),
        .pc_plus4_f(pc_plus4_f),
        .pc_next
    );

    instr_mem imem(
        .clk,
        .addr(pc_next),
        .instr(instr_f)
    );

    always_ff @(posedge clk) begin : if_id_pipeline_reg
        if (~rst_n) if_id_d <= '0;
        else if (en) if_id_d <= '{instr: instr_f, pc: pc_f, pc_plus4: pc_plus4_f};
    end

    // ====================================================
    // DECODE
    // ====================================================
    logic [31:0] instr_d, imm_d, pc_d, pc_plus4_d;
    logic reg_write_d, alu_src_a_d, alu_src_b_d, mem_write_d, branch_d, jump_d;
    alu_op_t alu_op_d;
    result_t result_src_d;
    imm_type_t imm_type;

    assign instr_d = if_id_d.instr;
    assign pc_d = if_id_d.pc;
    assign pc_plus4_d = if_id_d.pc_plus4;

    control_unit control_unit(
        .opcode(instr_d[6:0]),
        .funct3(instr_d[14:12]),
        .funct7_5(instr_d[30]),
        .reg_write(reg_write_d),
        .imm_type(imm_type),
        .alu_src_a(alu_src_a_d),
        .alu_src_b(alu_src_b_d),
        .alu_op(alu_op_d),
        .mem_write(mem_write_d),
        .result_src(result_src_d),
        .branch(branch_d),
        .jump(jump_d)
    );

    imm_gen imm_gen(
        .instr(instr_d),
        .imm_type,
        .imm(imm_d)
    );

    logic [31:0] rs1_data_d, rs2_data_d;

    reg_file reg_file(
        .clk,
        .reg_write(reg_write_w),
        .rs1(instr_d[19:15]),
        .rs2(instr_d[24:20]),
        .rd(rd_w),
        .wr_data(result_w),
        .rs1_data(rs1_data_d),
        .rs2_data(rs2_data_d)
    );

    always_ff @(posedge clk) begin : id_ex_pipeline_reg
        if (~rst_n) id_ex_e <= '0;
        else if (en) id_ex_e <= '{
            pc: pc_d,
            pc_plus4: pc_plus4_d,
            imm: imm_d,
            rs1_data: rs1_data_d,
            rs2_data: rs2_data_d,
            rd: instr_d[11:7],
            funct3: instr_d[14:12],
            reg_write: reg_write_d,
            alu_src_a: alu_src_a_d,
            alu_src_b: alu_src_b_d,
            alu_op: alu_op_d,
            mem_write: mem_write_d,
            result_src: result_src_d,
            branch: branch_d,
            jump: jump_d
        };
    end

    // ====================================================
    // EXECUTE
    // ====================================================
    logic [31:0] pc_e;
    logic [31:0] pc_plus4_e;
    logic [31:0] imm_e;
    logic [31:0] rs1_data_e;
    logic [31:0] rs2_data_e;
    logic [4:0] rd_e;
    logic [2:0] funct3_e;
    logic reg_write_e;
    logic alu_src_a_e;
    logic alu_src_b_e;
    alu_op_t alu_op_e;
    logic mem_write_e;
    result_t result_src_e;
    logic branch_e;
    logic jump_e;

    always_comb begin : execute_pipeline_signals
        pc_e = id_ex_e.pc;
        pc_plus4_e = id_ex_e.pc_plus4;
        imm_e = id_ex_e.imm;
        rs1_data_e = id_ex_e.rs1_data;
        rs2_data_e = id_ex_e.rs2_data;
        rd_e = id_ex_e.rd;
        funct3_e = id_ex_e.funct3;
        reg_write_e = id_ex_e.reg_write;
        alu_src_a_e = id_ex_e.alu_src_a;
        alu_src_b_e = id_ex_e.alu_src_b;
        alu_op_e = id_ex_e.alu_op;
        mem_write_e = id_ex_e.mem_write;
        result_src_e = id_ex_e.result_src;
        branch_e = id_ex_e.branch;
        jump_e = id_ex_e.jump;
    end

    logic [31:0] op1_e, op2_e;

    assign op1_e = alu_src_a_e ? pc_e : rs1_data_e;
    assign op2_e = alu_src_b_e ? imm_e : rs2_data_e;

    alu alu(
        .op1(op1_e),
        .op2(op2_e),
        .alu_op(alu_op_e),
        .result(alu_result_e)
    );

    logic taken_e;

    branch_unit branch_unit(
        .rs1_data(rs1_data_e),
        .rs2_data(rs2_data_e),
        .funct3(funct3_e),
        .taken(taken_e)
    );

    assign pc_src_e = jump_e || (branch_e && taken_e);

    always_ff @(posedge clk) begin : ex_mem_pipeline_reg
        if (~rst_n) ex_mem_m <= '0;
        else if (en) ex_mem_m <= '{
            alu_result: alu_result_e,
            pc_plus4: pc_plus4_e,
            rd: rd_e,
            funct3: funct3_e,
            reg_write: reg_write_e,
            result_src: result_src_e
        };
    end

    // ====================================================
    // MEMORY
    // ====================================================
    logic [31:0] alu_result_m, pc_plus4_m;
    logic [4:0] rd_m;
    logic reg_write_m;
    result_t result_src_m;

    logic [31:0] read_data_m;

    always_comb begin : mem_register_signals
        alu_result_m = ex_mem_m.alu_result;
        pc_plus4_m = ex_mem_m.pc_plus4;
        rd_m = ex_mem_m.rd;
        reg_write_m = ex_mem_m.reg_write;
        result_src_m = ex_mem_m.result_src;
    end

    data_mem dmem(
        .clk,
        .we({4{mem_write_e}}),
        .addr(alu_result_e),
        .wdata(rs2_data_e),
        .rdata(read_data_m)
    );

    always_ff @(posedge clk) begin : mem_wb_pipeline_reg
        if (~rst_n) mem_wb_w <= '0;
        else if (en) mem_wb_w <= '{
            alu_result: alu_result_m,
            read_data: read_data_m,
            pc_plus4: pc_plus4_m,
            rd: rd_m,
            reg_write: reg_write_m,
            result_src: result_src_m
        };
    end

    // ====================================================
    // WRITEBACK
    // ====================================================
    assign rd_w = mem_wb_w.rd;
    assign reg_write_w = mem_wb_w.reg_write;

    always_comb begin : writeback_mux
        case (mem_wb_w.result_src)
            RESULT_ALU: result_w = mem_wb_w.alu_result;
            RESULT_MEM: result_w = mem_wb_w.read_data;
            RESULT_PC4: result_w = mem_wb_w.pc_plus4;
            default: result_w = '0;
        endcase
    end
endmodule
