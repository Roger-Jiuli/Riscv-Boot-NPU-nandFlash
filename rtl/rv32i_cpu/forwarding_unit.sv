module forwarding_unit (

    // ============================================================
    // Current instruction in EX
    // ============================================================
    input  logic       ex_valid,

    input  logic [4:0] ex_rs1,
    input  logic [4:0] ex_rs2,

    input  logic       ex_use_rs1,
    input  logic       ex_use_rs2,


    // ============================================================
    // Instruction in EX/MEM
    // ============================================================
    input  logic       mem_valid,
    input  logic       mem_reg_write,
    input  logic [4:0] mem_rd,
    input  logic [1:0] mem_wb_sel,


    // ============================================================
    // Instruction in MEM/WB
    // ============================================================
    input  logic       wb_valid,
    input  logic       wb_reg_write,
    input  logic [4:0] wb_rd,


    // ============================================================
    // Forward select
    // ============================================================
    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);


    localparam logic [1:0]
        WB_ALU = 2'd0,
        WB_MEM = 2'd1,
        WB_PC4 = 2'd2;

    localparam logic [1:0]
        FWD_NONE = 2'b00,
        FWD_WB   = 2'b01,
        FWD_MEM  = 2'b10;


    always_comb begin

        forward_a = FWD_NONE;
        forward_b = FWD_NONE;


        // ========================================================
        // rs1 forwarding
        // Priority:
        // EX/MEM > MEM/WB
        // ========================================================

        if (ex_valid && ex_use_rs1) begin

            if (
                mem_valid &&
                mem_reg_write &&
                (mem_rd != 5'd0) &&
                (mem_rd == ex_rs1) &&

                // EX/MEM里的Load数据此时还没准备好
                (mem_wb_sel != WB_MEM)
            ) begin

                forward_a = FWD_MEM;

            end
            else if (
                wb_valid &&
                wb_reg_write &&
                (wb_rd != 5'd0) &&
                (wb_rd == ex_rs1)
            ) begin

                forward_a = FWD_WB;

            end

        end


        // ========================================================
        // rs2 forwarding
        // ========================================================

        if (ex_valid && ex_use_rs2) begin

            if (
                mem_valid &&
                mem_reg_write &&
                (mem_rd != 5'd0) &&
                (mem_rd == ex_rs2) &&
                (mem_wb_sel != WB_MEM)
            ) begin

                forward_b = FWD_MEM;

            end
            else if (
                wb_valid &&
                wb_reg_write &&
                (wb_rd != 5'd0) &&
                (wb_rd == ex_rs2)
            ) begin

                forward_b = FWD_WB;

            end

        end

    end

endmodule