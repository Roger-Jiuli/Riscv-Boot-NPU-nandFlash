// ============================================================
// alu_test.sv
// ============================================================

localparam int EXPECTED_WB_COUNT = 35;
localparam int EXPECTED_CYCLES = 41;

logic [4:0]  expected_wb_rd   [0:EXPECTED_WB_COUNT-1];
logic [31:0] expected_wb_data [0:EXPECTED_WB_COUNT-1];

integer wb_idx;
logic   test_done;
logic [31:0] actual_cycles;


// ============================================================
// Instruction encoding helpers
// ============================================================

function automatic [31:0] enc_r(
    input [6:0] funct7,
    input [4:0] rs2,
    input [4:0] rs1,
    input [2:0] funct3,
    input [4:0] rd
);
begin
    enc_r = {funct7, rs2, rs1, funct3, rd, 7'b0110011};
end
endfunction


function automatic [31:0] enc_i(
    input [11:0] imm,
    input [4:0]  rs1,
    input [2:0]  funct3,
    input [4:0]  rd
);
begin
    enc_i = {imm, rs1, funct3, rd, 7'b0010011};
end
endfunction


function automatic [31:0] enc_u(
    input [19:0] imm20,
    input [4:0]  rd,
    input [6:0]  opcode
);
begin
    enc_u = {imm20, rd, opcode};
end
endfunction


// ============================================================
// Main
// ============================================================

initial begin

    errors    = 0;
    wb_idx    = 0;
    test_done = 1'b0;
    actual_cycles = 0;

    rst_n = 1'b0;


    // ========================================================
    // Prepare operands
    // ========================================================

    // 0x00
    u_isram.mem[0] =
        enc_i(12'd10, 5'd0, 3'b000, 5'd1);
    // addi x1,x0,10

    // 0x04
    u_isram.mem[1] =
        enc_i(12'd3, 5'd0, 3'b000, 5'd2);
    // addi x2,x0,3

    // 0x08
    u_isram.mem[2] =
        enc_i(12'hFFF, 5'd0, 3'b000, 5'd3);
    // addi x3,x0,-1


    // ========================================================
    // R-TYPE
    // ========================================================

    // ADD: 10 + 3 = 13
    u_isram.mem[3] =
        enc_r(7'b0000000,5'd2,5'd1,3'b000,5'd4);

    // SUB: 3 - 10 = -7
    u_isram.mem[4] =
        enc_r(7'b0100000,5'd1,5'd2,3'b000,5'd5);

    // SLL: 10 << 3 = 80
    u_isram.mem[5] =
        enc_r(7'b0000000,5'd2,5'd1,3'b001,5'd6);

    // SLT: -1 < 10 signed => 1
    u_isram.mem[6] =
        enc_r(7'b0000000,5'd1,5'd3,3'b010,5'd7);

    // SLTU: FFFFFFFF < 10 unsigned => 0
    u_isram.mem[7] =
        enc_r(7'b0000000,5'd1,5'd3,3'b011,5'd8);

    // XOR: 10 ^ 3 = 9
    u_isram.mem[8] =
        enc_r(7'b0000000,5'd2,5'd1,3'b100,5'd9);

    // SRL: 10 >> 3 = 1
    u_isram.mem[9] =
        enc_r(7'b0000000,5'd2,5'd1,3'b101,5'd10);

    // SRA: -1 >>> 3 = FFFFFFFF
    u_isram.mem[10] =
        enc_r(7'b0100000,5'd2,5'd3,3'b101,5'd11);

    // OR: 10 | 3 = 11
    u_isram.mem[11] =
        enc_r(7'b0000000,5'd2,5'd1,3'b110,5'd12);

    // AND: 10 & 3 = 2
    u_isram.mem[12] =
        enc_r(7'b0000000,5'd2,5'd1,3'b111,5'd13);


    // ========================================================
    // I-TYPE ALU
    // ========================================================

    // ADDI: 10 + (-5) = 5
    u_isram.mem[13] =
        enc_i(12'hFFB,5'd1,3'b000,5'd14);

    // SLTI: -1 < 1 signed => 1
    u_isram.mem[14] =
        enc_i(12'd1,5'd3,3'b010,5'd15);

    // SLTIU: FFFFFFFF < 1 unsigned => 0
    u_isram.mem[15] =
        enc_i(12'd1,5'd3,3'b011,5'd16);

    // XORI: 10 ^ 15 = 5
    u_isram.mem[16] =
        enc_i(12'd15,5'd1,3'b100,5'd17);

    // ORI: 10 | 5 = 15
    u_isram.mem[17] =
        enc_i(12'd5,5'd1,3'b110,5'd18);

    // ANDI: 10 & 6 = 2
    u_isram.mem[18] =
        enc_i(12'd6,5'd1,3'b111,5'd19);


    // ========================================================
    // Immediate shifts
    // ========================================================

    // SLLI: 1 << 31 = 80000000
    u_isram.mem[19] =
        enc_i({7'b0000000,5'd31},
              5'd0,
              3'b001,
              5'd20);

    // Wait:
    // rs1=x0 would give 0.
    //
    // Need x21=1 first.
    // Replace above with ADDI x20=1,
    // then perform shifts below.
    // ========================================================

    u_isram.mem[19] =
        enc_i(12'd1,5'd0,3'b000,5'd20);
    // addi x20,x0,1

    // SLLI x21,x20,31
    u_isram.mem[20] =
        enc_i({7'b0000000,5'd31},
              5'd20,
              3'b001,
              5'd21);
    // = 80000000

    // SRLI x22,x21,31
    u_isram.mem[21] =
        enc_i({7'b0000000,5'd31},
              5'd21,
              3'b101,
              5'd22);
    // = 1

    // SRAI x23,x21,31
    u_isram.mem[22] =
        enc_i({7'b0100000,5'd31},
              5'd21,
              3'b101,
              5'd23);
    // = FFFFFFFF


    // ========================================================
    // Shift amount = 0
    // ========================================================

    // SLLI x24,x1,0 => 10
    u_isram.mem[23] =
        enc_i({7'b0000000,5'd0},
              5'd1,
              3'b001,
              5'd24);

    // SRLI x25,x1,0 => 10
    u_isram.mem[24] =
        enc_i({7'b0000000,5'd0},
              5'd1,
              3'b101,
              5'd25);


    // ========================================================
    // LUI
    // ========================================================

    // x26 = 12345000
    u_isram.mem[25] =
        enc_u(20'h12345,5'd26,7'b0110111);


    // ========================================================
    // AUIPC
    //
    // PC = index * 4
    //    = 26 * 4
    //    = 0x68
    //
    // imm = 0x00001000
    //
    // result = 0x1068
    // ========================================================

    u_isram.mem[26] =
        enc_u(20'h00001,5'd27,7'b0010111);


    // ========================================================
    // More edge cases
    // ========================================================

    // SUB x28,x0,x20
    // 0 - 1 = FFFFFFFF
    u_isram.mem[27] =
        enc_r(7'b0100000,5'd20,5'd0,3'b000,5'd28);


    // SRL FFFFFFFF >> 1 = 7FFFFFFF
    u_isram.mem[28] =
        enc_r(7'b0000000,5'd20,5'd3,3'b101,5'd29);


    // SRA FFFFFFFF >>> 1 = FFFFFFFF
    u_isram.mem[29] =
        enc_r(7'b0100000,5'd20,5'd3,3'b101,5'd30);


    // ========================================================
    // x0 write protection
    //
    // Architecturally this instruction executes, but there
    // must be NO wb_we because rd=x0.
    // ========================================================

    u_isram.mem[30] =
        enc_i(12'd123,5'd0,3'b000,5'd0);
    // addi x0,x0,123


    // Verify x0 still behaves as zero.
    u_isram.mem[31] =
        enc_i(12'd31,5'd0,3'b000,5'd4);
    // x4 = 31


    // ========================================================
    // A few dependency chains
    //
    // Also exercises normal ALU forwarding.
    // ========================================================

    u_isram.mem[32] =
        enc_i(12'd1,5'd4,3'b000,5'd5);
    // x5 = 32

    u_isram.mem[33] =
        enc_i(12'd1,5'd5,3'b000,5'd6);
    // x6 = 33

    u_isram.mem[34] =
        enc_i(12'd1,5'd6,3'b000,5'd7);
    // x7 = 34


    // ========================================================
    // End marker
    // ========================================================

    u_isram.mem[35] =
        enc_i(12'h055,5'd0,3'b000,5'd31);
    // addi x31,x0,0x55


    // NOP
    for (int i=36; i<128; i++) begin
        u_isram.mem[i] = 32'h00000013;
    end


    // ========================================================
    // Expected WB stream
    // ========================================================

    expected_wb_rd[0]=1;   expected_wb_data[0]=10;
    expected_wb_rd[1]=2;   expected_wb_data[1]=3;
    expected_wb_rd[2]=3;   expected_wb_data[2]=32'hFFFFFFFF;

    expected_wb_rd[3]=4;   expected_wb_data[3]=13;
    expected_wb_rd[4]=5;   expected_wb_data[4]=32'hFFFFFFF9;
    expected_wb_rd[5]=6;   expected_wb_data[5]=80;
    expected_wb_rd[6]=7;   expected_wb_data[6]=1;
    expected_wb_rd[7]=8;   expected_wb_data[7]=0;
    expected_wb_rd[8]=9;   expected_wb_data[8]=9;
    expected_wb_rd[9]=10;  expected_wb_data[9]=1;
    expected_wb_rd[10]=11; expected_wb_data[10]=32'hFFFFFFFF;
    expected_wb_rd[11]=12; expected_wb_data[11]=11;
    expected_wb_rd[12]=13; expected_wb_data[12]=2;

    expected_wb_rd[13]=14; expected_wb_data[13]=5;
    expected_wb_rd[14]=15; expected_wb_data[14]=1;
    expected_wb_rd[15]=16; expected_wb_data[15]=0;
    expected_wb_rd[16]=17; expected_wb_data[16]=5;
    expected_wb_rd[17]=18; expected_wb_data[17]=15;
    expected_wb_rd[18]=19; expected_wb_data[18]=2;

    expected_wb_rd[19]=20; expected_wb_data[19]=1;
    expected_wb_rd[20]=21; expected_wb_data[20]=32'h80000000;
    expected_wb_rd[21]=22; expected_wb_data[21]=1;
    expected_wb_rd[22]=23; expected_wb_data[22]=32'hFFFFFFFF;

    expected_wb_rd[23]=24; expected_wb_data[23]=10;
    expected_wb_rd[24]=25; expected_wb_data[24]=10;

    expected_wb_rd[25]=26; expected_wb_data[25]=32'h12345000;

    expected_wb_rd[26]=27; expected_wb_data[26]=32'h00001068;
    // AUIPC = PC 0x68 + 0x1000

    expected_wb_rd[27]=28; expected_wb_data[27]=32'hFFFFFFFF;
    expected_wb_rd[28]=29; expected_wb_data[28]=32'h7FFFFFFF;
    expected_wb_rd[29]=30; expected_wb_data[29]=32'hFFFFFFFF;

    // index 30 writes x0 -> NO architectural WB

    expected_wb_rd[30]=4;  expected_wb_data[30]=31;
    expected_wb_rd[31]=5;  expected_wb_data[31]=32;
    expected_wb_rd[32]=6;  expected_wb_data[32]=33;
    expected_wb_rd[33]=7;  expected_wb_data[33]=34;

    expected_wb_rd[34]=31; expected_wb_data[34]=32'h55;


    // ========================================================
    // IMPORTANT:
    //
    // There are 35 architectural writes, NOT 36,
    // because ADDI x0,x0,123 must not produce wb_we.
    // ========================================================

    #20;
    rst_n = 1'b1;

    wait(test_done);

    @(posedge clk);
    #1;


    // x0 must remain zero
    if (u_cpu.u_id_stage.u_regfile.regs[0] !== 32'h0) begin
        $error(
            "[X0] expected=00000000 actual=%08h",
            u_cpu.u_id_stage.u_regfile.regs[0]
        );
        errors++;
    end


    report_result("ALU_TEST");

    $finish;

end


// ============================================================
// WB scoreboard
// ============================================================

always @(posedge clk) begin

    if (rst_n && u_cpu.wb_we) begin

        if (wb_idx >= 35) begin

            $error(
                "[WB EXTRA] rd=x%0d data=%08h",
                u_cpu.wb_rd,
                u_cpu.wb_data
            );

            errors++;

        end
        else begin

            if ((u_cpu.wb_rd !== expected_wb_rd[wb_idx]) ||
                (u_cpu.wb_data !== expected_wb_data[wb_idx])) begin

                $error(
                    "[WB #%0d] expected x%0d=%08h, actual x%0d=%08h",
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
// Negative mechanism checks
//
// Pure ALU program:
//   no redirect
//   no memory stall
//   no load-use
// ============================================================

always @(negedge clk) begin

    if (rst_n) begin

        if (u_cpu.redirect_valid) begin
            $error("[UNEXPECTED REDIRECT]");
            errors++;
        end

        if (u_cpu.mem_stall) begin
            $error("[UNEXPECTED MEM STALL]");
            errors++;
        end

        if (u_cpu.load_use_hazard) begin
            $error("[UNEXPECTED LOAD-USE HAZARD]");
            errors++;
        end

    end

end


// ============================================================
// Timeout
// ============================================================

initial begin

    #10000;

    if (!test_done) begin

        $error(
            "[TIMEOUT] wb_idx=%0d/35",
            wb_idx
        );

        errors++;

        report_result("ALU_TEST");
        $finish;

    end

end