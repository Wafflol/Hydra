module program_counter (
    input logic clk,
    input logic rst_n,
    input logic en,
    input logic [31:0] pc_next,
    output logic [31:0] pc
);

    always_ff @(posedge clk) begin
        if (!rst_n) pc <= 32'd0;
        else if (en) pc <= pc_next;
    end
endmodule
