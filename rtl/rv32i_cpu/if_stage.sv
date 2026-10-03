module if_stage #(
    parameter logic [31:0] RESET_PC = 32'h0000_0000
)(
    input  logic        clk,
    input  logic        rst_n,

    // ==============================
    // Pc control
    // ==============================
    input  logic        pc_en,

    // ==============================
    // Pipeline control
    // ==============================
    input  logic        if_id_en,
    input  logic        if_id_flush,

    // ==============================
    // Redirect from EX
    // ==============================
    input  logic        redirect_valid,
    input  logic [31:0] redirect_pc,

    // ==============================
    // Instruction SRAM
    // synchronous read, 1-cycle latency
    // ==============================
    output logic        imem_en,
    output logic [31:0] imem_addr,

    input  logic [31:0] imem_rdata,

    // ==============================
    // IF2 -> ID
    // ==============================
    output logic        if_id_valid,
    output logic [31:0] if_id_pc,
    output logic [31:0] if_id_instr
);


    // ============================================================
    // IF1
    // ============================================================

    logic [31:0] pc;

    // 记录上一拍发给 ISRAM 的 PC
    logic [31:0] if1_pc_q;

    assign imem_addr = pc;

    // 只有 IF 能继续前进时，才发新的取指
    assign imem_en = pc_en;


    // ============================================================
    // PC
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= RESET_PC;
        end
        else if (redirect_valid) begin
            pc <= redirect_pc;
        end
        else if (pc_en) begin
            pc <= pc + 32'd4;
        end
    end


    // ============================================================
    // IF1 -> IF2 metadata
    //
    // ISRAM 数据下一拍返回，所以必须把本拍 PC 保存下来
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if1_pc_q    <= 32'b0;
        end
        else begin
            if (imem_en)
                if1_pc_q <= imem_addr;
        end
    end


    // ============================================================
    // IF2 -> ID pipeline register
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_id_valid <= 1'b0;
            if_id_pc    <= 32'b0;
            if_id_instr <= 32'b0;
        end
        else if (if_id_flush) begin
            if_id_valid <= 1'b0;
        end
        else if (if_id_en) begin
            if_id_valid <= 1;

            if_id_pc    <= if1_pc_q;
            if_id_instr <= imem_rdata;
        end
    end

endmodule