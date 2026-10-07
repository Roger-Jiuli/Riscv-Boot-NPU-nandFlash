// ============================================================
// forwarding_test.svh
//
// Purpose:
//   Verify forwarding logic of RV32I CPU.
//
// Coverage:
//   Case 1 : EX/MEM -> forward_a
//   Case 2 : MEM/WB -> forward_a
//   Case 3 : EX/MEM -> forward_b
//   Case 4 : MEM/WB -> forward_b
//   Case 5 : forward_a = MEM/WB, forward_b = EX/MEM
//   Case 6 : EX/MEM and MEM/WB both match -> EX/MEM priority
//
// Also check:
//   - No unexpected DMEM access
//   - No load-use hazard
//   - No redirect
//   - Final architectural register values
//   - Total execution cycles
//
// Forward encoding:
//   2'b00 : NONE
//   2'b01 : MEM/WB -> EX
//   2'b10 : EX/MEM -> EX
// ============================================================


// ============================================================
// Test State
// ============================================================

localparam int EXPECTED_CYCLES = 21;

integer wb_count;
integer actual_cycles;

logic test_done;

logic case1_checked;
logic case2_checked;
logic case3_checked;
logic case4_checked;
logic case5_checked;
logic case6_checked;


// ============================================================
// Forwarding / Control Checker
//
// Pipeline registers update at posedge.
// Check combinational signals at negedge after they settle.
// ============================================================

