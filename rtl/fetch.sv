module fetch (
    input logic clk,
    input logic rst_n,
    input logic en,
    input logic pc_src_e,
    input logic [31:0] alu_result_e,
    output logic [31:0] pc_f,
    output logic [31:0] pc_plus4_f,
    output logic [31:0] pc_next
);
    program_counter program_counter (
        .clk,
        .rst_n,
        .en,
        .pc_next,
        .pc(pc_f)
    );

    assign pc_plus4_f = pc_f + 32'd4;
    assign pc_next = ~rst_n   ? 32'd0 :
                     pc_src_e ? {alu_result_e[31:1], 1'b0} :
                     ~en      ? pc_f : pc_plus4_f;
endmodule
