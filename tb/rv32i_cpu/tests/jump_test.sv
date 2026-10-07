// ============================================================
// jump_test.sv
//
// Coverage:
//   1. JAL basic jump + PC+4
//   2. JAL x0: jump without WB
//   3. JALR basic jump + PC+4
//   4. JALR clears target bit[0]
//   5. ADDI -> JALR forwarding
//   6. LW   -> JALR load-use
//   7. JAL  -> JAL: wrong-path JAL must die
//   8. JALR -> JAL: wrong-path JAL must die
//   9. Wrong-path ADDI must not WB
//  10. Wrong-path SW must not modify memory
//
// Check:
//   - exact WB stream
//   - exact redirect stream
//   - JAL/JALR PC+4
//   - wrong-path side effects
//
// Cycle count:
//   add after functional PASS
// ============================================================


// ============================================================
// Expected streams
// ============================================================

localparam int EXPECTED_WB_COUNT       = 24;
localparam int EXPECTED_REDIRECT_COUNT = 9;
localparam int EXPECTED_CYCLES = 61;

logic [4:0]  expected_wb_rd
    [0:EXPECTED_WB_COUNT-1];

logic [31:0] expected_wb_data
    [0:EXPECTED_WB_COUNT-1];

logic [31:0] expected_redirect_pc
    [0:EXPECTED_REDIRECT_COUNT-1];

integer wb_idx;
integer redirect_idx;

logic test_done;
logic [31:0] actual_cycles;


// ============================================================
// Main test
// ============================================================

