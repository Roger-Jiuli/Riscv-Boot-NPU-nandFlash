module decoder (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,

    output logic       use_rs1,
    output logic       use_rs2,

    output logic [3:0] alu_op,
    output logic [1:0] alu_src_a,
    output logic       alu_src_b,

    output logic [2:0] imm_sel,

    output logic       mem_read,
    output logic       mem_write,

    output logic       reg_write,
    output logic [1:0] wb_sel,

    output logic [1:0] ctrl_flow
);


    // ============================================================
    // ALU Operation
    // ============================================================

    localparam logic [3:0]
        ALU_ADD  = 4'd0,
        ALU_SUB  = 4'd1,
        ALU_SLL  = 4'd2,
        ALU_SLT  = 4'd3,
        ALU_SLTU = 4'd4,
        ALU_XOR  = 4'd5,
        ALU_SRL  = 4'd6,
        ALU_SRA  = 4'd7,
        ALU_OR   = 4'd8,
        ALU_AND  = 4'd9;


    // ============================================================
    // ALU Source A
    // ============================================================

    localparam logic [1:0]
        SRC_A_RS1  = 2'd0,
        SRC_A_PC   = 2'd1,
        SRC_A_ZERO = 2'd2;


    // ============================================================
    // ALU Source B
    // ============================================================

    localparam logic
        SRC_B_RS2 = 1'b0,
        SRC_B_IMM = 1'b1;


    // ============================================================
    // Immediate Type
    // ============================================================

    localparam logic [2:0]
        IMM_I = 3'd0,
        IMM_S = 3'd1,
        IMM_B = 3'd2,
        IMM_U = 3'd3,
        IMM_J = 3'd4;


    // ============================================================
    // Write Back Source
    // ============================================================

    localparam logic [1:0]
        WB_ALU = 2'd0,
        WB_MEM = 2'd1,
        WB_PC4 = 2'd2;


    // ============================================================
    // Control Flow
    // ============================================================

    localparam logic [1:0]
        FLOW_NORMAL = 2'd0,
        FLOW_BRANCH = 2'd1,
        FLOW_JAL    = 2'd2,
        FLOW_JALR   = 2'd3;


    // ============================================================
    // Main Decoder
    // ============================================================

    always_comb begin

        // --------------------------------------------------------
        // Default
        // --------------------------------------------------------

        use_rs1   = 1'b0;
        use_rs2   = 1'b0;

        alu_op    = ALU_ADD;
        alu_src_a = SRC_A_RS1;
        alu_src_b = SRC_B_RS2;

        imm_sel   = IMM_I;

        mem_read  = 1'b0;
        mem_write = 1'b0;

        reg_write = 1'b0;
        wb_sel    = WB_ALU;

        ctrl_flow = FLOW_NORMAL;


        case (opcode)

            // ====================================================
            // R-Type
            //
            // ADD SUB SLL SLT SLTU XOR SRL SRA OR AND
            // ====================================================

            7'b0110011: begin

                use_rs1   = 1'b1;
                use_rs2   = 1'b1;

                alu_src_a = SRC_A_RS1;
                alu_src_b = SRC_B_RS2;

                reg_write = 1'b1;
                wb_sel    = WB_ALU;

                case (funct3)

                    3'b000:
                        if (funct7[5])
                            alu_op = ALU_SUB;
                        else
                            alu_op = ALU_ADD;

                    3'b001: alu_op = ALU_SLL;
                    3'b010: alu_op = ALU_SLT;
                    3'b011: alu_op = ALU_SLTU;
                    3'b100: alu_op = ALU_XOR;

                    3'b101:
                        if (funct7[5])
                            alu_op = ALU_SRA;
                        else
                            alu_op = ALU_SRL;

                    3'b110: alu_op = ALU_OR;
                    3'b111: alu_op = ALU_AND;

                    default: alu_op = ALU_ADD;

                endcase
            end


            // ====================================================
            // I-Type ALU
            //
            // ADDI SLTI SLTIU XORI ORI ANDI
            // SLLI SRLI SRAI
            // ====================================================

            7'b0010011: begin

                use_rs1   = 1'b1;

                alu_src_a = SRC_A_RS1;
                alu_src_b = SRC_B_IMM;

                imm_sel   = IMM_I;

                reg_write = 1'b1;
                wb_sel    = WB_ALU;

                case (funct3)

                    3'b000: alu_op = ALU_ADD;   // ADDI
                    3'b010: alu_op = ALU_SLT;   // SLTI
                    3'b011: alu_op = ALU_SLTU;  // SLTIU
                    3'b100: alu_op = ALU_XOR;   // XORI
                    3'b110: alu_op = ALU_OR;    // ORI
                    3'b111: alu_op = ALU_AND;   // ANDI
                    3'b001: alu_op = ALU_SLL;   // SLLI

                    3'b101:
                        if (funct7[5])
                            alu_op = ALU_SRA;    // SRAI
                        else
                            alu_op = ALU_SRL;    // SRLI

                    default: alu_op = ALU_ADD;

                endcase
            end


            // ====================================================
            // LOAD
            //
            // LB LH LW LBU LHU
            // ====================================================

            7'b0000011: begin

                use_rs1   = 1'b1;

                alu_op    = ALU_ADD;
                alu_src_a = SRC_A_RS1;
                alu_src_b = SRC_B_IMM;

                imm_sel   = IMM_I;

                mem_read  = 1'b1;

                reg_write = 1'b1;
                wb_sel    = WB_MEM;

            end


            // ====================================================
            // STORE
            //
            // SB SH SW
            // ====================================================

            7'b0100011: begin

                use_rs1   = 1'b1;
                use_rs2   = 1'b1;

                alu_op    = ALU_ADD;
                alu_src_a = SRC_A_RS1;
                alu_src_b = SRC_B_IMM;

                imm_sel   = IMM_S;

                mem_write = 1'b1;

            end


            // ====================================================
            // BRANCH
            //
            // BEQ BNE BLT BGE BLTU BGEU
            // ====================================================

            7'b1100011: begin

                use_rs1   = 1'b1;
                use_rs2   = 1'b1;

                alu_op    = ALU_ADD;
                alu_src_a = SRC_A_PC;
                alu_src_b = SRC_B_IMM;

                imm_sel   = IMM_B;

                ctrl_flow = FLOW_BRANCH;

            end


            // ====================================================
            // JAL
            // ====================================================

            7'b1101111: begin

                alu_op    = ALU_ADD;
                alu_src_a = SRC_A_PC;
                alu_src_b = SRC_B_IMM;

                imm_sel   = IMM_J;

                reg_write = 1'b1;
                wb_sel    = WB_PC4;

                ctrl_flow = FLOW_JAL;

            end


            // ====================================================
            // JALR
            // ====================================================

            7'b1100111: begin

                use_rs1   = 1'b1;

                alu_op    = ALU_ADD;
                alu_src_a = SRC_A_RS1;
                alu_src_b = SRC_B_IMM;

                imm_sel   = IMM_I;

                reg_write = 1'b1;
                wb_sel    = WB_PC4;

                ctrl_flow = FLOW_JALR;

            end


            // ====================================================
            // LUI
            //
            // rd = imm
            // ZERO + imm
            // ====================================================

            7'b0110111: begin

                alu_op    = ALU_ADD;
                alu_src_a = SRC_A_ZERO;
                alu_src_b = SRC_B_IMM;

                imm_sel   = IMM_U;

                reg_write = 1'b1;
                wb_sel    = WB_ALU;

            end


            // ====================================================
            // AUIPC
            //
            // rd = PC + imm
            // ====================================================

            7'b0010111: begin

                alu_op    = ALU_ADD;
                alu_src_a = SRC_A_PC;
                alu_src_b = SRC_B_IMM;

                imm_sel   = IMM_U;

                reg_write = 1'b1;
                wb_sel    = WB_ALU;

            end


            default: begin
                // 保持默认控制信号
            end

        endcase

    end

endmodule