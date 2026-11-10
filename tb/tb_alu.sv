module tb_alu ();
    import cpu_types::*;

    logic [31:0] op1, op2, result;
    alu_op_t alu_op;

    alu alu (.*);

    task automatic check(input logic [31:0] expected);
        #1;
        assert (result === expected)
        else
            $error(
                "ALU test failed: op1=%h op2=%h alu_op=%s result=%h expected=%h",
                op1,
                op2,
                alu_op,
                result,
                expected
            );
    endtask

    initial begin
        // ============================================================
        // ADD
        // ============================================================

        {op1, op2, alu_op} = {32'd0, 32'd0, ALU_ADD};
        check(32'd0);

        {op1, op2, alu_op} = {32'd1, 32'd2, ALU_ADD};
        check(32'd3);

        {op1, op2, alu_op} = {32'hFFFFFFFF, 32'd1, ALU_ADD};
        check(32'h00000000);  // overflow wraps

        {op1, op2, alu_op} = {32'h7FFFFFFF, 32'd1, ALU_ADD};
        check(32'h80000000);

        // ============================================================
        // SUB
        // ============================================================

        {op1, op2, alu_op} = {32'd2, 32'd1, ALU_SUB};
        check(32'd1);

        {op1, op2, alu_op} = {32'd1, 32'd2, ALU_SUB};
        check(32'hFFFFFFFF);  // -1

        {op1, op2, alu_op} = {32'd0, 32'd0, ALU_SUB};
        check(32'd0);

        {op1, op2, alu_op} = {32'h80000000, 32'd1, ALU_SUB};
        check(32'h7FFFFFFF);

        // ============================================================
        // AND
        // ============================================================

        {op1, op2, alu_op} = {32'hFFFFFFFF, 32'hFFFFFFFF, ALU_AND};
        check(32'hFFFFFFFF);

        {op1, op2, alu_op} = {32'hAAAAAAAA, 32'h55555555, ALU_AND};
        check(32'h00000000);

        {op1, op2, alu_op} = {32'hF0F0F0F0, 32'h0F0F0F0F, ALU_AND};
        check(32'h00000000);

        {op1, op2, alu_op} = {32'hF0F0F0F0, 32'hFFFF0000, ALU_AND};
        check(32'hF0F00000);

        // ============================================================
        // OR
        // ============================================================

        {op1, op2, alu_op} = {32'h00000000, 32'h00000000, ALU_OR};
        check(32'h00000000);

        {op1, op2, alu_op} = {32'hAAAAAAAA, 32'h55555555, ALU_OR};
        check(32'hFFFFFFFF);

        {op1, op2, alu_op} = {32'hF0F0F0F0, 32'h0F0F0F0F, ALU_OR};
        check(32'hFFFFFFFF);

        // ============================================================
        // XOR
        // ============================================================

        {op1, op2, alu_op} = {32'hAAAAAAAA, 32'h55555555, ALU_XOR};
        check(32'hFFFFFFFF);

        {op1, op2, alu_op} = {32'hFFFFFFFF, 32'hFFFFFFFF, ALU_XOR};
        check(32'h00000000);

        {op1, op2, alu_op} = {32'h12345678, 32'h12345678, ALU_XOR};
        check(32'h00000000);

        // ============================================================
        // SLL
        // ============================================================

        {op1, op2, alu_op} = {32'd1, 32'd0, ALU_SLL};
        check(32'd1);

        {op1, op2, alu_op} = {32'd1, 32'd1, ALU_SLL};
        check(32'd2);

        {op1, op2, alu_op} = {32'd1, 32'd4, ALU_SLL};
        check(32'd16);

        {op1, op2, alu_op} = {32'd1, 32'd31, ALU_SLL};
        check(32'h80000000);

        // RISC-V RV32 only uses the low 5 bits of the shift amount
        {op1, op2, alu_op} = {32'd1, 32'd32, ALU_SLL};
        check(32'd1);

        // ============================================================
        // SRL
        // ============================================================

        {op1, op2, alu_op} = {32'h80000000, 32'd0, ALU_SRL};
        check(32'h80000000);

        {op1, op2, alu_op} = {32'h80000000, 32'd1, ALU_SRL};
        check(32'h40000000);

        {op1, op2, alu_op} = {32'h80000000, 32'd31, ALU_SRL};
        check(32'd1);

        {op1, op2, alu_op} = {32'hFFFFFFFF, 32'd4, ALU_SRL};
        check(32'h0FFFFFFF);

        // ============================================================
        // SRA
        // ============================================================

        {op1, op2, alu_op} = {$signed(-32'd2), 32'd1, ALU_SRA};
        check($signed(-32'd1));

        {op1, op2, alu_op} = {$signed(-32'd4), 32'd1, ALU_SRA};
        check($signed(-32'd2));

        {op1, op2, alu_op} = {$signed(-32'd4), 32'd2, ALU_SRA};
        check($signed(-32'd1));

        {op1, op2, alu_op} = {$signed(-32'd1), 32'd31, ALU_SRA};
        check($signed(-32'd1));

        {op1, op2, alu_op} = {32'h80000000, 32'd1, ALU_SRA};
        check(32'hC0000000);

        // Positive numbers should behave like SRL
        {op1, op2, alu_op} = {32'h40000000, 32'd1, ALU_SRA};
        check(32'h20000000);

        // ============================================================
        // SLT - signed
        // ============================================================

        {op1, op2, alu_op} = {32'd1, 32'd2, ALU_SLT};
        check(32'd1);

        {op1, op2, alu_op} = {32'd2, 32'd1, ALU_SLT};
        check(32'd0);

        {op1, op2, alu_op} = {32'd2, 32'd2, ALU_SLT};
        check(32'd0);

        {op1, op2, alu_op} = {$signed(-32'd2), 32'd1, ALU_SLT};
        check(32'd1);

        {op1, op2, alu_op} = {32'd1, $signed(-32'd2), ALU_SLT};
        check(32'd0);

        {op1, op2, alu_op} = {$signed(-32'd2), $signed(-32'd1), ALU_SLT};
        check(32'd1);

        {op1, op2, alu_op} = {$signed(-32'd1), $signed(-32'd2), ALU_SLT};
        check(32'd0);

        // Most important signed-vs-unsigned distinction
        {op1, op2, alu_op} = {32'hFFFFFFFF, 32'd1, ALU_SLT};
        check(32'd1);  // -1 < 1

        // ============================================================
        // SLTU - unsigned
        // ============================================================

        {op1, op2, alu_op} = {32'd1, 32'd2, ALU_SLTU};
        check(32'd1);

        {op1, op2, alu_op} = {32'd2, 32'd1, ALU_SLTU};
        check(32'd0);

        {op1, op2, alu_op} = {32'd2, 32'd2, ALU_SLTU};
        check(32'd0);

        // 0xFFFFFFFF is large unsigned, despite being -1 signed
        {op1, op2, alu_op} = {32'hFFFFFFFF, 32'd1, ALU_SLTU};
        check(32'd0);

        {op1, op2, alu_op} = {32'd1, 32'hFFFFFFFF, ALU_SLTU};
        check(32'd1);

        // Signed and unsigned should differ here
        {op1, op2, alu_op} = {32'h80000000, 32'd1, ALU_SLTU};
        check(32'd0);

        {op1, op2, alu_op} = {32'h80000000, 32'd1, ALU_SLT};
        check(32'd1);

        // ============================================================
        // PASS_B - result = op2, op1 ignored (used for LUI)
        // ============================================================

        {op1, op2, alu_op} = {32'hDEADBEEF, 32'h12345000, ALU_PASS_B};
        check(32'h12345000);

        {op1, op2, alu_op} = {32'h00000000, 32'hFFFFF000, ALU_PASS_B};
        check(32'hFFFFF000);

        {op1, op2, alu_op} = {32'hFFFFFFFF, 32'h00000000, ALU_PASS_B};
        check(32'h00000000);

        // ============================================================
        // Done
        // ============================================================

        $display("ALL ALU TESTS PASSED");
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_alu);
    end
endmodule
