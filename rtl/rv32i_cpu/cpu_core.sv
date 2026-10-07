module cpu_core #(
    parameter logic [31:0] RESET_PC = 32'h0000_0000
)(
    input  logic        clk,
    input  logic        rst_n,

    // ============================================================
    // Instruction SRAM
    // ============================================================
    output logic        imem_en,
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,

    // ============================================================
    // Data Memory
    // ============================================================
    output logic        dmem_read,
    output logic        dmem_write,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic [3:0]  dmem_wstrb,

    input  logic [31:0] dmem_rdata,
    input  logic        dmem_ready
);

    // ============================================================
    // Encoding
    // ============================================================

    localparam logic [1:0]
        WB_ALU = 2'd0,
        WB_MEM = 2'd1,
        WB_PC4 = 2'd2;

    localparam logic [1:0]
        FLOW_NORMAL = 2'd0;


    // ============================================================
    // Pipeline control
    // ============================================================

    logic pc_en;

    logic if_id_en;
    logic if_id_flush;

    logic id_ex_en;
    logic id_ex_flush;

    logic ex_mem_en;
    logic ex_mem_flush;

    logic mem_wb_en;
    logic mem_wb_flush;


    // ============================================================
    // IF/ID
    // ============================================================

    logic        if_id_valid;
    logic [31:0] if_id_pc;
    logic [31:0] if_id_instr;


    // ============================================================
    // ID hazard information
    // ============================================================

    logic [4:0] id_rs1;
    logic [4:0] id_rs2;

    logic       id_use_rs1;
    logic       id_use_rs2;

    logic [1:0] id_ctrl_flow;


    // ============================================================
    // ID/EX
    // ============================================================

    logic        id_ex_valid;

    logic [31:0] id_ex_pc;
    logic [31:0] id_ex_rs1_data;
    logic [31:0] id_ex_rs2_data;

    logic [4:0]  id_ex_rs1;
    logic [4:0]  id_ex_rs2;
    logic [4:0]  id_ex_rd;

    logic [31:0] id_ex_imm;
    logic [2:0]  id_ex_funct3;

    logic        id_ex_use_rs1;
    logic        id_ex_use_rs2;

    logic [3:0]  id_ex_alu_op;
    logic [1:0]  id_ex_alu_src_a;
    logic        id_ex_alu_src_b;

    logic        id_ex_mem_read;
    logic        id_ex_mem_write;

    logic        id_ex_reg_write;
    logic [1:0]  id_ex_wb_sel;

    logic [1:0]  id_ex_ctrl_flow;


    // ============================================================
    // EX/MEM
    // ============================================================

    logic        ex_mem_valid;

    logic [31:0] ex_mem_alu_result;
    logic [31:0] ex_mem_store_data;
    logic [31:0] ex_mem_pc4;

    logic [4:0]  ex_mem_rd;
    logic [2:0]  ex_mem_funct3;

    logic        ex_mem_mem_read;
    logic        ex_mem_mem_write;

    logic        ex_mem_reg_write;
    logic [1:0]  ex_mem_wb_sel;


    // ============================================================
    // MEM/WB
    // ============================================================

    logic        mem_wb_valid;

    logic [31:0] mem_wb_alu_result;
    logic [31:0] mem_wb_load_data;
    logic [31:0] mem_wb_pc4;

    logic [4:0]  mem_wb_rd;

    logic        mem_wb_reg_write;
    logic [1:0]  mem_wb_wb_sel;


    // ============================================================
    // WB
    // ============================================================

    logic        wb_we;
    logic [4:0]  wb_rd;
    logic [31:0] wb_data;


    // ============================================================
    // Hazard / Forwarding / Redirect / MEM stall
    // ============================================================

    logic load_use_hazard;

    logic        redirect_valid;
    logic [31:0] redirect_pc;

    logic        mem_stall;
    logic        hold_forward;

    logic [31:0] mem_forward_data;


    // ============================================================
    // IF
    // ============================================================

    if_stage #(
        .RESET_PC (RESET_PC)
    ) u_if_stage (
        .clk            (clk),
        .rst_n          (rst_n),

        .pc_en          (pc_en),

        .if_id_en       (if_id_en),
        .if_id_flush    (if_id_flush),

        .redirect_valid (redirect_valid),
        .redirect_pc    (redirect_pc),

        .imem_en        (imem_en),
        .imem_addr      (imem_addr),
        .imem_rdata     (imem_rdata),

        .if_id_valid    (if_id_valid),
        .if_id_pc       (if_id_pc),
        .if_id_instr    (if_id_instr)
    );


    // ============================================================
    // ID
    // ============================================================

    id_stage u_id_stage (
        .clk              (clk),
        .rst_n            (rst_n),

        .if_id_valid      (if_id_valid),
        .if_id_pc         (if_id_pc),
        .if_id_instr      (if_id_instr),

        .id_ex_en         (id_ex_en),
        .id_ex_flush      (id_ex_flush),

        // WB -> RegFile
        .wb_we            (wb_we),
        .wb_rd            (wb_rd),
        .wb_data          (wb_data),

        // Hazard information
        .id_rs1           (id_rs1),
        .id_rs2           (id_rs2),
        .id_use_rs1       (id_use_rs1),
        .id_use_rs2       (id_use_rs2),
        .id_ctrl_flow     (id_ctrl_flow),

        // ID/EX
        .id_ex_valid      (id_ex_valid),

        .id_ex_pc         (id_ex_pc),
        .id_ex_rs1_data   (id_ex_rs1_data),
        .id_ex_rs2_data   (id_ex_rs2_data),

        .id_ex_rs1        (id_ex_rs1),
        .id_ex_rs2        (id_ex_rs2),
        .id_ex_rd         (id_ex_rd),

        .id_ex_imm        (id_ex_imm),
        .id_ex_funct3     (id_ex_funct3),

        .id_ex_use_rs1    (id_ex_use_rs1),
        .id_ex_use_rs2    (id_ex_use_rs2),

        .id_ex_alu_op     (id_ex_alu_op),
        .id_ex_alu_src_a  (id_ex_alu_src_a),
        .id_ex_alu_src_b  (id_ex_alu_src_b),

        .id_ex_mem_read   (id_ex_mem_read),
        .id_ex_mem_write  (id_ex_mem_write),

        .id_ex_reg_write  (id_ex_reg_write),
        .id_ex_wb_sel     (id_ex_wb_sel),

        .id_ex_ctrl_flow  (id_ex_ctrl_flow)
    );


    // ============================================================
    // Load-use hazard detection
    // ============================================================

    hazard_unit u_hazard_unit (
        .id_valid        (if_id_valid),

        .id_rs1          (id_rs1),
        .id_rs2          (id_rs2),

        .id_use_rs1      (id_use_rs1),
        .id_use_rs2      (id_use_rs2),

        .ex_valid        (id_ex_valid),
        .ex_mem_read     (id_ex_mem_read),
        .ex_rd           (id_ex_rd),

        .load_use_hazard (load_use_hazard)
    );


    // ============================================================
    // EX/MEM forwarding data
    //
    // Load不能从EX/MEM forward；
    // forwarding_unit内部会根据WB_MEM排除。
    // ============================================================

    assign mem_forward_data =
        (ex_mem_wb_sel == WB_PC4)
            ? ex_mem_pc4
            : ex_mem_alu_result;


    // ============================================================
    // EX
    // ============================================================

    ex_stage u_ex_stage (
        .clk               (clk),
        .rst_n             (rst_n),

        // ID/EX
        .id_ex_valid       (id_ex_valid),

        .id_ex_pc          (id_ex_pc),
        .id_ex_rs1_data    (id_ex_rs1_data),
        .id_ex_rs2_data    (id_ex_rs2_data),

        .id_ex_rs1         (id_ex_rs1),
        .id_ex_rs2         (id_ex_rs2),
        .id_ex_rd          (id_ex_rd),

        .id_ex_imm         (id_ex_imm),
        .id_ex_funct3      (id_ex_funct3),

        .id_ex_use_rs1     (id_ex_use_rs1),
        .id_ex_use_rs2     (id_ex_use_rs2),

        .id_ex_alu_op      (id_ex_alu_op),
        .id_ex_alu_src_a   (id_ex_alu_src_a),
        .id_ex_alu_src_b   (id_ex_alu_src_b),

        .id_ex_mem_read    (id_ex_mem_read),
        .id_ex_mem_write   (id_ex_mem_write),

        .id_ex_reg_write   (id_ex_reg_write),
        .id_ex_wb_sel      (id_ex_wb_sel),

        .id_ex_ctrl_flow   (id_ex_ctrl_flow),

        // EX/MEM forwarding
        .mem_valid         (ex_mem_valid),
        .mem_reg_write     (ex_mem_reg_write),
        .mem_rd            (ex_mem_rd),
        .mem_wb_sel        (ex_mem_wb_sel),
        .mem_forward_data  (mem_forward_data),
        .hold_forward      (hold_forward),

        // MEM/WB forwarding
        .wb_valid          (mem_wb_valid),
        .wb_reg_write      (mem_wb_reg_write),
        .wb_rd             (mem_wb_rd),
        .wb_data           (wb_data),

        // Pipeline control
        .ex_mem_en         (ex_mem_en),
        .ex_mem_flush      (ex_mem_flush),

        // Redirect
        .redirect_valid    (redirect_valid),
        .redirect_pc       (redirect_pc),

        // EX/MEM
        .ex_mem_valid      (ex_mem_valid),

        .ex_mem_alu_result (ex_mem_alu_result),
        .ex_mem_store_data (ex_mem_store_data),
        .ex_mem_pc4        (ex_mem_pc4),

        .ex_mem_rd         (ex_mem_rd),
        .ex_mem_funct3     (ex_mem_funct3),

        .ex_mem_mem_read   (ex_mem_mem_read),
        .ex_mem_mem_write  (ex_mem_mem_write),

        .ex_mem_reg_write  (ex_mem_reg_write),
        .ex_mem_wb_sel     (ex_mem_wb_sel)
    );


    // ============================================================
    // MEM
    // ============================================================

    mem_stage u_mem_stage (
        .clk               (clk),
        .rst_n             (rst_n),

        // EX/MEM
        .ex_mem_valid      (ex_mem_valid),

        .ex_mem_alu_result (ex_mem_alu_result),
        .ex_mem_store_data (ex_mem_store_data),
        .ex_mem_pc4        (ex_mem_pc4),

        .ex_mem_rd         (ex_mem_rd),
        .ex_mem_funct3     (ex_mem_funct3),

        .ex_mem_mem_read   (ex_mem_mem_read),
        .ex_mem_mem_write  (ex_mem_mem_write),

        .ex_mem_reg_write  (ex_mem_reg_write),
        .ex_mem_wb_sel     (ex_mem_wb_sel),

        // Data memory
        .dmem_read         (dmem_read),
        .dmem_write        (dmem_write),

        .dmem_addr         (dmem_addr),
        .dmem_wdata        (dmem_wdata),
        .dmem_wstrb        (dmem_wstrb),

        .dmem_rdata        (dmem_rdata),
        .dmem_ready        (dmem_ready),

        // Pipeline control
        .mem_wb_en         (mem_wb_en),
        .mem_wb_flush      (mem_wb_flush),

        .mem_stall         (mem_stall),
        .hold_forward      (hold_forward),

        // MEM/WB
        .mem_wb_valid      (mem_wb_valid),

        .mem_wb_alu_result (mem_wb_alu_result),
        .mem_wb_load_data  (mem_wb_load_data),
        .mem_wb_pc4        (mem_wb_pc4),

        .mem_wb_rd         (mem_wb_rd),

        .mem_wb_reg_write  (mem_wb_reg_write),
        .mem_wb_wb_sel     (mem_wb_wb_sel)
    );


    // ============================================================
    // WB
    // ============================================================

    wb_stage u_wb_stage (
        .mem_wb_valid      (mem_wb_valid),

        .mem_wb_alu_result (mem_wb_alu_result),
        .mem_wb_load_data  (mem_wb_load_data),
        .mem_wb_pc4        (mem_wb_pc4),

        .mem_wb_rd         (mem_wb_rd),

        .mem_wb_reg_write  (mem_wb_reg_write),
        .mem_wb_wb_sel     (mem_wb_wb_sel),

        .wb_we             (wb_we),
        .wb_rd             (wb_rd),
        .wb_data           (wb_data)
    );


    // ============================================================
    // Pipeline Control
    // ============================================================

    pipeline_control #(
        .FLOW_NORMAL (FLOW_NORMAL)
    ) u_pipeline_control (
        .clk             (clk),
        .rst_n           (rst_n),

        .load_use_hazard (load_use_hazard),

        .id_valid        (if_id_valid),
        .id_ctrl_flow    (id_ctrl_flow),

        .redirect_valid  (redirect_valid),

        .mem_stall       (mem_stall),

        .pc_en           (pc_en),

        .if_id_en        (if_id_en),
        .if_id_flush     (if_id_flush),

        .id_ex_en        (id_ex_en),
        .id_ex_flush     (id_ex_flush),

        .ex_mem_en       (ex_mem_en),
        .ex_mem_flush    (ex_mem_flush),

        .mem_wb_en       (mem_wb_en),
        .mem_wb_flush    (mem_wb_flush)
    );

endmodule