always @(negedge clk) begin
    if (rst_n && u_cpu.id_ex_valid) begin

        // ====================================================
        // Case 1
        //
        // addi x1, x0, 10
        // addi x2, x1, 1
        //
        // When x2 is in EX:
        //
        // EX/MEM : x1
        // EX     : addi x2,x1,1
        //
        // Expected:
        //   forward_a = EX/MEM
        //   forward_b = NONE
        // ====================================================

        if ((u_cpu.id_ex_rd      == 5'd2) &&
            (u_cpu.id_ex_rs1     == 5'd1) &&
            (u_cpu.id_ex_use_rs1 == 1'b1)) begin

            case1_checked = 1'b1;

            if (u_cpu.u_ex_stage.forward_a !== 2'b10) begin
                $error(
                    "[CASE1] forward_a expected EX/MEM(10), got %b",
                    u_cpu.u_ex_stage.forward_a
                );
                errors++;
            end

            if (u_cpu.u_ex_stage.forward_b !== 2'b00) begin
                $error(
                    "[CASE1] forward_b expected NONE(00), got %b",
                    u_cpu.u_ex_stage.forward_b
                );
                errors++;
            end
        end


        // ====================================================
        // Case 2
        //
        // addi x3, x0, 30
        // nop
        // addi x4, x3, 1
        //
        // When x4 is in EX:
        //
        // MEM/WB : x3
        //
        // Expected:
        //   forward_a = MEM/WB
        //   forward_b = NONE
        // ====================================================

        if ((u_cpu.id_ex_rd      == 5'd4) &&
            (u_cpu.id_ex_rs1     == 5'd3) &&
            (u_cpu.id_ex_use_rs1 == 1'b1)) begin

            case2_checked = 1'b1;

            if (u_cpu.u_ex_stage.forward_a !== 2'b01) begin
                $error(
                    "[CASE2] forward_a expected MEM/WB(01), got %b",
                    u_cpu.u_ex_stage.forward_a
                );
                errors++;
            end

            if (u_cpu.u_ex_stage.forward_b !== 2'b00) begin
                $error(
                    "[CASE2] forward_b expected NONE(00), got %b",
                    u_cpu.u_ex_stage.forward_b
                );
                errors++;
            end
        end


        // ====================================================
        // Case 3
        //
        // addi x5, x0, 50
        // add  x6, x0, x5
        //
        // When x6 is in EX:
        //
        // EX/MEM : x5
        //
        // Expected:
        //   forward_a = NONE
        //   forward_b = EX/MEM
        // ====================================================

        if ((u_cpu.id_ex_rd      == 5'd6) &&
            (u_cpu.id_ex_rs1     == 5'd0) &&
            (u_cpu.id_ex_rs2     == 5'd5) &&
            (u_cpu.id_ex_use_rs2 == 1'b1)) begin

            case3_checked = 1'b1;

            if (u_cpu.u_ex_stage.forward_a !== 2'b00) begin
                $error(
                    "[CASE3] forward_a expected NONE(00), got %b",
                    u_cpu.u_ex_stage.forward_a
                );
                errors++;
            end

            if (u_cpu.u_ex_stage.forward_b !== 2'b10) begin
                $error(
                    "[CASE3] forward_b expected EX/MEM(10), got %b",
                    u_cpu.u_ex_stage.forward_b
                );
                errors++;
            end
        end


        // ====================================================
        // Case 4
        //
        // addi x7, x0, 70
        // nop
        // add  x8, x0, x7
        //
        // When x8 is in EX:
        //
        // MEM/WB : x7
        //
        // Expected:
        //   forward_a = NONE
        //   forward_b = MEM/WB
        // ====================================================

        if ((u_cpu.id_ex_rd      == 5'd8) &&
            (u_cpu.id_ex_rs1     == 5'd0) &&
            (u_cpu.id_ex_rs2     == 5'd7) &&
            (u_cpu.id_ex_use_rs2 == 1'b1)) begin

            case4_checked = 1'b1;

            if (u_cpu.u_ex_stage.forward_a !== 2'b00) begin
                $error(
                    "[CASE4] forward_a expected NONE(00), got %b",
                    u_cpu.u_ex_stage.forward_a
                );
                errors++;
            end

            if (u_cpu.u_ex_stage.forward_b !== 2'b01) begin
                $error(
                    "[CASE4] forward_b expected MEM/WB(01), got %b",
                    u_cpu.u_ex_stage.forward_b
                );
                errors++;
            end
        end


        // ====================================================
        // Case 5
        //
        // addi x9,  x0, 90
        // addi x10, x0, 100
        // add  x11, x9, x10
        //
        // When x11 is in EX:
        //
        // MEM/WB : x9
        // EX/MEM : x10
        //
        // Expected:
        //   forward_a = MEM/WB
        //   forward_b = EX/MEM
        // ====================================================

        if ((u_cpu.id_ex_rd      == 5'd11) &&
            (u_cpu.id_ex_rs1     == 5'd9)  &&
            (u_cpu.id_ex_rs2     == 5'd10) &&
            (u_cpu.id_ex_use_rs1 == 1'b1)  &&
            (u_cpu.id_ex_use_rs2 == 1'b1)) begin

            case5_checked = 1'b1;

            if (u_cpu.u_ex_stage.forward_a !== 2'b01) begin
                $error(
                    "[CASE5] forward_a expected MEM/WB(01), got %b",
                    u_cpu.u_ex_stage.forward_a
                );
                errors++;
            end

            if (u_cpu.u_ex_stage.forward_b !== 2'b10) begin
                $error(
                    "[CASE5] forward_b expected EX/MEM(10), got %b",
                    u_cpu.u_ex_stage.forward_b
                );
                errors++;
            end
        end


        // ====================================================
        // Case 6
        //
        // addi x12, x0,  1
        // addi x12, x12, 1
        // addi x12, x12, 1
        //
        // When third instruction is in EX:
        //
        // MEM/WB : older x12 = 1
        // EX/MEM : newer x12 = 2
        //
        // Both match rs1=x12.
        //
        // EX/MEM MUST have higher priority.
        //
        // Expected:
        //   forward_a = EX/MEM
        // ====================================================

        if ((u_cpu.id_ex_rd         == 5'd12) &&
            (u_cpu.id_ex_rs1        == 5'd12) &&
             u_cpu.id_ex_use_rs1              &&

             u_cpu.ex_mem_valid               &&
             u_cpu.ex_mem_reg_write           &&
            (u_cpu.ex_mem_rd == 5'd12)        &&

             u_cpu.mem_wb_valid               &&
             u_cpu.mem_wb_reg_write           &&
            (u_cpu.mem_wb_rd == 5'd12)) begin

            case6_checked = 1'b1;

            if (u_cpu.u_ex_stage.forward_a !== 2'b10) begin
                $error(
                    "[CASE6] Priority error: expected EX/MEM(10), got %b",
                    u_cpu.u_ex_stage.forward_a
                );
                errors++;
            end

            if (u_cpu.u_ex_stage.forward_b !== 2'b00) begin
                $error(
                    "[CASE6] forward_b expected NONE(00), got %b",
                    u_cpu.u_ex_stage.forward_b
                );
                errors++;
            end
        end


        // ====================================================
        // Forbidden Behavior
        // ====================================================

        if (dmem_read || dmem_write) begin
            $error(
                "[FORWARD] Unexpected DMEM access: read=%b write=%b",
                dmem_read,
                dmem_write
            );
            errors++;
        end

        if (u_cpu.load_use_hazard) begin
            $error("[FORWARD] Unexpected load-use hazard");
            errors++;
        end

        if (u_cpu.redirect_valid) begin
            $error("[FORWARD] Unexpected redirect");
            errors++;
        end
    end
end


// ============================================================
// WB + Performance Monitor
//
// Check at negedge:
//   - wb signals are stable
//   - cycle_count has already been updated at previous posedge
// ============================================================

always @(posedge clk) begin
    if (rst_n && u_cpu.wb_we) begin

        wb_count++;

        // ----------------------------------------------------
        // There are exactly 14 architectural register writes
        // before the final target instruction completes.
        // ----------------------------------------------------

        if ((wb_count == 14) && !test_done) begin

            actual_cycles = cycle_count + 1;
            test_done     = 1'b1;

            if (actual_cycles !== EXPECTED_CYCLES) begin
                $error(
                    "[CYCLE] Expected %0d cycles, actual %0d cycles",
                    EXPECTED_CYCLES,
                    actual_cycles
                );
                errors++;
            end
            else begin
                $display(
                    "[CYCLE] PASS: expected=%0d actual=%0d",
                    EXPECTED_CYCLES,
                    actual_cycles
                );
            end
        end
    end
end


// ============================================================
// Main Test
// ============================================================

initial begin

    // ========================================================
    // Initialization
    // ========================================================

    rst_n         = 1'b0;

    errors        = 0;
    wb_count      = 0;
    actual_cycles = 0;
    test_done     = 1'b0;

    case1_checked = 1'b0;
    case2_checked = 1'b0;
    case3_checked = 1'b0;
    case4_checked = 1'b0;
    case5_checked = 1'b0;
    case6_checked = 1'b0;


    // ========================================================
    // Program
    // ========================================================


    // --------------------------------------------------------
    // Case 1
    // EX/MEM -> A
    // --------------------------------------------------------

    u_isram.mem[0] = 32'h00A00093; // addi x1,x0,10
    u_isram.mem[1] = 32'h00108113; // addi x2,x1,1
                                      // x2 = 11


    // --------------------------------------------------------
    // Case 2
    // MEM/WB -> A
    // --------------------------------------------------------

    u_isram.mem[2] = 32'h01E00193; // addi x3,x0,30
    u_isram.mem[3] = 32'h00000013; // nop
    u_isram.mem[4] = 32'h00118213; // addi x4,x3,1
                                      // x4 = 31


    // --------------------------------------------------------
    // Case 3
    // EX/MEM -> B
    // --------------------------------------------------------

    u_isram.mem[5] = 32'h03200293; // addi x5,x0,50
    u_isram.mem[6] = 32'h00500333; // add x6,x0,x5
                                      // x6 = 50


    // --------------------------------------------------------
    // Case 4
    // MEM/WB -> B
    // --------------------------------------------------------

    u_isram.mem[7] = 32'h04600393; // addi x7,x0,70
    u_isram.mem[8] = 32'h00000013; // nop
    u_isram.mem[9] = 32'h00700433; // add x8,x0,x7
                                      // x8 = 70


    // --------------------------------------------------------
    // Case 5
    //
    // A <- MEM/WB
    // B <- EX/MEM
    // --------------------------------------------------------

    u_isram.mem[10] = 32'h05A00493; // addi x9,x0,90
    u_isram.mem[11] = 32'h06400513; // addi x10,x0,100
    u_isram.mem[12] = 32'h00A485B3; // add x11,x9,x10
                                       // x11 = 190


    // --------------------------------------------------------
    // Case 6
    //
    // EX/MEM vs MEM/WB priority
    // --------------------------------------------------------

    u_isram.mem[13] = 32'h00100613; // addi x12,x0,1
    u_isram.mem[14] = 32'h00160613; // addi x12,x12,1
                                       // x12 = 2

    u_isram.mem[15] = 32'h00160613; // addi x12,x12,1
                                       // x12 = 3


    // --------------------------------------------------------
    // Fill remaining ISRAM with NOP
    // --------------------------------------------------------

    for (int i = 16; i < 64; i++)
        u_isram.mem[i] = 32'h00000013;


    // ========================================================
    // Release Reset
    // ========================================================

    #20;
    rst_n = 1'b1;


    // ========================================================
    // Wait for final architectural WB
    // ========================================================

    wait (test_done == 1'b1);

    // Move away from the checker edge before final checks
    @(posedge clk);
    #1;


    // ========================================================
    // Architectural State Check
    // ========================================================

    check_reg(1,  32'd10);
    check_reg(2,  32'd11);

    check_reg(3,  32'd30);
    check_reg(4,  32'd31);

    check_reg(5,  32'd50);
    check_reg(6,  32'd50);

    check_reg(7,  32'd70);
    check_reg(8,  32'd70);

    check_reg(9,  32'd90);
    check_reg(10, 32'd100);
    check_reg(11, 32'd190);

    check_reg(12, 32'd3);


    // ========================================================
    // Coverage Check
    //
    // Prevent false PASS if a target instruction was never
    // actually observed by the checker.
    // ========================================================

    if (!case1_checked) begin
        $error("[FORWARD] Case1 EX/MEM -> A was not checked");
        errors++;
    end

    if (!case2_checked) begin
        $error("[FORWARD] Case2 MEM/WB -> A was not checked");
        errors++;
    end

    if (!case3_checked) begin
        $error("[FORWARD] Case3 EX/MEM -> B was not checked");
        errors++;
    end

    if (!case4_checked) begin
        $error("[FORWARD] Case4 MEM/WB -> B was not checked");
        errors++;
    end

    if (!case5_checked) begin
        $error("[FORWARD] Case5 A/B simultaneous forwarding was not checked");
        errors++;
    end

    if (!case6_checked) begin
        $error("[FORWARD] Case6 forwarding priority was not checked");
        errors++;
    end


    // ========================================================
    // WB Count Check
    // ========================================================

    if (wb_count != 14) begin
        $error(
            "[FORWARD] Expected 14 architectural WB, got %0d",
            wb_count
        );
        errors++;
    end


    // ========================================================
    // Performance Summary
    // ========================================================

    $display(
        "[FORWARD] Execution cycles: expected=%0d actual=%0d",
        EXPECTED_CYCLES,
        actual_cycles
    );


    // ========================================================
    // Final Result
    // ========================================================

    report_result("FORWARDING TEST");

    $finish;
end