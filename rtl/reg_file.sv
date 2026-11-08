module reg_file (
    input logic clk,
    input logic reg_write,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic [31:0] wr_data,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

    logic [31:0] regs[0:31];

    always_comb begin : rd_data
        rs1_data = rs1 == 5'd0 ? '0 : rs1 == rd && reg_write == 1 ? wr_data : regs[rs1];
        rs2_data = rs2 == 5'd0 ? '0 : rs2 == rd && reg_write == 1 ? wr_data : regs[rs2];
    end

    always_ff @(posedge clk) begin : write
        if (reg_write && rd != 5'd0) begin
            regs[rd] <= wr_data;
        end
    end
endmodule
