module regfile (
    input  logic        clk,
    input  logic        rst_n,

    // ==============================
    // Read Port 1
    // ==============================
    input  logic [4:0]  rs1_addr,
    output logic [31:0] rs1_data,

    // ==============================
    // Read Port 2
    // ==============================
    input  logic [4:0]  rs2_addr,
    output logic [31:0] rs2_data,

    // ==============================
    // Write Port
    // ==============================
    input  logic        wb_we,
    input  logic [4:0]  wb_rd,
    input  logic [31:0] wb_data
);

    logic [31:0] regs [0:31];


    // ============================================================
    // Write
    // x0 永远不能被修改
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            integer i;

            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end
        else begin
            if (wb_we && (wb_rd != 5'd0))
                regs[wb_rd] <= wb_data;
        end
    end


    // ============================================================
    // Read
    // combinational read
    //
    // 同拍 WB -> ID bypass
    // ============================================================

    always_comb begin

        // rs1
        if (rs1_addr == 5'd0)
            rs1_data = 32'b0;
        else if (wb_we && (wb_rd == rs1_addr) && (wb_rd != 5'd0))
            rs1_data = wb_data;
        else
            rs1_data = regs[rs1_addr];


        // rs2
        if (rs2_addr == 5'd0)
            rs2_data = 32'b0;
        else if (wb_we && (wb_rd == rs2_addr) && (wb_rd != 5'd0))
            rs2_data = wb_data;
        else
            rs2_data = regs[rs2_addr];

    end

endmodule