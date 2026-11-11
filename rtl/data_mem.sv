module data_mem #(parameter WORDS = 1024) (
    input logic clk,
    input logic [3:0] we,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    output logic [31:0] rdata
);

    logic [3:0][7:0] mem [WORDS];

    always_ff @(posedge clk) begin
        for (int i = 0; i < 4; i++)
            if (we[i]) mem[addr[$clog2(WORDS)+1:2]][i] <= wdata[i*8 +: 8];
        rdata <= mem[addr[$clog2(WORDS)+1:2]];
    end
endmodule
