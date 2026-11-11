// Runs sw/basic.S (built into prog.hex by `make prog`) and checks the
// final register and memory values listed in that file's comments.
module tb_datapath ();
    logic clk = 0, rst_n = 0, en = 1;
    always #5 clk = ~clk;

    datapath dut(.*);

    task automatic check_reg(input int r, input logic [31:0] expected);
        assert (dut.reg_file.regs[r] === expected)
        else $error("x%0d = %h, expected %h", r, dut.reg_file.regs[r], expected);
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst_n = 1;
        repeat (60) @(posedge clk);

        // ========================================================================
        // ALU instructions
        // ========================================================================
        check_reg(1, 32'd5);            // addi
        check_reg(2, 32'd7);            // addi
        check_reg(3, 32'd12);           // add
        check_reg(4, 32'd2);            // sub
        check_reg(5, 32'h12345000);     // lui
        check_reg(6, 32'h00000028);     // auipc: its own PC
        check_reg(7, 32'hFFFFFFFF);     // addi with a negative immediate
        check_reg(9, 32'd1);            // slt:  -1 < 0 signed
        check_reg(10, 32'd0);           // sltu: 0xFFFFFFFF > 5 unsigned

        // ========================================================================
        // Memory
        // ========================================================================
        check_reg(8, 32'd12);           // lw reads back what sw wrote
        assert (dut.dmem.mem[4] === 32'd12)   // byte address 16 = word 4
        else $error("mem[16] = %h, expected 0000000c", dut.dmem.mem[4]);

        // ========================================================================
        // Branches and jumps
        // ========================================================================
        check_reg(11, 32'd0);           // beq jumped over the addi
        check_reg(12, 32'h00000058);    // jal return address
        check_reg(13, 32'd0);           // jal jumped over the addi
        check_reg(14, 32'd42);          // jal landed on the target

        // x0 must stay 0
        check_reg(0, 32'd0);

        $display("ALL DATAPATH TESTS PASSED");
        $finish;
    end
endmodule
