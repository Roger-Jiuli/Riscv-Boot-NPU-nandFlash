// ============================================================
// branch_test.sv
//
// Coverage:
//   1. BEQ   taken / not taken
//   2. BNE   taken / not taken
//   3. BLT   taken / not taken
//   4. BGE   taken / not taken
//   5. BLTU  taken / not taken
//   6. BGEU  taken / not taken
//
//   7. Signed / unsigned comparison
//   8. ALU -> Branch forwarding
//   9. LW  -> Branch load-use
//
//  10. Consecutive branches:
//      a. first taken     -> second wrong-path branch killed
//      b. first not taken -> second taken executes
//      c. first not taken -> second not taken executes
//
//  11. Wrong-path ADDI must not WB
//  12. Wrong-path SW must not modify memory
//
// Check:
//   - exact WB stream
//   - exact redirect stream
//   - wrong-path store side effect
//
// NOTE:
//   Cycle count is intentionally NOT checked yet.
// ============================================================


// ============================================================
// Expected WB stream
// ============================================================

localparam int EXPECTED_WB_COUNT = 26;
localparam int EXPECTED_CYCLES = 93;

logic [4:0]  expected_wb_rd   [0:EXPECTED_WB_COUNT-1];
logic [31:0] expected_wb_data [0:EXPECTED_WB_COUNT-1];

integer wb_idx;
logic [31:0] actual_cycles;


// ============================================================
// Expected redirect stream
//
// Only actually executed TAKEN branches may redirect.
// Wrong-path branches must NEVER appear here.
// ============================================================

localparam int EXPECTED_REDIRECT_COUNT = 9;

logic [31:0]
    expected_redirect_pc [0:EXPECTED_REDIRECT_COUNT-1];

integer redirect_idx;


// ============================================================
// Test control
// ============================================================

logic test_done;


// ============================================================
// Test program
// ============================================================

