module pipeline_control #(
    parameter logic [1:0] FLOW_NORMAL = 2'd0
)(
    input  logic       clk,
    input  logic       rst_n,

    // ============================================================
    // Hazard
    // ============================================================
    input  logic       load_use_hazard,

    // ============================================================
    // ID
    // ============================================================
    input  logic       id_valid,
    input  logic [1:0] id_ctrl_flow,

    // ============================================================
    // EX
    // redirect_valid = branch taken / JAL / JALR
    // ============================================================
    input  logic       redirect_valid,

    // ============================================================
    // MEM
    // ============================================================
    input  logic       mem_stall,

    // ============================================================
    // Pipeline control
    // ============================================================
    output logic       pc_en,

    output logic       if_id_en,
    output logic       if_id_flush,

    output logic       id_ex_en,
    output logic       id_ex_flush,

    output logic       ex_mem_en,
    output logic       ex_mem_flush,

    output logic       mem_wb_en,
    output logic       mem_wb_flush
);


    // ============================================================
    // Redirect refill state
    //
    // redirect发生后：
    //
    // cycle N:
    //      PC <- redirect_pc
    //
    // cycle N+1:
    //      pc_en    = 1
    //      if_id_en = 0
    //      发出target地址
    //
    // cycle N+2:
    //      恢复正常流水
    // ============================================================

    logic redirect_refill_q;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            redirect_refill_q <= 1'b0;
        end
        else begin

            // MEM stall 时整个前端冻结
            // refill 状态也必须保留
            if (mem_stall) begin
                redirect_refill_q <= redirect_refill_q;
            end

            // redirect 发生
            else if (redirect_valid) begin
                redirect_refill_q <= 1'b1;
            end

            // redirect 后第一拍完成
            else if (redirect_refill_q) begin
                redirect_refill_q <= 1'b0;
            end

        end
    end


    // ============================================================
    // Pipeline control
    // ============================================================

    always_comb begin

        // --------------------------------------------------------
        // Default : normal advance
        // --------------------------------------------------------

        pc_en        = 1'b1;

        if_id_en     = 1'b1;
        if_id_flush  = 1'b0;

        id_ex_en     = 1'b1;
        id_ex_flush  = 1'b0;

        ex_mem_en    = 1'b1;
        ex_mem_flush = 1'b0;

        mem_wb_en    = 1'b1;
        mem_wb_flush = 1'b0;


        // ========================================================
        // Priority 1 : MEM stall
        //
        // MEM不能前进：
        //   EX/MEM以及所有上游全部HOLD
        //   MEM/WB排空成Bubble
        // ========================================================

        if (mem_stall) begin

            pc_en        = 1'b0;

            if_id_en     = 1'b0;
            if_id_flush  = 1'b0;

            id_ex_en     = 1'b0;
            id_ex_flush  = 1'b0;

            ex_mem_en    = 1'b0;
            ex_mem_flush = 1'b0;

            mem_wb_en    = 1'b1;
            mem_wb_flush = 1'b1;

        end


        // ========================================================
        // Priority 2 : Redirect
        //
        // EX确认：
        //   Branch taken
        //   JAL
        //   JALR
        //
        // PC由if_stage中的redirect逻辑修改
        // 本拍不能继续发旧PC请求
        // ========================================================

        else if (redirect_valid) begin

            pc_en        = 1'b0;

            if_id_en     = 1'b0;
            if_id_flush  = 1'b1;

            // 正常让EX中的跳转指令离开
            // ID本来应该是Bubble
            id_ex_en     = 1'b1;
            id_ex_flush  = 1'b0;

            ex_mem_en    = 1'b1;
            ex_mem_flush = 1'b0;

            mem_wb_en    = 1'b1;
            mem_wb_flush = 1'b0;

        end


        // ========================================================
        // Priority 3 : Redirect refill
        //
        // redirect后的第一拍：
        //
        // PC已经是target
        // 现在允许IF1向ISRAM发target地址
        //
        // 但是同步SRAM的新数据还没回来，
        // 所以IF/ID不能ENABLE
        // ========================================================

        else if (redirect_refill_q) begin

            pc_en        = 1'b1;

            if_id_en     = 1'b0;
            if_id_flush  = 1'b1;

            id_ex_en     = 1'b1;
            id_ex_flush  = 1'b0;

            ex_mem_en    = 1'b1;
            ex_mem_flush = 1'b0;

            mem_wb_en    = 1'b1;
            mem_wb_flush = 1'b0;

        end


        // ========================================================
        // Priority 4 : Load-use hazard
        //
        // ID中的指令HOLD
        // EX中的load正常进入MEM
        // ID/EX插Bubble
        // ========================================================

        else if (load_use_hazard) begin

            pc_en        = 1'b0;

            if_id_en     = 1'b0;
            if_id_flush  = 1'b0;

            id_ex_en     = 1'b1;
            id_ex_flush  = 1'b1;

            ex_mem_en    = 1'b1;
            ex_mem_flush = 1'b0;

            mem_wb_en    = 1'b1;
            mem_wb_flush = 1'b0;

        end


        // ========================================================
        // Priority 5 : ID detects control-flow instruction
        //
        // Branch/JAL/JALR进入EX
        //
        // 停止IF1
        // IF/ID中的控制流指令已经被消费，所以flush
        //
        // imem_rdata中的下一条顺序指令暂时保留
        // ========================================================

        else if (id_valid &&
                 (id_ctrl_flow != FLOW_NORMAL)) begin

            pc_en        = 1'b0;

            if_id_en     = 1'b0;
            if_id_flush  = 1'b1;

            // 控制流指令正常进入EX
            id_ex_en     = 1'b1;
            id_ex_flush  = 1'b0;

            ex_mem_en    = 1'b1;
            ex_mem_flush = 1'b0;

            mem_wb_en    = 1'b1;
            mem_wb_flush = 1'b0;

        end

    end

endmodule