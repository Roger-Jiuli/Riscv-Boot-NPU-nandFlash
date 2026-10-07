// ============================================================
// integration_test.sv
//
// Final CPU integration test
//
// ============================================================
// 1. Equivalent software program
// ============================================================
//
// int main()
// {
//     uint32_t *base = (uint32_t *)0x100;
//
//     // ------------------------------------------------------
//     // Basic ALU + Store
//     // ------------------------------------------------------
//
//     uint32_t a = 10;
//     uint32_t b = 20;
//
//     base[0] = a;                 // MEM[0x100] = 10
//     base[1] = b;                 // MEM[0x104] = 20
//
//
//     // ------------------------------------------------------
//     // Load + load-use + ALU
//     // ------------------------------------------------------
//
//     uint32_t x = base[0];        // 10
//     uint32_t y = base[1];        // 20
//
//     uint32_t sum = x + y;        // 30
//                                  // y comes from immediately
//                                  // preceding LW -> load-use
//
//
//     // ------------------------------------------------------
//     // Taken branch
//     // ------------------------------------------------------
//
//     if (sum == 30) {
//
//         // Correct path
//
//     } else {
//
//         // WRONG PATH:
//         // neither of these side effects may occur.
//
//         x20 = 99;
//         base[4] = a;             // MEM[0x110]
//     }
//
//
//     // ------------------------------------------------------
//     // Function call
//     //
//     // Implemented by:
//     //
//     //     jal x8, func
//     //
//     // x8 = return address
//     // ------------------------------------------------------
//
//     uint32_t result = func(base, sum);
//
//
//     // ------------------------------------------------------
//     // Store function result and load it back
//     // ------------------------------------------------------
//
//     base[2] = result;            // MEM[0x108] = 31
//
//     uint32_t check = base[2];    // 31
//
//
//     // ------------------------------------------------------
//     // Not-taken branch
//     // ------------------------------------------------------
//
//     if (check != 31) {
//
//         // Failure path.
//         // Correct execution must NOT enter here.
//
//         goto fail;
//     }
//
//     x21 = 1;
//
//
//     // ------------------------------------------------------
//     // Unconditional jump over failure code
//     //
//     // Implemented by:
//     //
//     //     jal x0, pass
//     // ------------------------------------------------------
//
//     goto pass;
//
// fail:
//
//     x20 = 88;                    // WRONG PATH
//
//
// pass:
//
//     x31 = 0x55;                  // Test completion marker
//
//     return 0;
// }
//
//
//
// // ==========================================================
// // Function
// // ==========================================================
//
// uint32_t func(uint32_t *base, uint32_t value)
// {
//     // Store argument to memory.
//
//     base[3] = value;             // MEM[0x10C] = 30
//
//
//     // Load it back.
//
//     uint32_t temp = base[3];     // 30
//
//
//     // Immediate use of LW result.
//     // Exercises another load-use hazard.
//
//     uint32_t result = temp + 1;  // 31
//
//
//     // Return implemented by:
//
//     //     jalr x0, 0(x8)
//
//     return result;
// }
//
//
// ============================================================
// 2. Expected final architectural state
// ============================================================
//
// Registers:
//
//     x6  = 30          sum
//     x8  = 0x34        JAL return address
//     x10 = 31          function result
//     x11 = 31          result loaded from SRAM
//     x12 = 30          value loaded inside function
//     x20 = 0           wrong-path instructions never execute
//     x21 = 1           success path executed
//     x31 = 0x55        test completion marker
//
//
// Memory:
//
//     MEM[0x100] = 10
//     MEM[0x104] = 20
//     MEM[0x108] = 31
//     MEM[0x10C] = 30
//     MEM[0x110] = DEADBEEF
//                  ^ must remain unchanged because the SW
//                    targeting it is on a wrong path.
//
//
// ============================================================
// ============================================================
// integration_test.sv
//
// Final CPU integration test
//
// Covers interaction between:
//   - ALU
//   - forwarding
//   - SW / LW
//   - MEM backpressure
//   - load-use
//   - BEQ / BNE
//   - JAL
//   - JALR
//   - PC+4 link
//   - wrong-path flush
//
// Flow:
//   main
//     -> initialize
//     -> store
//     -> load
//     -> ALU
//     -> branch
//     -> JAL function
//          -> store
//          -> load
//          -> ALU
//          -> JALR return
//     -> store result
//     -> load result
//     -> branch check
//     -> PASS marker
// ============================================================


localparam int EXPECTED_WB_COUNT       = 14;
localparam int EXPECTED_REDIRECT_COUNT = 4;
localparam int EXPECTED_CYCLES = 66;