initial begin

    errors       = 0;
    wb_idx       = 0;
    redirect_idx = 0;
    test_done    = 1'b0;
    actual_cycles = 0;

    rst_n = 1'b0;


    // ========================================================
    // 0. Basic register preparation
    // ========================================================

    u_isram.mem[0] = 32'h00100093;
    // 0x0000: addi x1, x0, 1

    u_isram.mem[1] = 32'h00100113;
    // 0x0004: addi x2, x0, 1

    u_isram.mem[2] = 32'h00200193;
    // 0x0008: addi x3, x0, 2

    u_isram.mem[3] = 32'hFFF00213;
    // 0x000C: addi x4, x0, -1
    // x4 = 0xFFFFFFFF


    // ========================================================
    // CASE 1
    // BEQ taken
    //
    // x1 == x2
    //
    // 0x10 -> 0x18
    // ========================================================

    u_isram.mem[4] = 32'h00208463;
    // 0x10: beq x1, x2, +8
    // TAKEN -> index 6

    u_isram.mem[5] = 32'h06400A13;
    // 0x14: addi x20, x0, 100
    // WRONG PATH -- must NOT WB

    u_isram.mem[6] = 32'h00B00293;
    // 0x18: addi x5, x0, 11


    // ========================================================
    // CASE 2
    // BEQ not taken
    //
    // x1 != x3
    // ========================================================

    u_isram.mem[7] = 32'h00308463;
    // 0x1C: beq x1, x3, +8
    // NOT TAKEN

    u_isram.mem[8] = 32'h00C00313;
    // 0x20: addi x6, x0, 12


    // ========================================================
    // CASE 3
    // BNE taken
    //
    // x1 != x3
    //
    // 0x24 -> 0x2C
    // ========================================================

    u_isram.mem[9] = 32'h00309463;
    // 0x24: bne x1, x3, +8
    // TAKEN

    u_isram.mem[10] = 32'h06500A13;
    // 0x28: addi x20, x0, 101
    // WRONG PATH

    u_isram.mem[11] = 32'h00D00393;
    // 0x2C: addi x7, x0, 13


    // ========================================================
    // CASE 4
    // BNE not taken
    //
    // x1 == x2
    // ========================================================

    u_isram.mem[12] = 32'h00209463;
    // 0x30: bne x1, x2, +8
    // NOT TAKEN

    u_isram.mem[13] = 32'h00E00413;
    // 0x34: addi x8, x0, 14


    // ========================================================
    // CASE 5
    // BLT signed taken
    //
    // signed:
    // -1 < 1
    //
    // 0x38 -> 0x40
    // ========================================================

    u_isram.mem[14] = 32'h00124463;
    // 0x38: blt x4, x1, +8
    // TAKEN

    u_isram.mem[15] = 32'h06600A13;
    // 0x3C: addi x20, x0, 102
    // WRONG PATH

    u_isram.mem[16] = 32'h00F00493;
    // 0x40: addi x9, x0, 15


    // ========================================================
    // CASE 6
    // BLT signed not taken
    //
    // 2 < 1 = false
    // ========================================================

    u_isram.mem[17] = 32'h0011C463;
    // 0x44: blt x3, x1, +8
    // NOT TAKEN

    u_isram.mem[18] = 32'h01000513;
    // 0x48: addi x10, x0, 16


    // ========================================================
    // CASE 7
    // BGE signed taken
    //
    // 2 >= 1
    //
    // 0x4C -> 0x54
    // ========================================================

    u_isram.mem[19] = 32'h0011D463;
    // 0x4C: bge x3, x1, +8
    // TAKEN

    u_isram.mem[20] = 32'h06700A13;
    // 0x50: addi x20, x0, 103
    // WRONG PATH

    u_isram.mem[21] = 32'h01100593;
    // 0x54: addi x11, x0, 17


    // ========================================================
    // CASE 8
    // BGE signed not taken
    //
    // -1 >= 1 = false
    // ========================================================

    u_isram.mem[22] = 32'h00125463;
    // 0x58: bge x4, x1, +8
    // NOT TAKEN

    u_isram.mem[23] = 32'h01200613;
    // 0x5C: addi x12, x0, 18


    // ========================================================
    // CASE 9
    // BLTU not taken
    //
    // unsigned:
    //
    // x4 = 0xFFFFFFFF
    // x1 = 0x00000001
    //
    // 0xFFFFFFFF < 1 = false
    //
    // This distinguishes BLTU from BLT.
    // ========================================================

    u_isram.mem[24] = 32'h00126463;
    // 0x60: bltu x4, x1, +8
    // NOT TAKEN

    u_isram.mem[25] = 32'h01300693;
    // 0x64: addi x13, x0, 19


    // ========================================================
    // CASE 10
    // BLTU taken
    //
    // unsigned:
    // 1 < 2
    //
    // 0x68 -> 0x70
    // ========================================================

    u_isram.mem[26] = 32'h0030E463;
    // 0x68: bltu x1, x3, +8
    // TAKEN

    u_isram.mem[27] = 32'h06800A13;
    // 0x6C: addi x20, x0, 104
    // WRONG PATH

    u_isram.mem[28] = 32'h01400713;
    // 0x70: addi x14, x0, 20


    // ========================================================
    // CASE 11
    // BGEU taken
    //
    // unsigned:
    // 0xFFFFFFFF >= 1
    //
    // 0x74 -> 0x7C
    // ========================================================

    u_isram.mem[29] = 32'h00127463;
    // 0x74: bgeu x4, x1, +8
    // TAKEN

    u_isram.mem[30] = 32'h06900A13;
    // 0x78: addi x20, x0, 105
    // WRONG PATH

    u_isram.mem[31] = 32'h01500793;
    // 0x7C: addi x15, x0, 21


    // ========================================================
    // CASE 12
    // BGEU not taken
    //
    // unsigned:
    // 1 >= 2 = false
    // ========================================================

    u_isram.mem[32] = 32'h0030F463;
    // 0x80: bgeu x1, x3, +8
    // NOT TAKEN

    u_isram.mem[33] = 32'h01600813;
    // 0x84: addi x16, x0, 22


    // ========================================================
    // CASE 13
    // ALU -> Branch forwarding
    //
    // x17 is written immediately before BEQ.
    //
    // Correct x17 = 5:
    //      beq x17,x0 -> NOT TAKEN
    //
    // If forwarding fails and branch sees stale x17=0:
    //      branch incorrectly TAKEN.
    // ========================================================

    u_isram.mem[34] = 32'h00500893;
    // 0x88: addi x17, x0, 5

    u_isram.mem[35] = 32'h00088463;
    // 0x8C: beq x17, x0, +8
    // NOT TAKEN

    u_isram.mem[36] = 32'h01700913;
    // 0x90: addi x18, x0, 23


    // ========================================================
    // CASE 14
    // LW -> Branch
    //
    // MEM[0x80] = 7
    //
    // lw x19 -> beq x19,x0
    //
    // Correct:
    // x19 = 7, therefore NOT TAKEN.
    //
    // Exercises:
    //   - load-use hazard
    //   - load data forwarding
    //   - branch comparison
    // ========================================================

    u_isram.mem[37] = 32'h08000B13;
    // 0x94: addi x22, x0, 128

    u_isram.mem[38] = 32'h000B2983;
    // 0x98: lw x19, 0(x22)

    u_isram.mem[39] = 32'h00098463;
    // 0x9C: beq x19, x0, +8
    // NOT TAKEN

    u_isram.mem[40] = 32'h01800A93;
    // 0xA0: addi x21, x0, 24


    // ========================================================
    // CASE 15
    //
    // Consecutive Branch:
    //
    //   first  = TAKEN
    //   second = WRONG PATH
    //
    // Second branch is:
    //
    //     beq x0,x0
    //
    // so if it survives it is guaranteed to redirect.
    //
    // Correct behavior:
    //
    //     branch #1 redirects to index44.
    //     branch #2 MUST DIE.
    //
    // 0xA4 -> 0xB0
    // ========================================================

    u_isram.mem[41] = 32'h00208663;
    // 0xA4: beq x1, x2, +12
    // TAKEN -> index44

    u_isram.mem[42] = 32'h00000863;
    // 0xA8: beq x0, x0, +16
    //
    // WRONG PATH
    //
    // If this instruction incorrectly executes:
    // 0xA8 + 0x10 = 0xB8
    //
    // There must NOT be a redirect to 0xB8.

    u_isram.mem[43] = 32'h06300A13;
    // 0xAC: addi x20, x0, 99
    // WRONG PATH

    u_isram.mem[44] = 32'h01900B93;
    // 0xB0: addi x23, x0, 25


    // ========================================================
    // CASE 16
    //
    // Consecutive Branch:
    //
    //   first  = NOT TAKEN
    //   second = TAKEN
    //
    // First branch must not accidentally kill the second.
    //
    // second:
    // 0xB8 -> 0xC0
    // ========================================================

    u_isram.mem[45] = 32'h00308463;
    // 0xB4: beq x1, x3, +8
    // NOT TAKEN

    u_isram.mem[46] = 32'h00000463;
    // 0xB8: beq x0, x0, +8
    // TAKEN -> index48

    u_isram.mem[47] = 32'h06200A13;
    // 0xBC: addi x20, x0, 98
    // WRONG PATH

    u_isram.mem[48] = 32'h01A00C13;
    // 0xC0: addi x24, x0, 26


    // ========================================================
    // CASE 17
    //
    // Consecutive Branch:
    //
    //   first  = NOT TAKEN
    //   second = NOT TAKEN
    //
    // Both branches must execute normally.
    // ========================================================

    u_isram.mem[49] = 32'h00308463;
    // 0xC4: beq x1, x3, +8
    // NOT TAKEN

    u_isram.mem[50] = 32'h00310463;
    // 0xC8: beq x2, x3, +8
    // NOT TAKEN

    u_isram.mem[51] = 32'h01B00C93;
    // 0xCC: addi x25, x0, 27


    // ========================================================
    // CASE 18
    //
    // Taken branch followed by WRONG-PATH STORE.
    //
    // MEM[0x84] initially = DEADBEEF.
    //
    // Wrong-path:
    //      sw x1,4(x22)
    //
    // would write address:
    //      0x80 + 4 = 0x84
    //
    // Correct result:
    //      MEM[0x84] remains DEADBEEF.
    //
    // 0xD0 -> 0xDC
    // ========================================================

    u_isram.mem[52] = 32'h00208663;
    // 0xD0: beq x1, x2, +12
    // TAKEN -> index55

    u_isram.mem[53] = 32'h001B2223;
    // 0xD4: sw x1, 4(x22)
    // WRONG PATH

    u_isram.mem[54] = 32'h06100A13;
    // 0xD8: addi x20, x0, 97
    // WRONG PATH

    u_isram.mem[55] = 32'h01C00D13;
    // 0xDC: addi x26, x0, 28


    // ========================================================
    // End marker
    // ========================================================

    u_isram.mem[56] = 32'h05500F93;
    // 0xE0: addi x31, x0, 0x55


    // Fill remaining ISRAM with NOP
    for (int i = 57; i < 128; i++) begin
        u_isram.mem[i] = 32'h00000013;
    end


    // ========================================================
    // DSRAM initialization
    // ========================================================

    u_dsram.mem[32] = 32'd7;
    // address 0x80

    u_dsram.mem[33] = 32'hDEADBEEF;
    // address 0x84
    // wrong-path SW must NOT change this


    // ========================================================
    // Expected WB stream
    // ========================================================

    expected_wb_rd[0]   = 5'd1;
    expected_wb_data[0] = 32'd1;

    expected_wb_rd[1]   = 5'd2;
    expected_wb_data[1] = 32'd1;

    expected_wb_rd[2]   = 5'd3;
    expected_wb_data[2] = 32'd2;

    expected_wb_rd[3]   = 5'd4;
    expected_wb_data[3] = 32'hFFFFFFFF;

    expected_wb_rd[4]   = 5'd5;
    expected_wb_data[4] = 32'd11;

    expected_wb_rd[5]   = 5'd6;
    expected_wb_data[5] = 32'd12;

    expected_wb_rd[6]   = 5'd7;
    expected_wb_data[6] = 32'd13;

    expected_wb_rd[7]   = 5'd8;
    expected_wb_data[7] = 32'd14;

    expected_wb_rd[8]   = 5'd9;
    expected_wb_data[8] = 32'd15;

    expected_wb_rd[9]   = 5'd10;
    expected_wb_data[9] = 32'd16;

    expected_wb_rd[10]   = 5'd11;
    expected_wb_data[10] = 32'd17;

    expected_wb_rd[11]   = 5'd12;
    expected_wb_data[11] = 32'd18;

    expected_wb_rd[12]   = 5'd13;
    expected_wb_data[12] = 32'd19;

    expected_wb_rd[13]   = 5'd14;
    expected_wb_data[13] = 32'd20;

    expected_wb_rd[14]   = 5'd15;
    expected_wb_data[14] = 32'd21;

    expected_wb_rd[15]   = 5'd16;
    expected_wb_data[15] = 32'd22;

    expected_wb_rd[16]   = 5'd17;
    expected_wb_data[16] = 32'd5;

    expected_wb_rd[17]   = 5'd18;
    expected_wb_data[17] = 32'd23;

    expected_wb_rd[18]   = 5'd22;
    expected_wb_data[18] = 32'd128;

    expected_wb_rd[19]   = 5'd19;
    expected_wb_data[19] = 32'd7;

    expected_wb_rd[20]   = 5'd21;
    expected_wb_data[20] = 32'd24;

    expected_wb_rd[21]   = 5'd23;
    expected_wb_data[21] = 32'd25;

    expected_wb_rd[22]   = 5'd24;
    expected_wb_data[22] = 32'd26;

    expected_wb_rd[23]   = 5'd25;
    expected_wb_data[23] = 32'd27;

    expected_wb_rd[24]   = 5'd26;
    expected_wb_data[24] = 32'd28;

    expected_wb_rd[25]   = 5'd31;
    expected_wb_data[25] = 32'h00000055;


    // ========================================================
    // Expected redirect stream
    //
    // Order of actually executed TAKEN branches:
    //
    // #0 BEQ
    // #1 BNE
    // #2 BLT
    // #3 BGE
    // #4 BLTU
    // #5 BGEU
    // #6 branch->branch: first taken
    // #7 branch->branch: second taken
    // #8 wrong-path-store protection branch
    // ========================================================

    expected_redirect_pc[0] = 32'h00000018;

    expected_redirect_pc[1] = 32'h0000002C;

    expected_redirect_pc[2] = 32'h00000040;

    expected_redirect_pc[3] = 32'h00000054;

    expected_redirect_pc[4] = 32'h00000070;

    expected_redirect_pc[5] = 32'h0000007C;

    expected_redirect_pc[6] = 32'h000000B0;

    expected_redirect_pc[7] = 32'h000000C0;

    expected_redirect_pc[8] = 32'h000000DC;


    // ========================================================
    // Release reset
    // ========================================================

    #20;
    rst_n = 1'b1;


    // ========================================================
    // Wait until final expected WB
    // ========================================================

    wait(test_done);

    @(posedge clk);
    #1;


    // ========================================================
    // Final checks
    // ========================================================

    if (wb_idx !== EXPECTED_WB_COUNT) begin
        $error(
            "[WB COUNT] expected=%0d actual=%0d",
            EXPECTED_WB_COUNT,
            wb_idx
        );
        errors++;
    end


    if (redirect_idx !== EXPECTED_REDIRECT_COUNT) begin
        $error(
            "[REDIRECT COUNT] expected=%0d actual=%0d",
            EXPECTED_REDIRECT_COUNT,
            redirect_idx
        );
        errors++;
    end


    // Wrong-path SW must never reach DSRAM.
    if (u_dsram.mem[33] !== 32'hDEADBEEF) begin

        $error(
            "[WRONG-PATH STORE] addr=0x84 expected=DEADBEEF actual=%08h",
            u_dsram.mem[33]
        );

        errors++;

    end
    else begin

        $display(
            "[PASS] Wrong-path store killed, MEM[0x84]=%08h",
            u_dsram.mem[33]
        );

    end


    report_result("BRANCH_TEST");

    $finish;

end


// ============================================================
// WB SCOREBOARD
//
// Exact architectural commit stream.
//
// Any wrong-path register-writing instruction that survives
// flush will disturb this stream and cause failure.
// ============================================================

always @(posedge clk) begin

    if (rst_n && u_cpu.wb_we) begin

        if (wb_idx >= EXPECTED_WB_COUNT) begin

            $error(
                "[WB EXTRA] rd=x%0d data=%08h",
                u_cpu.wb_rd,
                u_cpu.wb_data
            );

            errors++;

        end
        else begin

            if (u_cpu.wb_rd !== expected_wb_rd[wb_idx]) begin

                $error(
                    "[WB #%0d RD] expected=x%0d actual=x%0d",
                    wb_idx,
                    expected_wb_rd[wb_idx],
                    u_cpu.wb_rd
                );

                errors++;

            end


            if (u_cpu.wb_data !== expected_wb_data[wb_idx]) begin

                $error(
                    "[WB #%0d DATA] expected=%08h actual=%08h",
                    wb_idx,
                    expected_wb_data[wb_idx],
                    u_cpu.wb_data
                );

                errors++;

            end


            if ((u_cpu.wb_rd === expected_wb_rd[wb_idx]) &&
                (u_cpu.wb_data === expected_wb_data[wb_idx])) begin

                $display(
                    "[WB PASS] #%0d x%0d = %08h",
                    wb_idx,
                    u_cpu.wb_rd,
                    u_cpu.wb_data
                );

            end


            wb_idx++;

            if (wb_idx == EXPECTED_WB_COUNT) begin

                actual_cycles = cycle_count + 1;
                test_done     = 1'b1;

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

        end

    end

end


// ============================================================
// REDIRECT SCOREBOARD
//
// Sample at negedge:
// combinational EX redirect signals are stable here.
//
// This is especially important for:
//
//   CASE 15:
//       taken branch
//       followed by wrong-path unconditional BEQ
//
// If the wrong-path BEQ survives, an unexpected redirect
// appears here immediately.
// ============================================================

always @(negedge clk) begin

    if (rst_n && u_cpu.redirect_valid) begin

        if (redirect_idx >= EXPECTED_REDIRECT_COUNT) begin

            $error(
                "[REDIRECT EXTRA] target=%08h",
                u_cpu.redirect_pc
            );

            errors++;

        end
        else begin

            if (u_cpu.redirect_pc !==
                expected_redirect_pc[redirect_idx]) begin

                $error(
                    "[REDIRECT #%0d] expected=%08h actual=%08h",
                    redirect_idx,
                    expected_redirect_pc[redirect_idx],
                    u_cpu.redirect_pc
                );

                errors++;

            end
            else begin

                $display(
                    "[REDIRECT PASS] #%0d target=%08h",
                    redirect_idx,
                    u_cpu.redirect_pc
                );

            end

        end


        redirect_idx++;

    end

end


// ============================================================
// Timeout
//
// Prevent simulation from hanging forever if branch control
// flow enters a wrong path / loop.
// ============================================================

initial begin

    #10000;

    if (!test_done) begin

        $error(
            "[TIMEOUT] wb_idx=%0d/%0d redirect_idx=%0d/%0d",
            wb_idx,
            EXPECTED_WB_COUNT,
            redirect_idx,
            EXPECTED_REDIRECT_COUNT
        );

        errors++;

        report_result("BRANCH_TEST");

        $finish;

    end

end