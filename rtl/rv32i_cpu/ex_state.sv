module ex_stage (
    input  logic        clk,
    input  logic        rst_n,

    // ============================================================
    // ID/EX
    // ============================================================
    input  logic        id_ex_valid,
    input  logic [31:0] id_ex_pc,

    input  logic [31:0] id_ex_rs1_data,
    input  logic [31:0] id_ex_rs2_data,

    input  logic [4:0]  id_ex_rs1,
    input  logic [4:0]  id_ex_rs2,
    input  logic [4:0]  id_ex_rd,

    input  logic [31:0] id_ex_imm,
    input  logic [2:0]  id_ex_funct3,

    input  logic        id_ex_use_rs1,
    input  logic        id_ex_use_rs2,

    input  logic [3:0]  id_ex_alu_op,
    input  logic [1:0]  id_ex_alu_src_a,
    input  logic        id_ex_alu_src_b,

    input  logic        id_ex_mem_read,
    input  logic        id_ex_mem_write,

    input  logic        id_ex_reg_write,
    input  logic [1:0]  id_ex_wb_sel,

    input  logic [1:0]  id_ex_ctrl_flow,


    // ============================================================
    // Pipeline control
    // ============================================================
    input  logic        ex_mem_en,
    input  logic        ex_mem_flush,


    // ============================================================
    // EX/MEM information used for forwarding
    // ============================================================
    input  logic        mem_valid,
    input  logic        mem_reg_write,
    input  logic [4:0]  mem_rd,
    input  logic [1:0]  mem_wb_sel,
    input  logic [31:0] mem_forward_data,


    // ============================================================
    // MEM/WB information used for forwarding
    // ============================================================
    input  logic        wb_valid,
    input  logic        wb_reg_write,
    input  logic [4:0]  wb_rd,
    input  logic [31:0] wb_data,


    // ============================================================
    // Redirect
    // ============================================================
    output logic        redirect_valid,
    output logic [31:0] redirect_pc,


    // ============================================================
    // EX/MEM
    // ============================================================
    output logic        ex_mem_valid,

    output logic [31:0] ex_mem_alu_result,
    output logic [31:0] ex_mem_store_data,
    output logic [31:0] ex_mem_pc4,

    output logic [4:0]  ex_mem_rd,
    output logic [2:0]  ex_mem_funct3,

    output logic        ex_mem_mem_read,
    output logic        ex_mem_mem_write,

    output logic        ex_mem_reg_write,
    output logic [1:0]  ex_mem_wb_sel
);


    localparam logic [1:0]
        SRC_A_RS1  = 2'd0,
        SRC_A_PC   = 2'd1,
        SRC_A_ZERO = 2'd2;

    localparam logic
        SRC_B_RS2 = 1'b0,
        SRC_B_IMM = 1'b1;

    localparam logic [1:0]
        FLOW_NORMAL = 2'd0,
        FLOW_BRANCH = 2'd1,
        FLOW_JAL    = 2'd2,
        FLOW_JALR   = 2'd3;

    localparam logic [1:0]
        FWD_NONE = 2'b00,
        FWD_WB   = 2'b01,
        FWD_MEM  = 2'b10;


    // ============================================================
    // Forwarding Unit
    // ============================================================

    logic [1:0] forward_a;
    logic [1:0] forward_b;

    forwarding_unit u_forwarding_unit (
        .ex_valid      (id_ex_valid),

        .ex_rs1        (id_ex_rs1),
        .ex_rs2        (id_ex_rs2),
        .ex_use_rs1    (id_ex_use_rs1),
        .ex_use_rs2    (id_ex_use_rs2),

        .mem_valid     (mem_valid),
        .mem_reg_write (mem_reg_write),
        .mem_rd        (mem_rd),
        .mem_wb_sel    (mem_wb_sel),

        .wb_valid      (wb_valid),
        .wb_reg_write  (wb_reg_write),
        .wb_rd         (wb_rd),

        .forward_a     (forward_a),
        .forward_b     (forward_b)
    );


    // ============================================================
    // Forwarded register operands
    // ============================================================

    logic [31:0] src1_fwd;
    logic [31:0] src2_fwd;

    always_comb begin

        case (forward_a)
            FWD_MEM:  src1_fwd = mem_forward_data;
            FWD_WB:   src1_fwd = wb_data;
            default:  src1_fwd = id_ex_rs1_data;
        endcase

        case (forward_b)
            FWD_MEM:  src2_fwd = mem_forward_data;
            FWD_WB:   src2_fwd = wb_data;
            default:  src2_fwd = id_ex_rs2_data;
        endcase

    end


    // ============================================================
    // ALU input mux
    // ============================================================

    logic [31:0] alu_a;
    logic [31:0] alu_b;

    always_comb begin

        case (id_ex_alu_src_a)
            SRC_A_RS1:  alu_a = src1_fwd;
            SRC_A_PC:   alu_a = id_ex_pc;
            SRC_A_ZERO: alu_a = 32'b0;
            default:    alu_a = 32'b0;
        endcase

        case (id_ex_alu_src_b)
            SRC_B_RS2: alu_b = src2_fwd;
            SRC_B_IMM: alu_b = id_ex_imm;
            default:   alu_b = 32'b0;
        endcase

    end


    // ============================================================
    // ALU
    // ============================================================

    logic [31:0] alu_result;

    alu u_alu (
        .a      (alu_a),
        .b      (alu_b),
        .alu_op (id_ex_alu_op),
        .result (alu_result)
    );


    // ============================================================
    // Branch Comparator
    // ============================================================

    logic branch_taken;

    always_comb begin

        branch_taken = 1'b0;

        case (id_ex_funct3)

            3'b000:
                branch_taken = (src1_fwd == src2_fwd);   // BEQ

            3'b001:
                branch_taken = (src1_fwd != src2_fwd);   // BNE

            3'b100:
                branch_taken =
                    ($signed(src1_fwd) < $signed(src2_fwd)); // BLT

            3'b101:
                branch_taken =
                    ($signed(src1_fwd) >= $signed(src2_fwd)); // BGE

            3'b110:
                branch_taken = (src1_fwd < src2_fwd);    // BLTU

            3'b111:
                branch_taken = (src1_fwd >= src2_fwd);   // BGEU

            default:
                branch_taken = 1'b0;

        endcase

    end


    // ============================================================
    // Redirect
    // ============================================================

    always_comb begin

        redirect_valid = 1'b0;
        redirect_pc    = 32'b0;

        if (id_ex_valid && ex_mem_en) begin

            case (id_ex_ctrl_flow)

                FLOW_BRANCH: begin
                    if (branch_taken) begin
                        redirect_valid = 1'b1;

                        // Branch ALU已经计算 PC + imm
                        redirect_pc = alu_result;
                    end
                end

                FLOW_JAL: begin
                    redirect_valid = 1'b1;

                    // JAL ALU已经计算 PC + imm
                    redirect_pc = alu_result;
                end

                FLOW_JALR: begin
                    redirect_valid = 1'b1;

                    // RISC-V要求JALR清除bit 0
                    redirect_pc = alu_result & 32'hFFFF_FFFE;
                end

                default: begin
                    redirect_valid = 1'b0;
                end

            endcase

        end

    end


    // ============================================================
    // EX/MEM Pipeline Register
    //
    // RESET > FLUSH > ENABLE > HOLD
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            ex_mem_valid      <= 1'b0;

            ex_mem_alu_result <= 32'b0;
            ex_mem_store_data <= 32'b0;
            ex_mem_pc4        <= 32'b0;

            ex_mem_rd         <= 5'b0;
            ex_mem_funct3     <= 3'b0;

            ex_mem_mem_read   <= 1'b0;
            ex_mem_mem_write  <= 1'b0;

            ex_mem_reg_write  <= 1'b0;
            ex_mem_wb_sel     <= 2'b0;

        end
        else if (ex_mem_flush) begin

            ex_mem_valid <= 1'b0;

        end
        else if (ex_mem_en) begin

            ex_mem_valid      <= id_ex_valid;

            ex_mem_alu_result <= alu_result;

            // 注意：必须是Forward后的rs2
            ex_mem_store_data <= src2_fwd;

            ex_mem_pc4        <= id_ex_pc + 32'd4;

            ex_mem_rd         <= id_ex_rd;
            ex_mem_funct3     <= id_ex_funct3;

            ex_mem_mem_read   <= id_ex_mem_read;
            ex_mem_mem_write  <= id_ex_mem_write;

            ex_mem_reg_write  <= id_ex_reg_write;
            ex_mem_wb_sel     <= id_ex_wb_sel;

        end

        // else HOLD
    end

endmodule