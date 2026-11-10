module tb_branch_unit();
    import cpu_types::*;

    logic [31:0] rs1_data, rs2_data;
    logic [2:0] funct3;
    logic taken;

    branch_unit branch_unit(.*);

    task automatic check(input logic [31:0] a, input logic [31:0] b,
                         input logic [2:0] f3, input logic expected);
        rs1_data = a;
        rs2_data = b;
        funct3 = f3;
        #1;
        assert (taken == expected)
        else $error("rs1=%h rs2=%h funct3=%b taken=%b expected=%b", a, b, f3, taken, expected);
    endtask

    initial begin
        // ========================================================================
        // rs1_data = 5, rs2_data = 5
        // ========================================================================
        check(5, 5, 3'b000, 1);
        check(5, 5, 3'b001, 0);
        check(5, 5, 3'b100, 0);
        check(5, 5, 3'b101, 1);
        check(5, 5, 3'b110, 0);
        check(5, 5, 3'b111, 1);

        // ========================================================================
        // rs1_data = 5, rs2_data = 6
        // ========================================================================
        check(5, 6, 3'b000, 0);
        check(5, 6, 3'b001, 1);
        check(5, 6, 3'b100, 1);
        check(5, 6, 3'b101, 0);
        check(5, 6, 3'b110, 1);
        check(5, 6, 3'b111, 0);

        // ========================================================================
        // rs1_data = 6, rs2_data = 5
        // ========================================================================
        check(6, 5, 3'b000, 0);
        check(6, 5, 3'b001, 1);
        check(6, 5, 3'b100, 0);
        check(6, 5, 3'b101, 1);
        check(6, 5, 3'b110, 0);
        check(6, 5, 3'b111, 1);

        // ========================================================================
        // rs1_data = 32'hFFFFFFFF, rs2_data = 1
        // ========================================================================
        check(32'hFFFFFFFF, 1, 3'b000, 0);
        check(32'hFFFFFFFF, 1, 3'b001, 1);
        check(32'hFFFFFFFF, 1, 3'b100, 1);
        check(32'hFFFFFFFF, 1, 3'b101, 0);
        check(32'hFFFFFFFF, 1, 3'b110, 0);
        check(32'hFFFFFFFF, 1, 3'b111, 1);

        // ========================================================================
        // rs1_data = 1, rs2_data = 32'hFFFFFFFF
        // ========================================================================
        check(1, 32'hFFFFFFFF, 3'b000, 0);
        check(1, 32'hFFFFFFFF, 3'b001, 1);
        check(1, 32'hFFFFFFFF, 3'b100, 0);
        check(1, 32'hFFFFFFFF, 3'b101, 1);
        check(1, 32'hFFFFFFFF, 3'b110, 1);
        check(1, 32'hFFFFFFFF, 3'b111, 0);

        // ========================================================================
        // rs1_data = 32'h80000000, rs2_data = 0
        // ========================================================================
        check(32'h80000000, 0, 3'b000, 0);
        check(32'h80000000, 0, 3'b001, 1);
        check(32'h80000000, 0, 3'b100, 1);
        check(32'h80000000, 0, 3'b101, 0);
        check(32'h80000000, 0, 3'b110, 0);
        check(32'h80000000, 0, 3'b111, 1);
        $display("ALL BRANCH UNIT TESTS PASSED");
        $finish;
    end
endmodule
