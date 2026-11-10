module tb_reg_file ();
    logic clk, reg_write, rst_n;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] wr_data, rs1_data, rs2_data;

    reg_file reg_file (.*);

    initial clk = 0;
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        reg_write = 0;
        rs1 = 0;
        rs2 = 0;
        rd = 0;
        wr_data = 0;
        rst_n = 0;

        @(posedge clk);
        rst_n = 1;

        // Write x1 = 42
        @(posedge clk);
        reg_write = 1;
        rd = 5'd1;
        wr_data = 32'd42;

        // Write x2 = 100
        @(posedge clk);
        rd = 5'd2;
        wr_data = 32'd100;

        // Stop writing
        @(posedge clk);
        reg_write = 0;

        // Read x1 and x2
        rs1 = 5'd1;
        rs2 = 5'd2;

        repeat (2) @(posedge clk);

        // Read x0
        rs1 = 5'd0;
        rs2 = 5'd0;

        repeat (2) @(posedge clk);

        // ---------------- Internal bypass tests ----------------
        // Inputs change on negedge and are checked before the next posedge,
        // so the write hasn't landed in regs[] yet. Any new value seen on
        // the read port must have come through the bypass.

        // Case 1: write x3 and read x3 in the same cycle -> new value
        @(negedge clk);
        reg_write = 1;
        rd = 5'd3;
        wr_data = 32'hDEAD_BEEF;
        rs1 = 5'd3;
        rs2 = 5'd3;
        #1;
        assert (rs1_data == 32'hDEAD_BEEF)
        else $error("bypass: rs1_data = %h, expected deadbeef", rs1_data);
        assert (rs2_data == 32'hDEAD_BEEF)
        else $error("bypass: rs2_data = %h, expected deadbeef", rs2_data);

        // Case 2: rd matches rs1 but reg_write = 0 -> no bypass, old value
        @(negedge clk);
        reg_write = 0;
        rd = 5'd1;
        wr_data = 32'hBAD0_BAD0;
        rs1 = 5'd1;
        rs2 = 5'd1;
        #1;
        assert (rs1_data == 32'd42)
        else $error("no-write bypass: rs1_data = %h, expected 0000002a", rs1_data);
        assert (rs2_data == 32'd42)
        else $error("no-write bypass: rs2_data = %h, expected 0000002a", rs2_data);

        // Case 3: write to x0 while reading x0 -> must still read 0
        @(negedge clk);
        reg_write = 1;
        rd = 5'd0;
        wr_data = 32'hFFFF_FFFF;
        rs1 = 5'd0;
        rs2 = 5'd0;
        #1;
        assert (rs1_data == 32'd0)
        else $error("x0 bypass: rs1_data = %h, expected 0", rs1_data);
        assert (rs2_data == 32'd0)
        else $error("x0 bypass: rs2_data = %h, expected 0", rs2_data);

        @(negedge clk);
        reg_write = 0;

        repeat (2) @(posedge clk);
        $display("ALL REG FILE TESTS PASSED");
        $finish;
    end

    // assert property (rs1_data == reg_file.regs[rs1]);
    // assert property (rs2_data == reg_file.regs[rs2]);
    always_comb begin
        if (rs1 != rd) begin
            assert (rs1_data == reg_file.regs[rs1])
            else $error("rs1_data mismatch");
        end
        if (rs2 != rd) begin
            assert (rs2_data == reg_file.regs[rs2])
            else $error("rs2_data mismatch");
        end
    end

    property p_reg_write;
        @(posedge clk) disable iff (~rst_n) (reg_write && rd != 0) |-> ##1 (reg_file.regs[$past(rd)] == $past(wr_data));
    endproperty

    assert property (p_reg_write);

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_reg_file);
    end
endmodule
