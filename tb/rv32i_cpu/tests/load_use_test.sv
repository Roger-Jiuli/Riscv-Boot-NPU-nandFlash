// ============================================================
// load_use_test.sv
//
// Purpose:
//   Verify load-use hazard detection.
//
// Expected real load-use hazards:
//   1. LW -> ADD rs1
//   2. LW -> ADD rs2
//   3. LW -> SW  store data
//   4. LW -> BEQ compare operand
//
// Also verify NO false stall:
//   5. LW rd=x0
//   6. I-type raw rs2 field matches load rd, but use_rs2=0
//   7. Independent instruction
// ============================================================


localparam int EXPECTED_WB_COUNT   = 14;
localparam int EXPECTED_LOAD_STALL = 4;

// 17 instructions
//
// ideal:          17 + 5 = 22
// 8 DMEM accesses: 8 * 3 = 24
// load-use:                 + 4
// BEQ control bubble:       + 1
//
// total = 51
localparam int EXPECTED_CYCLES = 51;


logic [4:0]  expected_wb_rd   [0:EXPECTED_WB_COUNT-1];
logic [31:0] expected_wb_data [0:EXPECTED_WB_COUNT-1];

integer wb_idx;
integer load_stall_count;

logic test_done;
logic [31:0] actual_cycles;


// ============================================================
// Main test
// ============================================================