logic [4:0] expected_wb_rd
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
// Encoding helpers
// ============================================================

function automatic [31:0] enc_r(
    input [6:0] funct7,
    input [4:0] rs2,
    input [4:0] rs1,
    input [2:0] funct3,
    input [4:0] rd
);
begin
    enc_r = {
        funct7,
        rs2,
        rs1,
        funct3,
        rd,
        7'b0110011
    };
end
endfunction


function automatic [31:0] enc_i(
    input [11:0] imm,
    input [4:0]  rs1,
    input [2:0]  funct3,
    input [4:0]  rd,
    input [6:0]  opcode
);
begin
    enc_i = {
        imm,
        rs1,
        funct3,
        rd,
        opcode
    };
end
endfunction


function automatic [31:0] enc_s(
    input [11:0] imm,
    input [4:0]  rs2,
    input [4:0]  rs1,
    input [2:0]  funct3
);
begin
    enc_s = {
        imm[11:5],
        rs2,
        rs1,
        funct3,
        imm[4:0],
        7'b0100011
    };
end
endfunction


function automatic [31:0] enc_b(
    input [12:0] imm,
    input [4:0]  rs2,
    input [4:0]  rs1,
    input [2:0]  funct3
);
begin
    enc_b = {
        imm[12],
        imm[10:5],
        rs2,
        rs1,
        funct3,
        imm[4:1],
        imm[11],
        7'b1100011
    };
end
endfunction


function automatic [31:0] enc_j(
    input [20:0] imm,
    input [4:0]  rd
);
begin
    enc_j = {
        imm[20],
        imm[10:1],
        imm[11],
        imm[19:12],
        rd,
        7'b1101111
    };