initial begin

    errors       = 0;
    wb_idx       = 0;
    redirect_idx = 0;
    test_done    = 1'b0;
    actual_cycles = 0;

    rst_n = 1'b0;


    // ========================================================
    // CASE 1: Basic JAL
    //
    // 0x00: jal x1,+8
    //
    // target = 0x08
    // x1     = PC+4 = 0x04
    // ========================================================

    u_isram.mem[0] = 32'h008000EF;
    // 0x00: jal x1,+8

    u_isram.mem[1] = 32'h06300A13;
    // 0x04: addi x20,x0,99
    // WRONG PATH

    u_isram.mem[2] = 32'h00B00113;
    // 0x08: addi x2,x0,11


    // ========================================================
    // CASE 2: JAL x0
    //
    // Jump but no register write.
    //
    // 0x0C -> 0x14
    // ========================================================

    u_isram.mem[3] = 32'h0080006F;
    // 0x0C: jal x0,+8

    u_isram.mem[4] = 32'h06200A13;
    // 0x10: addi x20,x0,98
    // WRONG PATH

    u_isram.mem[5] = 32'h00C00193;
    // 0x14: addi x3,x0,12


    // ========================================================
    // CASE 3: Basic JALR
    //
    // x4 = 0x24
    //
    // 0x1C:
    // jalr x5,0(x4)
    //
    // target = 0x24
    // x5     = 0x20
    // ========================================================

    u_isram.mem[6] = 32'h02400213;
    // 0x18: addi x4,x0,0x24

    u_isram.mem[7] = 32'h000202E7;
    // 0x1C: jalr x5,0(x4)

    u_isram.mem[8] = 32'h06100A13;
    // 0x20: addi x20,x0,97
    // WRONG PATH

    u_isram.mem[9] = 32'h00D00313;
    // 0x24: addi x6,x0,13


    // ========================================================
    // CASE 4: JALR bit[0] clear
    //
    // x7 = 0x35
    //
    // target:
    // (0x35 + 0) & ~1
    // = 0x34
    //
    // JALR PC = 0x2C
    // x8      = 0x30
    // ========================================================

    u_isram.mem[10] = 32'h03500393;
    // 0x28: addi x7,x0,0x35

    u_isram.mem[11] = 32'h00038467;
    // 0x2C: jalr x8,0(x7)

    u_isram.mem[12] = 32'h06000A13;
    // 0x30: addi x20,x0,96
    // WRONG PATH

    u_isram.mem[13] = 32'h00E00493;
    // 0x34: addi x9,x0,14


    // ========================================================
    // CASE 5: ADDI -> JALR forwarding
    //
    // x10 produced immediately before JALR.
    //
    // 0x38: x10 = 0x44
    // 0x3C: jalr x11,0(x10)
    //
    // target = 0x44
    // x11    = 0x40
    // ========================================================

    u_isram.mem[14] = 32'h04400513;
    // 0x38: addi x10,x0,0x44

    u_isram.mem[15] = 32'h000505E7;
    // 0x3C: jalr x11,0(x10)

    u_isram.mem[16] = 32'h05F00A13;
    // 0x40: addi x20,x0,95
    // WRONG PATH

    u_isram.mem[17] = 32'h00F00613;
    // 0x44: addi x12,x0,15


    // ========================================================
    // CASE 6: LW -> JALR
    //
    // MEM[0x80] = 0x58
    //
    // lw x13,0(x15)
    // jalr x14,0(x13)
    //
    // Exercises:
    //   MEM stall
    //   load-use
    //   forwarding
    //   JALR
    //
    // target = 0x58
    // x14    = 0x54
    // ========================================================

    u_isram.mem[18] = 32'h08000793;
    // 0x48: addi x15,x0,128

    u_isram.mem[19] = 32'h0007A683;
    // 0x4C: lw x13,0(x15)

    u_isram.mem[20] = 32'h00068767;
    // 0x50: jalr x14,0(x13)

    u_isram.mem[21] = 32'h05E00A13;
    // 0x54: addi x20,x0,94
    // WRONG PATH

    u_isram.mem[22] = 32'h01000813;
    // 0x58: addi x16,x0,16


    // ========================================================
    // CASE 7: JAL -> JAL
    //
    // First JAL:
    //
    // 0x5C -> 0x68
    // x17 = 0x60
    //
    // Second JAL at 0x60 is WRONG PATH.
    //
    // If it survives:
    //   redirect -> 0x78
    //   x18      -> 0x64
    //
    // Neither is allowed.
    // ========================================================

    u_isram.mem[23] = 32'h00C008EF;
    // 0x5C: jal x17,+12
    // target = 0x68

    u_isram.mem[24] = 32'h0180096F;
    // 0x60: jal x18,+24
    // WRONG PATH
    // would target 0x78

    u_isram.mem[25] = 32'h05D00A13;
    // 0x64: addi x20,x0,93
    // WRONG PATH

    u_isram.mem[26] = 32'h01100993;
    // 0x68: addi x19,x0,17


    // ========================================================
    // CASE 8: JALR -> JAL
    //
    // x21 = 0x7C
    //
    // 0x70:
    // jalr x22,0(x21)
    //
    // target = 0x7C
    // x22    = 0x74
    //
    // Following JAL at 0x74 is WRONG PATH.
    // ========================================================

    u_isram.mem[27] = 32'h07C00A93;
    // 0x6C: addi x21,x0,0x7C

    u_isram.mem[28] = 32'h000A8B67;
    // 0x70: jalr x22,0(x21)

    u_isram.mem[29] = 32'h01800BEF;
    // 0x74: jal x23,+24
    // WRONG PATH
    // would target 0x8C

    u_isram.mem[30] = 32'h05C00A13;
    // 0x78: addi x20,x0,92
    // WRONG PATH

    u_isram.mem[31] = 32'h01200C13;
    // 0x7C: addi x24,x0,18


    // ========================================================
    // CASE 9: Wrong-path STORE
    //
    // 0x80:
    // jal x25,+12
    //
    // target = 0x8C
    // x25    = 0x84
    //
    // Wrong path:
    // sw x2,4(x15)
    //
    // x15 = 0x80
    // address = 0x84
    //
    // MEM[0x84] must remain DEADBEEF.
    // ========================================================

    u_isram.mem[32] = 32'h00C00CEF;
    // 0x80: jal x25,+12

    u_isram.mem[33] = 32'h0027A223;
    // 0x84: sw x2,4(x15)
    // WRONG PATH

    u_isram.mem[34] = 32'h05B00A13;
    // 0x88: addi x20,x0,91
    // WRONG PATH

    u_isram.mem[35] = 32'h01300D13;
    // 0x8C: addi x26,x0,19


    // ========================================================
    // End marker
    // ========================================================

    u_isram.mem[36] = 32'h05500F93;
    // 0x90: addi x31,x0,0x55


    // ========================================================
    // Remaining ISRAM = NOP
    // ========================================================

    for (int i = 37; i < 128; i++) begin
        u_isram.mem[i] = 32'h00000013;
    end


    // ========================================================
    // DSRAM
    // ========================================================

    u_dsram.mem[32] = 32'h00000058;
    // address 0x80
    // target used by LW -> JALR

    u_dsram.mem[33] = 32'hDEADBEEF;
    // address 0x84
    // wrong-path SW protection


    // ========================================================
    // Expected WB stream
    // ========================================================

    expected_wb_rd[0]   = 5'd1;
    expected_wb_data[0] = 32'h00000004;
    // JAL PC+4

    expected_wb_rd[1]   = 5'd2;
    expected_wb_data[1] = 32'd11;


    expected_wb_rd[2]   = 5'd3;
    expected_wb_data[2] = 32'd12;


    expected_wb_rd[3]   = 5'd4;
    expected_wb_data[3] = 32'h00000024;

    expected_wb_rd[4]   = 5'd5;
    expected_wb_data[4] = 32'h00000020;
    // JALR PC+4

    expected_wb_rd[5]   = 5'd6;
    expected_wb_data[5] = 32'd13;


    expected_wb_rd[6]   = 5'd7;
    expected_wb_data[6] = 32'h00000035;

    expected_wb_rd[7]   = 5'd8;
    expected_wb_data[7] = 32'h00000030;
    // JALR PC+4

    expected_wb_rd[8]   = 5'd9;
    expected_wb_data[8] = 32'd14;


    expected_wb_rd[9]   = 5'd10;
    expected_wb_data[9] = 32'h00000044;

    expected_wb_rd[10]   = 5'd11;
    expected_wb_data[10] = 32'h00000040;
    // JALR PC+4

    expected_wb_rd[11]   = 5'd12;
    expected_wb_data[11] = 32'd15;


    expected_wb_rd[12]   = 5'd15;
    expected_wb_data[12] = 32'h00000080;

    expected_wb_rd[13]   = 5'd13;
    expected_wb_data[13] = 32'h00000058;
    // LW result

    expected_wb_rd[14]   = 5'd14;
    expected_wb_data[14] = 32'h00000054;
    // JALR PC+4

    expected_wb_rd[15]   = 5'd16;
    expected_wb_data[15] = 32'd16;


    expected_wb_rd[16]   = 5'd17;
    expected_wb_data[16] = 32'h00000060;
    // JAL PC+4

    expected_wb_rd[17]   = 5'd19;
    expected_wb_data[17] = 32'd17;


    expected_wb_rd[18]   = 5'd21;
    expected_wb_data[18] = 32'h0000007C;

    expected_wb_rd[19]   = 5'd22;
    expected_wb_data[19] = 32'h00000074;
    // JALR PC+4

    expected_wb_rd[20]   = 5'd24;
    expected_wb_data[20] = 32'd18;


    expected_wb_rd[21]   = 5'd25;
    expected_wb_data[21] = 32'h00000084;
    // JAL PC+4

    expected_wb_rd[22]   = 5'd26;
    expected_wb_data[22] = 32'd19;


    expected_wb_rd[23]   = 5'd31;
    expected_wb_data[23] = 32'h00000055;


    // ========================================================
    // Expected redirect stream
    // ========================================================

    expected_redirect_pc[0] = 32'h00000008;
    // JAL @ 0x00

    expected_redirect_pc[1] = 32'h00000014;
    // JAL x0 @ 0x0C

    expected_redirect_pc[2] = 32'h00000024;
    // JALR @ 0x1C

    expected_redirect_pc[3] = 32'h00000034;
    // JALR bit0 clear

    expected_redirect_pc[4] = 32'h00000044;
    // ADDI -> JALR

    expected_redirect_pc[5] = 32'h00000058;
    // LW -> JALR

    expected_redirect_pc[6] = 32'h00000068;
    // JAL -> JAL

    expected_redirect_pc[7] = 32'h0000007C;
    // JALR -> JAL

    expected_redirect_pc[8] = 32'h0000008C;
    // JAL protecting wrong-path SW


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


    // Wrong-path SW must never execute.
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


    report_result("JUMP_TEST");

    $finish;

end


// ============================================================
// WB SCOREBOARD
//
// Exact architectural WB stream.
//
// This catches:
//   - wrong JAL/JALR PC+4
//   - missing WB
//   - wrong-path register writes
//   - wrong WB ordering
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


            if ((u_cpu.wb_rd   === expected_wb_rd[wb_idx]) &&
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
                test_done = 1'b1;
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

        end

    end

end


// ============================================================
// Redirect scoreboard
//
// Every actually executed JAL/JALR redirects.
//
// Wrong-path JAL/JALR must NOT appear in this stream.
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

        report_result("JUMP_TEST");

        $finish;

    end

end