module mem_stage (
    input  logic        clk,
    input  logic        rst_n,

    // ============================================================
    // EX/MEM
    // ============================================================
    input  logic        ex_mem_valid,

    input  logic [31:0] ex_mem_alu_result,
    input  logic [31:0] ex_mem_store_data,
    input  logic [31:0] ex_mem_pc4,

    input  logic [4:0]  ex_mem_rd,
    input  logic [2:0]  ex_mem_funct3,

    input  logic        ex_mem_mem_read,
    input  logic        ex_mem_mem_write,

    input  logic        ex_mem_reg_write,
    input  logic [1:0]  ex_mem_wb_sel,


    // ============================================================
    // Data memory / SoC data interface
    // ============================================================
    output logic        dmem_read,
    output logic        dmem_write,

    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic [3:0]  dmem_wstrb,

    input  logic [31:0] dmem_rdata,
    input  logic        dmem_ready,


    // ============================================================
    // Pipeline control
    // ============================================================
    output logic        mem_stall,
    output logic        hold_forward,

    input  logic        mem_wb_en,
    input  logic        mem_wb_flush,


    // ============================================================
    // MEM/WB
    // ============================================================
    output logic        mem_wb_valid,

    output logic [31:0] mem_wb_alu_result,
    output logic [31:0] mem_wb_load_data,
    output logic [31:0] mem_wb_pc4,

    output logic [4:0]  mem_wb_rd,

    output logic        mem_wb_reg_write,
    output logic [1:0]  mem_wb_wb_sel
);


    // ============================================================
    // Store Unit
    // ============================================================

    logic [31:0] store_wdata;
    logic [3:0]  store_wstrb;

    store_unit u_store_unit (
        .addr       (ex_mem_alu_result),
        .funct3     (ex_mem_funct3),
        .store_data (ex_mem_store_data),

        .wdata      (store_wdata),
        .wstrb      (store_wstrb)
    );


    // ============================================================
    // Load Unit
    // ============================================================

    logic [31:0] load_data;

    load_unit u_load_unit (
        .addr      (ex_mem_alu_result),
        .funct3    (ex_mem_funct3),
        .rdata     (dmem_rdata),

        .load_data (load_data)
    );


    // ============================================================
    // Data Interface
    // ============================================================

    assign dmem_addr  = ex_mem_alu_result;

    assign dmem_read  =
        ex_mem_valid && ex_mem_mem_read;

    assign dmem_write =
        ex_mem_valid && ex_mem_mem_write;

    assign dmem_wdata = store_wdata;
    assign dmem_wstrb = store_wstrb;


    // ============================================================
    // MEM Stall
    // ============================================================

    logic mem_access;

    assign mem_access =
        ex_mem_valid &&
        (ex_mem_mem_read || ex_mem_mem_write);

    assign mem_stall =
        mem_access && !dmem_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            hold_forward <= 1'b0;
        else if (mem_stall && ex_mem_valid)
            hold_forward <= 1'b1;
        else if (mem_wb_valid)
            hold_forward <= 1'b0;
    end


    // ============================================================
    // MEM/WB Pipeline Register
    //
    // RESET > FLUSH > ENABLE > HOLD
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            mem_wb_valid      <= 1'b0;

            mem_wb_alu_result <= 32'b0;
            mem_wb_load_data  <= 32'b0;
            mem_wb_pc4        <= 32'b0;

            mem_wb_rd         <= 5'b0;

            mem_wb_reg_write  <= 1'b0;
            mem_wb_wb_sel     <= 2'b0;

        end
        else if (mem_wb_flush) begin

            mem_wb_valid <= 1'b0;

        end
        else if (mem_wb_en) begin

            mem_wb_valid      <= ex_mem_valid;

            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_load_data  <= load_data;
            mem_wb_pc4        <= ex_mem_pc4;

            mem_wb_rd         <= ex_mem_rd;

            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_wb_sel     <= ex_mem_wb_sel;

        end

        // else HOLD

    end

endmodule