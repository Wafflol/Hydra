module branch_unit (
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,
    input logic [2:0] funct3,
    output logic taken
);

    logic eq, lt, ltu;

    assign eq = (rs1_data == rs2_data);
    assign lt = ($signed(rs1_data) < $signed(rs2_data));
    assign ltu = (rs1_data < rs2_data);

    always_comb begin
        case (funct3)
            3'b000: taken = eq;
            3'b001: taken = ~eq;
            3'b100: taken = lt;
            3'b101: taken = ~lt;
            3'b110: taken = ltu;
            3'b111: taken = ~ltu;
            default: taken = 1'b0;
        endcase
    end
endmodule
