module wb_stage (

    // ============================================================
    // MEM/WB
    // ============================================================
    input  logic        mem_wb_valid,

    input  logic [31:0] mem_wb_alu_result,
    input  logic [31:0] mem_wb_load_data,
    input  logic [31:0] mem_wb_pc4,

    input  logic [4:0]  mem_wb_rd,

    input  logic        mem_wb_reg_write,
    input  logic [1:0]  mem_wb_wb_sel,


    // ============================================================
    // WB -> RegFile
    // ============================================================
    output logic        wb_we,
    output logic [4:0]  wb_rd,
    output logic [31:0] wb_data
);


    localparam logic [1:0]
        WB_ALU = 2'd0,
        WB_MEM = 2'd1,
        WB_PC4 = 2'd2;


    // ============================================================
    // Write-back data mux
    // ============================================================

    always_comb begin

        case (mem_wb_wb_sel)

            WB_ALU:
                wb_data = mem_wb_alu_result;

            WB_MEM:
                wb_data = mem_wb_load_data;

            WB_PC4:
                wb_data = mem_wb_pc4;

            default:
                wb_data = 32'b0;

        endcase

    end


    // ============================================================
    // Register File write interface
    // ============================================================

    assign wb_rd = mem_wb_rd;

    assign wb_we =
        mem_wb_valid &&
        mem_wb_reg_write &&
        (mem_wb_rd != 5'd0);

endmodule