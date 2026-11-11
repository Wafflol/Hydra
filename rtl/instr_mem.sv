module instr_mem #(parameter WORDS = 1024, parameter INIT = "prog.hex") (
    input logic clk,
    input logic [31:0] addr,
    output logic [31:0] instr
);

    logic [31:0] mem [WORDS];
    initial $readmemh(INIT, mem);

    always_ff @(posedge clk) begin
        instr <= mem[addr[$clog2(WORDS)+1:2]];
    end
endmodule
