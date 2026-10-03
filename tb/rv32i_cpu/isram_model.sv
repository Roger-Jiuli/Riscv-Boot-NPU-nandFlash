module isram_model #(
    parameter int WORDS = 1024
)(
    input  logic        clk,

    input  logic        en,
    input  logic [31:0] addr,

    output logic [31:0] rdata
);

    logic [31:0] mem [0:WORDS-1];

    // ------------------------------------------------------------
    // Synchronous read
    //
    // en = 1:
    //   在上升沿采样addr
    //   rdata更新为对应word
    //
    // en = 0:
    //   rdata保持
    // ------------------------------------------------------------

    always_ff @(posedge clk) begin
        if (en)
            rdata <= mem[addr[31:2]];
    end

endmodule