module tb_imm_gen();
    import cpu_types::*;

    logic [31:0] instr, imm;
    imm_type_t imm_type;

    imm_gen imm_gen(.*);

    task automatic check(input logic [31:0] ist, input imm_type_t i_type, input logic [31:0] e_imm);
        instr = ist;
        imm_type = i_type;
        #1;
        assert (imm === e_imm)
        else $error("instr=%h imm_type=%s imm=%h expected=%h", instr, imm_type.name(), imm, e_imm);
    endtask

    initial begin
        // ========================================================================
        // I-type
        // ========================================================================
        check(32'h00510093, IMM_I, 32'h00000005);  // addi x1, x2, 5
        check(32'hFFF10093, IMM_I, 32'hFFFFFFFF);  // addi x1, x2, -1
        check(32'h80010093, IMM_I, 32'hFFFFF800);  // addi x1, x2, -2048 (most negative)

        // ========================================================================
        // S-type
        // ========================================================================
        check(32'h00512423, IMM_S, 32'h00000008);  // sw x5, 8(x2)
        check(32'hFE512E23, IMM_S, 32'hFFFFFFFC);  // sw x5, -4(x2)

        // ========================================================================
        // B-type
        // ========================================================================
        check(32'h00208863, IMM_B, 32'h00000010);  // beq x1, x2, 16
        check(32'hFE208EE3, IMM_B, 32'hFFFFFFFC);  // beq x1, x2, -4
        check(32'h002080E3, IMM_B, 32'h00000800);  // beq x1, x2, 2048 (bit 11 from instr[7])

        // ========================================================================
        // U-type
        // ========================================================================
        check(32'h123450B7, IMM_U, 32'h12345000);  // lui x1, 0x12345
        check(32'hFFFFF0B7, IMM_U, 32'hFFFFF000);  // lui x1, 0xFFFFF

        // ========================================================================
        // J-type
        // ========================================================================
        check(32'h001000EF, IMM_J, 32'h00000800);  // jal x1, 2048 (bit 11 from instr[20])
        check(32'hFF9FF0EF, IMM_J, 32'hFFFFFFF8);  // jal x1, -8

        $display("ALL IMM_GEN TESTS PASSED");
        $finish;
    end
endmodule
