module id_stage (
    input  logic        clk,
    input  logic        rst_n,

    // ============================================================
    // IF/ID -> ID
    // ============================================================
    input  logic        if_id_valid,
    input  logic [31:0] if_id_pc,
    input  logic [31:0] if_id_instr,

    // ============================================================
    // ID/EX pipeline control
    // ============================================================
    input  logic        id_ex_en,
    input  logic        id_ex_flush,

    // ============================================================
    // WB -> RegFile
    // ============================================================
    input  logic        wb_we,
    input  logic [4:0]  wb_rd,
    input  logic [31:0] wb_data,

    // ============================================================
    // ID information for Hazard / Pipeline Control
    // ============================================================
    output logic [4:0]  id_rs1,
    output logic [4:0]  id_rs2,
    output logic        id_use_rs1,
    output logic        id_use_rs2,
    output logic [1:0]  id_ctrl_flow,

    // ============================================================
    // ID/EX
    // ============================================================
    output logic        id_ex_valid,

    output logic [31:0] id_ex_pc,

    output logic [31:0] id_ex_rs1_data,
    output logic [31:0] id_ex_rs2_data,

    output logic [4:0]  id_ex_rs1,
    output logic [4:0]  id_ex_rs2,
    output logic [4:0]  id_ex_rd,

    output logic [31:0] id_ex_imm,
    output logic [2:0]  id_ex_funct3,

    output logic        id_ex_use_rs1,
    output logic        id_ex_use_rs2,

    output logic [3:0]  id_ex_alu_op,
    output logic [1:0]  id_ex_alu_src_a,
    output logic        id_ex_alu_src_b,

    output logic        id_ex_mem_read,
    output logic        id_ex_mem_write,

    output logic        id_ex_reg_write,
    output logic [1:0]  id_ex_wb_sel,

    output logic [1:0]  id_ex_ctrl_flow
);


    // ============================================================
    // Instruction fields
    // ============================================================

    logic [6:0] opcode;
    logic [4:0] rd;
    logic [2:0] funct3;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [6:0] funct7;

    assign opcode = if_id_instr[6:0];
    assign rd     = if_id_instr[11:7];
    assign funct3 = if_id_instr[14:12];
    assign rs1    = if_id_instr[19:15];
    assign rs2    = if_id_instr[24:20];
    assign funct7 = if_id_instr[31:25];


    // ============================================================
    // Decoder outputs
    // ============================================================

    logic       dec_use_rs1;
    logic       dec_use_rs2;

    logic [3:0] dec_alu_op;
    logic [1:0] dec_alu_src_a;
    logic       dec_alu_src_b;

    logic [2:0] dec_imm_sel;

    logic       dec_mem_read;
    logic       dec_mem_write;

    logic       dec_reg_write;
    logic [1:0] dec_wb_sel;

    logic [1:0] dec_ctrl_flow;


    decoder u_decoder (
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),

        .use_rs1    (dec_use_rs1),
        .use_rs2    (dec_use_rs2),

        .alu_op     (dec_alu_op),
        .alu_src_a  (dec_alu_src_a),
        .alu_src_b  (dec_alu_src_b),

        .imm_sel    (dec_imm_sel),

        .mem_read   (dec_mem_read),
        .mem_write  (dec_mem_write),

        .reg_write  (dec_reg_write),
        .wb_sel     (dec_wb_sel),

        .ctrl_flow  (dec_ctrl_flow)
    );


    // ============================================================
    // Register File
    // ============================================================

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    regfile u_regfile (
        .clk       (clk),
        .rst_n     (rst_n),

        .rs1_addr  (rs1),
        .rs1_data  (rs1_data),

        .rs2_addr  (rs2),
        .rs2_data  (rs2_data),

        .wb_we     (wb_we),
        .wb_rd     (wb_rd),
        .wb_data   (wb_data)
    );


    // ============================================================
    // Immediate Generator
    // ============================================================

    logic [31:0] imm;

    imm_gen u_imm_gen (
        .instr   (if_id_instr),
        .imm_sel (dec_imm_sel),
        .imm     (imm)
    );


    // ============================================================
    // Information exposed to Hazard / Pipeline Control
    // ============================================================

    assign id_rs1       = rs1;
    assign id_rs2       = rs2;
    assign id_use_rs1   = dec_use_rs1;
    assign id_use_rs2   = dec_use_rs2;
    assign id_ctrl_flow = dec_ctrl_flow;


    // ============================================================
    // ID/EX Pipeline Register
    //
    // Priority:
    // RESET > FLUSH > ENABLE > HOLD
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            id_ex_valid     <= 1'b0;

            id_ex_pc        <= 32'b0;

            id_ex_rs1_data  <= 32'b0;
            id_ex_rs2_data  <= 32'b0;

            id_ex_rs1       <= 5'b0;
            id_ex_rs2       <= 5'b0;
            id_ex_rd        <= 5'b0;

            id_ex_imm       <= 32'b0;
            id_ex_funct3    <= 3'b0;

            id_ex_use_rs1   <= 1'b0;
            id_ex_use_rs2   <= 1'b0;

            id_ex_alu_op    <= 4'b0;
            id_ex_alu_src_a <= 2'b0;
            id_ex_alu_src_b <= 1'b0;

            id_ex_mem_read  <= 1'b0;
            id_ex_mem_write <= 1'b0;

            id_ex_reg_write <= 1'b0;
            id_ex_wb_sel    <= 2'b0;

            id_ex_ctrl_flow <= 2'b0;

        end
        else if (id_ex_flush) begin

            // Bubble
            id_ex_valid <= 1'b0;

        end
        else if (id_ex_en) begin

            // ----------------------------------------------------
            // Instruction identity
            // ----------------------------------------------------

            id_ex_valid <= if_id_valid;
            id_ex_pc    <= if_id_pc;

            // ----------------------------------------------------
            // Register operands
            // ----------------------------------------------------

            id_ex_rs1_data <= rs1_data;
            id_ex_rs2_data <= rs2_data;

            id_ex_rs1 <= rs1;
            id_ex_rs2 <= rs2;
            id_ex_rd  <= rd;

            // ----------------------------------------------------
            // Immediate / funct3
            // ----------------------------------------------------

            id_ex_imm    <= imm;
            id_ex_funct3 <= funct3;

            // ----------------------------------------------------
            // Hazard information
            // ----------------------------------------------------

            id_ex_use_rs1 <= dec_use_rs1;
            id_ex_use_rs2 <= dec_use_rs2;

            // ----------------------------------------------------
            // EX control
            // ----------------------------------------------------

            id_ex_alu_op    <= dec_alu_op;
            id_ex_alu_src_a <= dec_alu_src_a;
            id_ex_alu_src_b <= dec_alu_src_b;

            // ----------------------------------------------------
            // MEM control
            // ----------------------------------------------------

            id_ex_mem_read  <= dec_mem_read;
            id_ex_mem_write <= dec_mem_write;

            // ----------------------------------------------------
            // WB control
            // ----------------------------------------------------

            id_ex_reg_write <= dec_reg_write;
            id_ex_wb_sel    <= dec_wb_sel;

            // ----------------------------------------------------
            // Control flow
            // ----------------------------------------------------

            id_ex_ctrl_flow <= dec_ctrl_flow;

        end

        // else:
        // id_ex_en = 0
        // HOLD

    end

endmodule