initial begin

    errors           = 0;
    wb_idx           = 0;
    load_stall_count = 0;
    test_done         = 1'b0;
    actual_cycles     = 0;

    rst_n = 1'b0;


    // ========================================================
    // Program
    // ========================================================

    // x1 = 0x80
    u_isram.mem[0] = 32'h08000093;
    // addi x1,x0,128


    // --------------------------------------------------------
    // CASE 1
    // LW -> ADD
    // rs1 dependency
    //
    // x2 = MEM[0x80] = 11
    // x3 = x2 + x0 = 11
    //
    // MUST stall exactly once
    // --------------------------------------------------------

    u_isram.mem[1] = 32'h0000A103;
    // lw x2,0(x1)

    u_isram.mem[2] = 32'h000101B3;
    // add x3,x2,x0


    // --------------------------------------------------------
    // CASE 2
    // LW -> ADD
    // rs2 dependency
    //
    // x4 = MEM[0x84] = 22
    // x5 = x0 + x4 = 22
    //
    // MUST stall exactly once
    // --------------------------------------------------------

    u_isram.mem[3] = 32'h0040A203;
    // lw x4,4(x1)

    u_isram.mem[4] = 32'h004002B3;
    // add x5,x0,x4


    // --------------------------------------------------------
    // CASE 3
    // LW -> SW
    //
    // Store data depends on load result.
    //
    // x6 = MEM[0x88] = 33
    // MEM[0x8C] = x6
    //
    // MUST stall exactly once
    // --------------------------------------------------------

    u_isram.mem[5] = 32'h0080A303;
    // lw x6,8(x1)

    u_isram.mem[6] = 32'h0060A623;
    // sw x6,12(x1)


    // --------------------------------------------------------
    // CASE 4
    // LW -> BEQ
    //
    // Branch compare operand depends on load.
    //
    // MEM[0x90] = 7
    // therefore BEQ x7,x0 is NOT taken.
    //
    // MUST load-use stall exactly once.
    // --------------------------------------------------------

    u_isram.mem[7] = 32'h0100A383;
    // lw x7,16(x1)

    u_isram.mem[8] = 32'h00038463;
    // beq x7,x0,+8

    u_isram.mem[9] = 32'h00800413;
    // addi x8,x0,8
    //
    // Must execute because branch is NOT taken.


    // --------------------------------------------------------
    // CASE 5
    // LW rd=x0
    //
    // Even though following instruction reads x0,
    // rd=x0 must NEVER create a hazard.
    //
    // NO stall allowed.
    // --------------------------------------------------------

    u_isram.mem[10] = 32'h0140A003;
    // lw x0,20(x1)

    u_isram.mem[11] = 32'h00900493;
    // addi x9,x0,9


    // --------------------------------------------------------
    // CASE 6
    // False dependency test
    //
    // lw x10,...
    //
    // ADDI encoding has:
    // instr[24:20] = imm[4:0]
    //
    // imm = 10
    //
    // Therefore raw instruction field [24:20] == 10,
    // which looks like "rs2=x10".
    //
    // But ADDI DOES NOT USE rs2.
    //
    // use_rs2 must prevent a false load-use stall.
    //
    // NO stall allowed.
    // --------------------------------------------------------

    u_isram.mem[12] = 32'h0180A503;
    // lw x10,24(x1)

    u_isram.mem[13] = 32'h00A00593;
    // addi x11,x0,10


    // --------------------------------------------------------
    // CASE 7
    // Completely independent instruction
    //
    // NO stall allowed.
    // --------------------------------------------------------

    u_isram.mem[14] = 32'h01C0A603;
    // lw x12,28(x1)

    u_isram.mem[15] = 32'h000006B3;
    // add x13,x0,x0


    // --------------------------------------------------------
    // End marker
    // --------------------------------------------------------

    u_isram.mem[16] = 32'h05500F93;
    // addi x31,x0,0x55


    // Fill remaining ISRAM with NOP
    for (int i = 17; i < 128; i++)
        u_isram.mem[i] = 32'h00000013;


    // ========================================================
    // DSRAM initial contents
    // ========================================================

    // 0x80
    u_dsram.mem[32] = 32'd11;

    // 0x84
    u_dsram.mem[33] = 32'd22;

    // 0x88
    u_dsram.mem[34] = 32'd33;

    // 0x8C - destination of LW->SW
    u_dsram.mem[35] = 32'd0;

    // 0x90
    // x7 = 7, therefore BEQ x7,x0 is NOT taken
    u_dsram.mem[36] = 32'd7;

    // 0x94
    u_dsram.mem[37] = 32'h12345678;

    // 0x98
    u_dsram.mem[38] = 32'd100;

    // 0x9C
    u_dsram.mem[39] = 32'd200;


    // ========================================================
    // Expected WB stream
    // ========================================================

    expected_wb_rd[0]   = 5'd1;
    expected_wb_data[0] = 32'd128;

    expected_wb_rd[1]   = 5'd2;
    expected_wb_data[1] = 32'd11;

    expected_wb_rd[2]   = 5'd3;
    expected_wb_data[2] = 32'd11;

    expected_wb_rd[3]   = 5'd4;
    expected_wb_data[3] = 32'd22;

    expected_wb_rd[4]   = 5'd5;
    expected_wb_data[4] = 32'd22;

    expected_wb_rd[5]   = 5'd6;
    expected_wb_data[5] = 32'd33;

    expected_wb_rd[6]   = 5'd7;
    expected_wb_data[6] = 32'd7;

    expected_wb_rd[7]   = 5'd8;
    expected_wb_data[7] = 32'd8;

    // lw x0 does NOT generate architectural WB.

    expected_wb_rd[8]   = 5'd9;
    expected_wb_data[8] = 32'd9;

    expected_wb_rd[9]   = 5'd10;
    expected_wb_data[9] = 32'd100;

    expected_wb_rd[10]   = 5'd11;
    expected_wb_data[10] = 32'd10;

    expected_wb_rd[11]   = 5'd12;
    expected_wb_data[11] = 32'd200;

    expected_wb_rd[12]   = 5'd13;
    expected_wb_data[12] = 32'd0;

    expected_wb_rd[13]   = 5'd31;
    expected_wb_data[13] = 32'h00000055;


    // ========================================================
    // Release reset
    // ========================================================

    #20;
    rst_n = 1'b1;


    // ========================================================
    // Wait for complete architectural stream
    // ========================================================

    wait(test_done);

    @(posedge clk);
    #1;


    // ========================================================
    // Hazard count
    // ========================================================

    if (load_stall_count !== EXPECTED_LOAD_STALL) begin

        $error(
            "[LOAD-USE COUNT] expected=%0d actual=%0d",
            EXPECTED_LOAD_STALL,
            load_stall_count
        );

        errors++;
    end
    else begin

        $display(
            "[LOAD-USE COUNT PASS] expected=%0d actual=%0d",
            EXPECTED_LOAD_STALL,
            load_stall_count
        );

    end


    // ========================================================
    // Final memory check
    //
    // CASE 3:
    // LW x6,8(x1)
    // SW x6,12(x1)
    //
    // Must store 33.
    // ========================================================

    if (u_dsram.mem[35] !== 32'd33) begin

        $error(
            "[LW->SW] expected MEM[0x8C]=00000021 actual=%08h",
            u_dsram.mem[35]
        );

        errors++;

    end


    // ========================================================
    // Result
    // ========================================================

    report_result("LOAD_USE_TEST");

    $finish;

end


// ============================================================
// LOAD-USE MECHANISM CHECKER
//
// Sample at negedge:
// combinational hazard/control signals have settled.
//
// IMPORTANT:
// This assumes these signals are visible in cpu_core:
//
//   u_cpu.load_use_hazard
//   u_cpu.pc_en
//   u_cpu.if_id_en
//   u_cpu.id_ex_flush
//
// ============================================================
logic load_use_fire;

assign load_use_fire =
    u_cpu.load_use_hazard   &&
    !u_cpu.mem_stall        &&
    !u_cpu.redirect_valid   &&
    !u_cpu.u_pipeline_control.redirect_refill_q;

always @(negedge clk) begin

    if (rst_n && load_use_fire) begin

        load_stall_count++;

        $display(
            "[LOAD-USE FIRE] cycle=%0d pc=%08h",
            cycle_count,
            u_cpu.if_id_pc
        );

        if (u_cpu.pc_en !== 1'b0) begin
            $error("[LOAD-USE] pc_en must be 0");
            errors++;
        end

        if (u_cpu.if_id_en !== 1'b0) begin
            $error("[LOAD-USE] if_id_en must be 0");
            errors++;
        end

        if (u_cpu.id_ex_flush !== 1'b1) begin
            $error("[LOAD-USE] id_ex_flush must be 1");
            errors++;
        end

    end

end


// ============================================================
// WB SCOREBOARD
// ============================================================

always @(posedge clk) begin

    if (rst_n && u_cpu.wb_we) begin


        // ----------------------------------------------------
        // Cycle check at final architectural WB
        // ----------------------------------------------------

        if (wb_idx == EXPECTED_WB_COUNT-1) begin

            actual_cycles = cycle_count + 1;

            if (actual_cycles !== EXPECTED_CYCLES) begin

                $error(
                    "[CYCLE] expected=%0d actual=%0d",
                    EXPECTED_CYCLES,
                    actual_cycles
                );

                errors++;

            end
            else begin

                $display(
                    "[CYCLE PASS] expected=%0d actual=%0d",
                    EXPECTED_CYCLES,
                    actual_cycles
                );

            end

        end


        // ----------------------------------------------------
        // Unexpected WB
        // ----------------------------------------------------

        if (wb_idx >= EXPECTED_WB_COUNT) begin

            $error(
                "[WB] Unexpected extra WB: rd=x%0d data=%08h",
                u_cpu.wb_rd,
                u_cpu.wb_data
            );

            errors++;

        end


        // ----------------------------------------------------
        // Expected WB
        // ----------------------------------------------------

        else begin

            if (u_cpu.wb_rd !== expected_wb_rd[wb_idx]) begin

                $error(
                    "[WB #%0d] RD mismatch: expected=x%0d actual=x%0d",
                    wb_idx,
                    expected_wb_rd[wb_idx],
                    u_cpu.wb_rd
                );

                errors++;

            end


            if (u_cpu.wb_data !== expected_wb_data[wb_idx]) begin

                $error(
                    "[WB #%0d] DATA mismatch: expected=%08h actual=%08h",
                    wb_idx,
                    expected_wb_data[wb_idx],
                    u_cpu.wb_data
                );

                errors++;

            end


            $display(
                "[WB PASS] #%0d x%0d = %08h",
                wb_idx,
                u_cpu.wb_rd,
                u_cpu.wb_data
            );


            wb_idx++;


            if (wb_idx == EXPECTED_WB_COUNT)
                test_done = 1'b1;

        end

    end

end