end
endfunction


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
    // MAIN PROGRAM
    // ========================================================


    // --------------------------------------------------------
    // 0x00
    // x1 = base = 0x100
    // --------------------------------------------------------

    u_isram.mem[0] =
        enc_i(
            12'h100,
            5'd0,
            3'b000,
            5'd1,
            7'b0010011
        );

    // addi x1,x0,0x100


    // --------------------------------------------------------
    // 0x04
    // x2 = 10
    // --------------------------------------------------------

    u_isram.mem[1] =
        enc_i(
            12'd10,
            5'd0,
            3'b000,
            5'd2,
            7'b0010011
        );


    // --------------------------------------------------------
    // 0x08
    // x3 = 20
    // --------------------------------------------------------

    u_isram.mem[2] =
        enc_i(
            12'd20,
            5'd0,
            3'b000,
            5'd3,
            7'b0010011
        );


    // --------------------------------------------------------
    // 0x0C
    // MEM[0x100] = 10
    //
    // ADDI -> SW dependency also exists for x3/x2 nearby.
    // --------------------------------------------------------

    u_isram.mem[3] =
        enc_s(
            12'd0,
            5'd2,
            5'd1,
            3'b010
        );

    // sw x2,0(x1)


    // --------------------------------------------------------
    // 0x10
    // MEM[0x104] = 20
    // --------------------------------------------------------

    u_isram.mem[4] =
        enc_s(
            12'd4,
            5'd3,
            5'd1,
            3'b010
        );

    // sw x3,4(x1)


    // --------------------------------------------------------
    // 0x14
    // x4 = MEM[0x100] = 10
    // --------------------------------------------------------

    u_isram.mem[5] =
        enc_i(
            12'd0,
            5'd1,
            3'b010,
            5'd4,
            7'b0000011
        );

    // lw x4,0(x1)


    // --------------------------------------------------------
    // 0x18
    // x5 = MEM[0x104] = 20
    // --------------------------------------------------------

    u_isram.mem[6] =
        enc_i(
            12'd4,
            5'd1,
            3'b010,
            5'd5,
            7'b0000011
        );

    // lw x5,4(x1)


    // --------------------------------------------------------
    // 0x1C
    //
    // x6 = x4 + x5 = 30
    //
    // x5 comes directly from previous LW.
    // Therefore:
    //
    //      LW -> ADD
    //
    // real load-use hazard.
    // --------------------------------------------------------

    u_isram.mem[7] =
        enc_r(
            7'b0000000,
            5'd5,
            5'd4,
            3'b000,
            5'd6
        );

    // add x6,x4,x5


    // --------------------------------------------------------
    // 0x20
    // x7 = 30
    // --------------------------------------------------------

    u_isram.mem[8] =
        enc_i(
            12'd30,
            5'd0,
            3'b000,
            5'd7,
            7'b0010011
        );


    // --------------------------------------------------------
    // 0x24
    //
    // if (x6 == x7)
    //     goto correct
    //
    // target = 0x30
    //
    // offset = +12
    //
    // This branch MUST be taken.
    // --------------------------------------------------------

    u_isram.mem[9] =
        enc_b(
            13'd12,
            5'd7,
            5'd6,
            3'b000
        );

    // beq x6,x7,+12


    // --------------------------------------------------------
    // 0x28 WRONG PATH
    //
    // Must NOT modify x20.
    // --------------------------------------------------------

    u_isram.mem[10] =
        enc_i(
            12'd99,
            5'd0,
            3'b000,
            5'd20,
            7'b0010011
        );


    // --------------------------------------------------------
    // 0x2C WRONG PATH STORE
    //
    // Would corrupt MEM[0x110].
    // --------------------------------------------------------

    u_isram.mem[11] =
        enc_s(
            12'd16,
            5'd2,
            5'd1,
            3'b010
        );

    // sw x2,16(x1)
    // WRONG PATH


    // ========================================================
    // CORRECT PATH
    // ========================================================


    // --------------------------------------------------------
    // 0x30
    //
    // Call function at 0x60.
    //
    // JAL PC = 0x30
    //
    // x8 = return address = 0x34
    //
    // target:
    // 0x60 - 0x30 = +0x30
    // --------------------------------------------------------

    u_isram.mem[12] =
        enc_j(
            21'h00030,
            5'd8
        );

    // jal x8,+0x30


    // ========================================================
    // RETURN POINT
    // ========================================================


    // --------------------------------------------------------
    // 0x34
    //
    // Function result:
    //
    // x10 = 31
    //
    // Store result.
    // --------------------------------------------------------

    u_isram.mem[13] =
        enc_s(
            12'd8,
            5'd10,
            5'd1,
            3'b010
        );

    // sw x10,8(x1)
    // MEM[0x108] = 31


    // --------------------------------------------------------
    // 0x38
    // Read result back.
    // --------------------------------------------------------

    u_isram.mem[14] =
        enc_i(
            12'd8,
            5'd1,
            3'b010,
            5'd11,
            7'b0000011
        );

    // lw x11,8(x1)


    // --------------------------------------------------------
    // 0x3C
    //
    // x9 = 31
    //
    // Notice LW x11 is immediately before this ADDI,
    // but ADDI does NOT use x11.
    //
    // Therefore NO false load-use stall should occur.
    // --------------------------------------------------------

    u_isram.mem[15] =
        enc_i(
            12'd31,
            5'd0,
            3'b000,
            5'd9,
            7'b0010011
        );


    // --------------------------------------------------------
    // 0x40
    //
    // bne x11,x9,+8
    //
    // 31 != 31 -> FALSE
    //
    // Branch NOT TAKEN.
    //
    // This also uses the loaded x11 after one intervening
    // instruction.
    // --------------------------------------------------------

    u_isram.mem[16] =
        enc_b(
            13'd8,
            5'd9,
            5'd11,
            3'b001
        );

    // bne x11,x9,+8


    // --------------------------------------------------------
    // 0x44
    //
    // Correct path.
    // --------------------------------------------------------

    u_isram.mem[17] =
        enc_i(
            12'd1,
            5'd0,
            3'b000,
            5'd21,
            7'b0010011
        );

    // addi x21,x0,1


    // --------------------------------------------------------
    // 0x48
    //
    // Jump over failure block.
    //
    // target = 0x50
    // --------------------------------------------------------

    u_isram.mem[18] =
        enc_j(
            21'd8,
            5'd0
        );

    // jal x0,+8


    // --------------------------------------------------------
    // 0x4C WRONG PATH
    // --------------------------------------------------------

    u_isram.mem[19] =
        enc_i(
            12'd88,
            5'd0,
            3'b000,
            5'd20,
            7'b0010011
        );


    // --------------------------------------------------------
    // 0x50 PASS marker
    // --------------------------------------------------------

    u_isram.mem[20] =
        enc_i(
            12'h055,
            5'd0,
            3'b000,
            5'd31,
            7'b0010011
        );

    // addi x31,x0,0x55


    // --------------------------------------------------------
    // 0x54
    // NOP
    // --------------------------------------------------------

    u_isram.mem[21] = 32'h00000013;


    // --------------------------------------------------------
    // 0x58
    // NOP
    // --------------------------------------------------------

    u_isram.mem[22] = 32'h00000013;


    // --------------------------------------------------------
    // 0x5C
    // NOP
    // --------------------------------------------------------

    u_isram.mem[23] = 32'h00000013;


    // ========================================================
    // FUNCTION
    //
    // Entry = 0x60
    //
    // Input:
    //   x6 = 30
    //
    // Return address:
    //   x8 = 0x34
    //
    // Output:
    //   x10 = 31
    // ========================================================


    // --------------------------------------------------------
    // 0x60
    //
    // Save input to memory.
    // --------------------------------------------------------

    u_isram.mem[24] =
        enc_s(
            12'd12,
            5'd6,
            5'd1,
            3'b010
        );

    // sw x6,12(x1)
    // MEM[0x10C] = 30


    // --------------------------------------------------------
    // 0x64
    //
    // Load it back.
    // --------------------------------------------------------

    u_isram.mem[25] =
        enc_i(
            12'd12,
            5'd1,
            3'b010,
            5'd12,
            7'b0000011
        );

    // lw x12,12(x1)


    // --------------------------------------------------------
    // 0x68
    //
    // Immediate consumer.
    //
    // LW -> ADDI load-use hazard.
    //
    // x10 = 30 + 1 = 31
    // --------------------------------------------------------

    u_isram.mem[26] =
        enc_i(
            12'd1,
            5'd12,
            3'b000,
            5'd10,
            7'b0010011
        );

    // addi x10,x12,1


    // --------------------------------------------------------
    // 0x6C
    //
    // Return:
    //
    // jalr x0,0(x8)
    //
    // target = 0x34
    //
    // rd=x0 -> no WB.
    // --------------------------------------------------------

    u_isram.mem[27] =
        enc_i(
            12'd0,
            5'd8,
            3'b000,
            5'd0,
            7'b1100111
        );

    // jalr x0,0(x8)


    // ========================================================
    // Remaining ISRAM
    // ========================================================

    for (int i=28; i<128; i++) begin
        u_isram.mem[i] = 32'h00000013;
    end


    // ========================================================
    // DSRAM initialization
    // ========================================================

    u_dsram.mem[64] = 32'hAAAAAAAA;
    // 0x100

    u_dsram.mem[65] = 32'hBBBBBBBB;
    // 0x104

    u_dsram.mem[66] = 32'hCCCCCCCC;
    // 0x108

    u_dsram.mem[67] = 32'hDDDDDDDD;
    // 0x10C

    u_dsram.mem[68] = 32'hDEADBEEF;
    // 0x110
    // wrong-path store protection


    // ========================================================
    // Expected WB stream
    // ========================================================

    expected_wb_rd[0]   = 5'd1;
    expected_wb_data[0] = 32'h00000100;

    expected_wb_rd[1]   = 5'd2;
    expected_wb_data[1] = 32'd10;

    expected_wb_rd[2]   = 5'd3;
    expected_wb_data[2] = 32'd20;


    expected_wb_rd[3]   = 5'd4;
    expected_wb_data[3] = 32'd10;

    expected_wb_rd[4]   = 5'd5;
    expected_wb_data[4] = 32'd20;

    expected_wb_rd[5]   = 5'd6;
    expected_wb_data[5] = 32'd30;

    expected_wb_rd[6]   = 5'd7;
    expected_wb_data[6] = 32'd30;


    // JAL @0x30
    expected_wb_rd[7]   = 5'd8;
    expected_wb_data[7] = 32'h00000034;


    // Function LW
    expected_wb_rd[8]   = 5'd12;
    expected_wb_data[8] = 32'd30;

    // Function result
    expected_wb_rd[9]   = 5'd10;
    expected_wb_data[9] = 32'd31;


    // Main result LW
    expected_wb_rd[10]   = 5'd11;
    expected_wb_data[10] = 32'd31;

    expected_wb_rd[11]   = 5'd9;
    expected_wb_data[11] = 32'd31;

    expected_wb_rd[12]   = 5'd21;
    expected_wb_data[12] = 32'd1;

    expected_wb_rd[13]   = 5'd31;
    expected_wb_data[13] = 32'h00000055;


    // ========================================================
    // Expected redirect stream
    //
    // 1. BEQ taken
    // 2. JAL function
    // 3. JALR return
    // 4. JAL x0 final
    //
    // Wait: that's FOUR redirects.
    // ========================================================

    // Set below after correcting count.

    expected_redirect_pc[0] = 32'h00000030;
    expected_redirect_pc[1] = 32'h00000060;
    expected_redirect_pc[2] = 32'h00000034;


    // ========================================================
    // Release reset
    // ========================================================

    #20;
    rst_n = 1'b1;

    wait(test_done);

    @(posedge clk);
    #1;


    // ========================================================
    // Final architectural state
    // ========================================================

    check_reg(5'd6,  32'd30);
    check_reg(5'd10, 32'd31);
    check_reg(5'd11, 32'd31);
    check_reg(5'd21, 32'd1);
    check_reg(5'd31, 32'h55);


    // ========================================================
    // Memory state
    // ========================================================

    if (u_dsram.mem[64] !== 32'd10) begin
        $error(
            "[MEM 0x100] expected=10 actual=%08h",
            u_dsram.mem[64]
        );
        errors++;
    end

    if (u_dsram.mem[65] !== 32'd20) begin
        $error(
            "[MEM 0x104] expected=20 actual=%08h",
            u_dsram.mem[65]
        );
        errors++;
    end

    if (u_dsram.mem[66] !== 32'd31) begin
        $error(
            "[MEM 0x108] expected=31 actual=%08h",
            u_dsram.mem[66]
        );
        errors++;
    end

    if (u_dsram.mem[67] !== 32'd30) begin
        $error(
            "[MEM 0x10C] expected=30 actual=%08h",
            u_dsram.mem[67]
        );
        errors++;
    end

    if (u_dsram.mem[68] !== 32'hDEADBEEF) begin
        $error(
            "[WRONG PATH STORE] MEM[0x110] changed to %08h",
            u_dsram.mem[68]
        );
        errors++;
    end


    report_result("INTEGRATION_TEST");

    $finish;

end


// ============================================================
// WB scoreboard
// ============================================================

always @(posedge clk) begin

    if (rst_n && u_cpu.wb_we) begin

        if (wb_idx >= EXPECTED_WB_COUNT) begin

            $error(
                "[WB EXTRA] x%0d=%08h",
                u_cpu.wb_rd,
                u_cpu.wb_data
            );

            errors++;

        end
        else begin

            if ((u_cpu.wb_rd !== expected_wb_rd[wb_idx]) ||
                (u_cpu.wb_data !== expected_wb_data[wb_idx])) begin

                $error(
                    "[WB #%0d] expected x%0d=%08h actual x%0d=%08h",
                    wb_idx,
                    expected_wb_rd[wb_idx],
                    expected_wb_data[wb_idx],
                    u_cpu.wb_rd,
                    u_cpu.wb_data
                );

                errors++;

            end
            else begin

                $display(
                    "[WB PASS] #%0d x%0d = %08h",
                    wb_idx,
                    u_cpu.wb_rd,
                    u_cpu.wb_data
                );

            end

            wb_idx++;

            if (wb_idx == EXPECTED_WB_COUNT)begin
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
// ============================================================

always @(negedge clk) begin

    if (rst_n && u_cpu.redirect_valid) begin

        if (redirect_idx >= 4) begin

            $error(
                "[REDIRECT EXTRA] target=%08h",
                u_cpu.redirect_pc
            );

            errors++;

        end
        else begin

            case (redirect_idx)

                0: begin
                    if (u_cpu.redirect_pc !== 32'h00000030) begin
                        $error(
                            "[REDIRECT 0] expected=00000030 actual=%08h",
                            u_cpu.redirect_pc
                        );
                        errors++;
                    end
                end

                1: begin
                    if (u_cpu.redirect_pc !== 32'h00000060) begin
                        $error(
                            "[REDIRECT 1] expected=00000060 actual=%08h",
                            u_cpu.redirect_pc
                        );
                        errors++;
                    end
                end

                2: begin
                    if (u_cpu.redirect_pc !== 32'h00000034) begin
                        $error(
                            "[REDIRECT 2] expected=00000034 actual=%08h",
                            u_cpu.redirect_pc
                        );
                        errors++;
                    end
                end

                3: begin
                    if (u_cpu.redirect_pc !== 32'h00000050) begin
                        $error(
                            "[REDIRECT 3] expected=00000050 actual=%08h",
                            u_cpu.redirect_pc
                        );
                        errors++;
                    end
                end

            endcase

            $display(
                "[REDIRECT] #%0d target=%08h",
                redirect_idx,
                u_cpu.redirect_pc
            );

        end

        redirect_idx++;

    end

end


// ============================================================
// Timeout
// ============================================================

initial begin

    #20000;

    if (!test_done) begin

        $error(
            "[TIMEOUT] wb=%0d/%0d redirect=%0d/4",
            wb_idx,
            EXPECTED_WB_COUNT,
            redirect_idx
        );

        errors++;

        report_result("INTEGRATION_TEST");

        $finish;

    end

end