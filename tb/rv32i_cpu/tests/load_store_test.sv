// ============================================================
// load_store_test.svh
// ============================================================
//
// Verification layers:
//
//   1. WB scoreboard
//      Every architectural register write is checked.
//
//   2. DMEM transaction scoreboard
//      Every Load/Store transaction is checked:
//      R/W + addr + wdata + wstrb.
//
//   3. DMEM protocol checker
//      Request must remain stable while waiting for ready.
//
//   4. Final SRAM state
//
// Cycle performance check will be added AFTER functional PASS.
//
// ============================================================


// ============================================================
// Expected WB stream
// ============================================================

localparam int EXPECTED_WB_COUNT = 47;
localparam int EXPECTED_CYCLES = 218;

logic [4:0]  expected_wb_rd   [0:EXPECTED_WB_COUNT-1];
logic [31:0] expected_wb_data [0:EXPECTED_WB_COUNT-1];
logic [31:0] actual_cycles;

integer wb_idx;


// ============================================================
// Expected DMEM transaction stream
// ============================================================

localparam int EXPECTED_DMEM_COUNT = 47;

logic        expected_dmem_write [0:EXPECTED_DMEM_COUNT-1];
logic [31:0] expected_dmem_addr  [0:EXPECTED_DMEM_COUNT-1];
logic [31:0] expected_dmem_wdata [0:EXPECTED_DMEM_COUNT-1];
logic [3:0]  expected_dmem_wstrb [0:EXPECTED_DMEM_COUNT-1];

integer dmem_idx;


// ============================================================
// Test control
// ============================================================

logic test_done;


// ============================================================
// Outstanding DMEM request snapshot
// ============================================================

logic        req_waiting;

logic        saved_read;
logic        saved_write;

logic [31:0] saved_addr;
logic [31:0] saved_wdata;
logic [3:0]  saved_wstrb;


// ============================================================
// Main test
// ============================================================

initial begin

    errors      = 0;
    wb_idx      = 0;
    dmem_idx    = 0;
    test_done   = 1'b0;
    req_waiting = 1'b0;
    actual_cycles = 0;

    rst_n = 1'b0;


    // ========================================================
    // Program
    //
    // Base address:
    //
    // x1 = 128 = 0x80
    // ========================================================

    u_isram.mem[0]  = 32'h08000093; // addi x1,x0,128

    // --------------------------------------------------------
    // CASE 1 : SW -> LW
    // --------------------------------------------------------

    u_isram.mem[1]  = 32'h00B00113; // addi x2,x0,11
    u_isram.mem[2]  = 32'h0020A023; // sw   x2,0(x1)
    u_isram.mem[3]  = 32'h0000A183; // lw   x3,0(x1)


    // --------------------------------------------------------
    // CASE 2 : SW -> SW -> SW
    // --------------------------------------------------------

    u_isram.mem[4]  = 32'h01500213; // addi x4,x0,21
    u_isram.mem[5]  = 32'h01600293; // addi x5,x0,22
    u_isram.mem[6]  = 32'h01700313; // addi x6,x0,23

    u_isram.mem[7]  = 32'h0040A223; // sw x4,4(x1)
    u_isram.mem[8]  = 32'h0050A423; // sw x5,8(x1)
    u_isram.mem[9]  = 32'h0060A623; // sw x6,12(x1)


    // --------------------------------------------------------
    // CASE 3 : LW -> LW -> LW
    // --------------------------------------------------------

    u_isram.mem[10] = 32'h0040A383; // lw x7,4(x1)
    u_isram.mem[11] = 32'h0080A403; // lw x8,8(x1)
    u_isram.mem[12] = 32'h00C0A483; // lw x9,12(x1)


    // --------------------------------------------------------
    // CASE 4 : SW -> LW -> SW -> LW
    // --------------------------------------------------------

    u_isram.mem[13] = 32'h01F00513; // addi x10,x0,31
    u_isram.mem[14] = 32'h00A0A823; // sw   x10,16(x1)
    u_isram.mem[15] = 32'h0100A583; // lw   x11,16(x1)
    u_isram.mem[16] = 32'h00B0AA23; // sw   x11,20(x1)
    u_isram.mem[17] = 32'h0140A603; // lw   x12,20(x1)


    // --------------------------------------------------------
    // CASE 5 : SW -> SB -> LW
    //
    // 0x00000123
    //       ↓ SB 0x45 @ byte1
    // 0x00004523
    // --------------------------------------------------------

    u_isram.mem[18] = 32'h12300693; // addi x13,x0,0x123
    u_isram.mem[19] = 32'h00D0AC23; // sw   x13,24(x1)

    u_isram.mem[20] = 32'h04500713; // addi x14,x0,0x45
    u_isram.mem[21] = 32'h00E08CA3; // sb   x14,25(x1)

    u_isram.mem[22] = 32'h0180A783; // lw x15,24(x1)


    // --------------------------------------------------------
    // CASE 6 : SW -> SH -> LW
    //
    // 0x00000123
    //       ↓ SH 0x0067 @ upper half
    // 0x00670123
    // --------------------------------------------------------

    u_isram.mem[23] = 32'h12300813; // addi x16,x0,0x123
    u_isram.mem[24] = 32'h0100AE23; // sw   x16,28(x1)

    u_isram.mem[25] = 32'h06700893; // addi x17,x0,0x67
    u_isram.mem[26] = 32'h01109F23; // sh   x17,30(x1)

    u_isram.mem[27] = 32'h01C0A903; // lw x18,28(x1)


    // --------------------------------------------------------
    // CASE 7 : SB x4 -> LW
    //
    // +0 = 11
    // +1 = 22
    // +2 = 33
    // +3 = 44
    //
    // LW = 0x44332211
    // --------------------------------------------------------

    u_isram.mem[28] = 32'h01100993; // addi x19,x0,0x11
    u_isram.mem[29] = 32'h02200A13; // addi x20,x0,0x22
    u_isram.mem[30] = 32'h03300A93; // addi x21,x0,0x33
    u_isram.mem[31] = 32'h04400B13; // addi x22,x0,0x44

    u_isram.mem[32] = 32'h03308023; // sb x19,32(x1)
    u_isram.mem[33] = 32'h034080A3; // sb x20,33(x1)
    u_isram.mem[34] = 32'h03508123; // sb x21,34(x1)
    u_isram.mem[35] = 32'h036081A3; // sb x22,35(x1)

    u_isram.mem[36] = 32'h0200AB83; // lw x23,32(x1)


    // --------------------------------------------------------
    // CASE 8 : SH x2 -> LW
    //
    // lower = 0x0123
    // upper = 0x0456
    //
    // LW = 0x04560123
    // --------------------------------------------------------

    u_isram.mem[37] = 32'h12300C13; // addi x24,x0,0x123
    u_isram.mem[38] = 32'h45600C93; // addi x25,x0,0x456

    u_isram.mem[39] = 32'h03809223; // sh x24,36(x1)
    u_isram.mem[40] = 32'h03909323; // sh x25,38(x1)

    u_isram.mem[41] = 32'h0240AD03; // lw x26,36(x1)


    // --------------------------------------------------------
    // CASE 9 :
    //
    // Build 0x80FF7F01
    //
    // LUI:
    //      0x80FF8000
    //
    // ADDI -255:
    //      0x80FF7F01
    //
    // Then exercise every load lane/type.
    // --------------------------------------------------------

    u_isram.mem[42] = 32'h80FF8DB7; // lui  x27,0x80FF8
    u_isram.mem[43] = 32'hF01D8D93; // addi x27,x27,-255

    u_isram.mem[44] = 32'h03B0A423; // sw x27,40(x1)

    // LB every byte lane

    u_isram.mem[45] = 32'h02808E03; // lb x28,40(x1) -> 00000001
    u_isram.mem[46] = 32'h02908E83; // lb x29,41(x1) -> 0000007F
    u_isram.mem[47] = 32'h02A08F03; // lb x30,42(x1) -> FFFFFFFF
    u_isram.mem[48] = 32'h02B08F83; // lb x31,43(x1) -> FFFFFF80

    // LBU

    u_isram.mem[49] = 32'h02A0C103; // lbu x2,42(x1) -> 000000FF
    u_isram.mem[50] = 32'h02B0C183; // lbu x3,43(x1) -> 00000080

    // LH

    u_isram.mem[51] = 32'h02809203; // lh x4,40(x1) -> 00007F01
    u_isram.mem[52] = 32'h02A09283; // lh x5,42(x1) -> FFFF80FF

    // LHU

    u_isram.mem[53] = 32'h0280D303; // lhu x6,40(x1) -> 00007F01
    u_isram.mem[54] = 32'h02A0D383; // lhu x7,42(x1) -> 000080FF


    // --------------------------------------------------------
    // CASE 10 : mixed-width store
    //
    // SW 0
    // SB 12 @ byte0
    // SB 34 @ byte1
    // SH 0567 @ upper half
    //
    // result = 0x05673412
    // --------------------------------------------------------

    u_isram.mem[55] = 32'h0200A623; // sw x0,44(x1)

    u_isram.mem[56] = 32'h01200413; // addi x8,x0,0x12
    u_isram.mem[57] = 32'h02808623; // sb x8,44(x1)

    u_isram.mem[58] = 32'h03400493; // addi x9,x0,0x34
    u_isram.mem[59] = 32'h029086A3; // sb x9,45(x1)

    u_isram.mem[60] = 32'h56700513; // addi x10,x0,0x567
    u_isram.mem[61] = 32'h02A09723; // sh x10,46(x1)

    u_isram.mem[62] = 32'h02C0A583; // lw x11,44(x1)


    // --------------------------------------------------------
    // CASE 11 : LW -> SW
    //
    // Intentional load-use dependency on store data.
    // --------------------------------------------------------

    u_isram.mem[63] = 32'h02C0A603; // lw x12,44(x1)
    u_isram.mem[64] = 32'h02C0A823; // sw x12,48(x1)
    u_isram.mem[65] = 32'h0300A683; // lw x13,48(x1)


    // --------------------------------------------------------
    // CASE 12 : ADDI -> SW
    //
    // Store-data forwarding.
    // --------------------------------------------------------

    u_isram.mem[66] = 32'h02A00713; // addi x14,x0,42
    u_isram.mem[67] = 32'h02E0AA23; // sw   x14,52(x1)
    u_isram.mem[68] = 32'h0340A783; // lw   x15,52(x1)


    // --------------------------------------------------------
    // End marker
    // --------------------------------------------------------

    u_isram.mem[69] = 32'h05500F93; // addi x31,x0,0x55


    for (int i = 70; i < 128; i++)
        u_isram.mem[i] = 32'h00000013;


    // ========================================================
    // Clear DSRAM test region
    // ========================================================

    for (int i = 32; i < 64; i++)
        u_dsram.mem[i] = 32'b0;


    // ========================================================
    // Expected WB stream
    //
    // EVERY instruction that writes rd appears here.
    // Stores do not.
    // ========================================================

    expected_wb_rd[0]   = 5'd1;
    expected_wb_data[0] = 32'h00000080;

    expected_wb_rd[1]   = 5'd2;
    expected_wb_data[1] = 32'h0000000B;

    expected_wb_rd[2]   = 5'd3;
    expected_wb_data[2] = 32'h0000000B;

    expected_wb_rd[3]   = 5'd4;
    expected_wb_data[3] = 32'h00000015;

    expected_wb_rd[4]   = 5'd5;
    expected_wb_data[4] = 32'h00000016;

    expected_wb_rd[5]   = 5'd6;
    expected_wb_data[5] = 32'h00000017;

    expected_wb_rd[6]   = 5'd7;
    expected_wb_data[6] = 32'h00000015;

    expected_wb_rd[7]   = 5'd8;
    expected_wb_data[7] = 32'h00000016;

    expected_wb_rd[8]   = 5'd9;
    expected_wb_data[8] = 32'h00000017;

    expected_wb_rd[9]   = 5'd10;
    expected_wb_data[9] = 32'h0000001F;

    expected_wb_rd[10]   = 5'd11;
    expected_wb_data[10] = 32'h0000001F;

    expected_wb_rd[11]   = 5'd12;
    expected_wb_data[11] = 32'h0000001F;

    expected_wb_rd[12]   = 5'd13;
    expected_wb_data[12] = 32'h00000123;

    expected_wb_rd[13]   = 5'd14;
    expected_wb_data[13] = 32'h00000045;

    expected_wb_rd[14]   = 5'd15;
    expected_wb_data[14] = 32'h00004523;

    expected_wb_rd[15]   = 5'd16;
    expected_wb_data[15] = 32'h00000123;

    expected_wb_rd[16]   = 5'd17;
    expected_wb_data[16] = 32'h00000067;

    expected_wb_rd[17]   = 5'd18;
    expected_wb_data[17] = 32'h00670123;

    expected_wb_rd[18]   = 5'd19;
    expected_wb_data[18] = 32'h00000011;

    expected_wb_rd[19]   = 5'd20;
    expected_wb_data[19] = 32'h00000022;

    expected_wb_rd[20]   = 5'd21;
    expected_wb_data[20] = 32'h00000033;

    expected_wb_rd[21]   = 5'd22;
    expected_wb_data[21] = 32'h00000044;

    expected_wb_rd[22]   = 5'd23;
    expected_wb_data[22] = 32'h44332211;

    expected_wb_rd[23]   = 5'd24;
    expected_wb_data[23] = 32'h00000123;

    expected_wb_rd[24]   = 5'd25;
    expected_wb_data[24] = 32'h00000456;

    expected_wb_rd[25]   = 5'd26;
    expected_wb_data[25] = 32'h04560123;

    // LUI intermediate value
    expected_wb_rd[26]   = 5'd27;
    expected_wb_data[26] = 32'h80FF8000;

    // ADDI after LUI
    expected_wb_rd[27]   = 5'd27;
    expected_wb_data[27] = 32'h80FF7F01;

    // LB results
    expected_wb_rd[28]   = 5'd28;
    expected_wb_data[28] = 32'h00000001;

    expected_wb_rd[29]   = 5'd29;
    expected_wb_data[29] = 32'h0000007F;

    expected_wb_rd[30]   = 5'd30;
    expected_wb_data[30] = 32'hFFFFFFFF;

    // This is the intermediate x31 result that the old TB missed.
    expected_wb_rd[31]   = 5'd31;
    expected_wb_data[31] = 32'hFFFFFF80;

    // LBU
    expected_wb_rd[32]   = 5'd2;
    expected_wb_data[32] = 32'h000000FF;

    expected_wb_rd[33]   = 5'd3;
    expected_wb_data[33] = 32'h00000080;

    // LH
    expected_wb_rd[34]   = 5'd4;
    expected_wb_data[34] = 32'h00007F01;

    expected_wb_rd[35]   = 5'd5;
    expected_wb_data[35] = 32'hFFFF80FF;

    // LHU
    expected_wb_rd[36]   = 5'd6;
    expected_wb_data[36] = 32'h00007F01;

    expected_wb_rd[37]   = 5'd7;
    expected_wb_data[37] = 32'h000080FF;

    expected_wb_rd[38]   = 5'd8;
    expected_wb_data[38] = 32'h00000012;

    expected_wb_rd[39]   = 5'd9;
    expected_wb_data[39] = 32'h00000034;

    expected_wb_rd[40]   = 5'd10;
    expected_wb_data[40] = 32'h00000567;

    expected_wb_rd[41]   = 5'd11;
    expected_wb_data[41] = 32'h05673412;

    expected_wb_rd[42]   = 5'd12;
    expected_wb_data[42] = 32'h05673412;

    expected_wb_rd[43]   = 5'd13;
    expected_wb_data[43] = 32'h05673412;

    expected_wb_rd[44]   = 5'd14;
    expected_wb_data[44] = 32'h0000002A;

    expected_wb_rd[45]   = 5'd15;
    expected_wb_data[45] = 32'h0000002A;

    // End marker
    expected_wb_rd[46]   = 5'd31;
    expected_wb_data[46] = 32'h00000055;


    // ========================================================
    // Expected DMEM transactions
    //
    // For READ:
    //   wdata/wstrb are don't-care and are not compared.
    //
    // For WRITE:
    //   addr/wdata/wstrb are all compared.
    // ========================================================

    // SW -> LW
    expected_dmem_write[0]=1; expected_dmem_addr[0]=32'h80; expected_dmem_wdata[0]=32'h0000000B; expected_dmem_wstrb[0]=4'hF;
    expected_dmem_write[1]=0; expected_dmem_addr[1]=32'h80;

    // SW SW SW
    expected_dmem_write[2]=1; expected_dmem_addr[2]=32'h84; expected_dmem_wdata[2]=32'h00000015; expected_dmem_wstrb[2]=4'hF;
    expected_dmem_write[3]=1; expected_dmem_addr[3]=32'h88; expected_dmem_wdata[3]=32'h00000016; expected_dmem_wstrb[3]=4'hF;
    expected_dmem_write[4]=1; expected_dmem_addr[4]=32'h8C; expected_dmem_wdata[4]=32'h00000017; expected_dmem_wstrb[4]=4'hF;

    // LW LW LW
    expected_dmem_write[5]=0; expected_dmem_addr[5]=32'h84;
    expected_dmem_write[6]=0; expected_dmem_addr[6]=32'h88;
    expected_dmem_write[7]=0; expected_dmem_addr[7]=32'h8C;

    // SW LW SW LW
    expected_dmem_write[8]=1;  expected_dmem_addr[8]=32'h90; expected_dmem_wdata[8]=32'h0000001F; expected_dmem_wstrb[8]=4'hF;
    expected_dmem_write[9]=0;  expected_dmem_addr[9]=32'h90;
    expected_dmem_write[10]=1; expected_dmem_addr[10]=32'h94; expected_dmem_wdata[10]=32'h0000001F; expected_dmem_wstrb[10]=4'hF;
    expected_dmem_write[11]=0; expected_dmem_addr[11]=32'h94;

    // SW -> SB -> LW
    expected_dmem_write[12]=1; expected_dmem_addr[12]=32'h98; expected_dmem_wdata[12]=32'h00000123; expected_dmem_wstrb[12]=4'hF;
    expected_dmem_write[13]=1; expected_dmem_addr[13]=32'h99; expected_dmem_wdata[13]=32'h00004500; expected_dmem_wstrb[13]=4'h2;
    expected_dmem_write[14]=0; expected_dmem_addr[14]=32'h98;

    // SW -> SH -> LW
    expected_dmem_write[15]=1; expected_dmem_addr[15]=32'h9C; expected_dmem_wdata[15]=32'h00000123; expected_dmem_wstrb[15]=4'hF;
    expected_dmem_write[16]=1; expected_dmem_addr[16]=32'h9E; expected_dmem_wdata[16]=32'h00670000; expected_dmem_wstrb[16]=4'hC;
    expected_dmem_write[17]=0; expected_dmem_addr[17]=32'h9C;

    // SB x4 -> LW
    expected_dmem_write[18]=1; expected_dmem_addr[18]=32'hA0; expected_dmem_wdata[18]=32'h00000011; expected_dmem_wstrb[18]=4'h1;
    expected_dmem_write[19]=1; expected_dmem_addr[19]=32'hA1; expected_dmem_wdata[19]=32'h00002200; expected_dmem_wstrb[19]=4'h2;
    expected_dmem_write[20]=1; expected_dmem_addr[20]=32'hA2; expected_dmem_wdata[20]=32'h00330000; expected_dmem_wstrb[20]=4'h4;
    expected_dmem_write[21]=1; expected_dmem_addr[21]=32'hA3; expected_dmem_wdata[21]=32'h44000000; expected_dmem_wstrb[21]=4'h8;
    expected_dmem_write[22]=0; expected_dmem_addr[22]=32'hA0;

    // SH x2 -> LW
    expected_dmem_write[23]=1; expected_dmem_addr[23]=32'hA4; expected_dmem_wdata[23]=32'h00000123; expected_dmem_wstrb[23]=4'h3;
    expected_dmem_write[24]=1; expected_dmem_addr[24]=32'hA6; expected_dmem_wdata[24]=32'h04560000; expected_dmem_wstrb[24]=4'hC;
    expected_dmem_write[25]=0; expected_dmem_addr[25]=32'hA4;

    // SW 0x80FF7F01
    expected_dmem_write[26]=1; expected_dmem_addr[26]=32'hA8; expected_dmem_wdata[26]=32'h80FF7F01; expected_dmem_wstrb[26]=4'hF;

    // LB x4
    expected_dmem_write[27]=0; expected_dmem_addr[27]=32'hA8;
    expected_dmem_write[28]=0; expected_dmem_addr[28]=32'hA9;
    expected_dmem_write[29]=0; expected_dmem_addr[29]=32'hAA;
    expected_dmem_write[30]=0; expected_dmem_addr[30]=32'hAB;

    // LBU x2
    expected_dmem_write[31]=0; expected_dmem_addr[31]=32'hAA;
    expected_dmem_write[32]=0; expected_dmem_addr[32]=32'hAB;

    // LH x2
    expected_dmem_write[33]=0; expected_dmem_addr[33]=32'hA8;
    expected_dmem_write[34]=0; expected_dmem_addr[34]=32'hAA;

    // LHU x2
    expected_dmem_write[35]=0; expected_dmem_addr[35]=32'hA8;
    expected_dmem_write[36]=0; expected_dmem_addr[36]=32'hAA;

    // Mixed store
    expected_dmem_write[37]=1; expected_dmem_addr[37]=32'hAC; expected_dmem_wdata[37]=32'h00000000; expected_dmem_wstrb[37]=4'hF;
    expected_dmem_write[38]=1; expected_dmem_addr[38]=32'hAC; expected_dmem_wdata[38]=32'h00000012; expected_dmem_wstrb[38]=4'h1;
    expected_dmem_write[39]=1; expected_dmem_addr[39]=32'hAD; expected_dmem_wdata[39]=32'h00003400; expected_dmem_wstrb[39]=4'h2;
    expected_dmem_write[40]=1; expected_dmem_addr[40]=32'hAE; expected_dmem_wdata[40]=32'h05670000; expected_dmem_wstrb[40]=4'hC;
    expected_dmem_write[41]=0; expected_dmem_addr[41]=32'hAC;

    // LW -> SW -> LW
    expected_dmem_write[42]=0; expected_dmem_addr[42]=32'hAC;
    expected_dmem_write[43]=1; expected_dmem_addr[43]=32'hB0; expected_dmem_wdata[43]=32'h05673412; expected_dmem_wstrb[43]=4'hF;
    expected_dmem_write[44]=0; expected_dmem_addr[44]=32'hB0;

    // ADDI -> SW -> LW
    expected_dmem_write[45]=1; expected_dmem_addr[45]=32'hB4; expected_dmem_wdata[45]=32'h0000002A; expected_dmem_wstrb[45]=4'hF;
    expected_dmem_write[46]=0; expected_dmem_addr[46]=32'hB4;


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
    // Make sure complete streams were observed
    // ========================================================

    if (wb_idx !== EXPECTED_WB_COUNT) begin
        $error(
            "[WB COUNT] expected=%0d actual=%0d",
            EXPECTED_WB_COUNT,
            wb_idx
        );
        errors++;
    end

    if (dmem_idx !== EXPECTED_DMEM_COUNT) begin
        $error(
            "[DMEM COUNT] expected=%0d actual=%0d",
            EXPECTED_DMEM_COUNT,
            dmem_idx
        );
        errors++;
    end


    // ========================================================
    // Final SRAM state
    // ========================================================

    if (u_dsram.mem[32] !== 32'h0000000B) begin
        $error("[MEM 0x80] expected=0000000B actual=%08h", u_dsram.mem[32]);
        errors++;
    end

    if (u_dsram.mem[33] !== 32'h00000015) begin
        $error("[MEM 0x84] expected=00000015 actual=%08h", u_dsram.mem[33]);
        errors++;
    end

    if (u_dsram.mem[34] !== 32'h00000016) begin
        $error("[MEM 0x88] expected=00000016 actual=%08h", u_dsram.mem[34]);
        errors++;
    end

    if (u_dsram.mem[35] !== 32'h00000017) begin
        $error("[MEM 0x8C] expected=00000017 actual=%08h", u_dsram.mem[35]);
        errors++;
    end

    if (u_dsram.mem[36] !== 32'h0000001F) begin
        $error("[MEM 0x90] expected=0000001F actual=%08h", u_dsram.mem[36]);
        errors++;
    end

    if (u_dsram.mem[37] !== 32'h0000001F) begin
        $error("[MEM 0x94] expected=0000001F actual=%08h", u_dsram.mem[37]);
        errors++;
    end

    if (u_dsram.mem[38] !== 32'h00004523) begin
        $error("[MEM 0x98] expected=00004523 actual=%08h", u_dsram.mem[38]);
        errors++;
    end

    if (u_dsram.mem[39] !== 32'h00670123) begin
        $error("[MEM 0x9C] expected=00670123 actual=%08h", u_dsram.mem[39]);
        errors++;
    end

    if (u_dsram.mem[40] !== 32'h44332211) begin
        $error("[MEM 0xA0] expected=44332211 actual=%08h", u_dsram.mem[40]);
        errors++;
    end

    if (u_dsram.mem[41] !== 32'h04560123) begin
        $error("[MEM 0xA4] expected=04560123 actual=%08h", u_dsram.mem[41]);
        errors++;
    end

    if (u_dsram.mem[42] !== 32'h80FF7F01) begin
        $error("[MEM 0xA8] expected=80FF7F01 actual=%08h", u_dsram.mem[42]);
        errors++;
    end

    if (u_dsram.mem[43] !== 32'h05673412) begin
        $error("[MEM 0xAC] expected=05673412 actual=%08h", u_dsram.mem[43]);
        errors++;
    end

    if (u_dsram.mem[44] !== 32'h05673412) begin
        $error("[MEM 0xB0] expected=05673412 actual=%08h", u_dsram.mem[44]);
        errors++;
    end

    if (u_dsram.mem[45] !== 32'h0000002A) begin
        $error("[MEM 0xB4] expected=0000002A actual=%08h", u_dsram.mem[45]);
        errors++;
    end


    // ========================================================
    // Result
    // ========================================================

    report_result("LOAD_STORE_TEST");

    $finish;
end


// ============================================================
// WB SCOREBOARD
//
// Architectural register writes happen on posedge.
// ============================================================

always @(posedge clk) begin

    if (rst_n && u_cpu.wb_we) begin

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
                $display("[CYCLE PASS] expected=%0d actual=%0d",
                    EXPECTED_CYCLES,
                    actual_cycles
                );
            end
        end

        // More WB events than expected
        if (wb_idx >= EXPECTED_WB_COUNT) begin

            $error(
                "[WB] Unexpected extra WB: rd=x%0d data=%08h",
                u_cpu.wb_rd,
                u_cpu.wb_data
            );

            errors++;
        end

        else begin

            // ------------------------------------------------
            // RD check
            // ------------------------------------------------

            if (u_cpu.wb_rd !== expected_wb_rd[wb_idx]) begin

                $error(
                    "[WB #%0d] RD mismatch: expected=x%0d actual=x%0d",
                    wb_idx,
                    expected_wb_rd[wb_idx],
                    u_cpu.wb_rd
                );

                errors++;
            end


            // ------------------------------------------------
            // DATA check
            // ------------------------------------------------

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


            // ------------------------------------------------
            // Last expected architectural WB
            // ------------------------------------------------

            if (wb_idx == EXPECTED_WB_COUNT)
                test_done = 1'b1;

        end
    end
end


// ============================================================
// DMEM SCOREBOARD + PROTOCOL CHECKER
//
// Sample on negedge so CPU combinational outputs have settled.
// ============================================================

always @(negedge clk) begin

    if (!rst_n) begin

        req_waiting = 1'b0;

    end

    else begin

        // ====================================================
        // Basic legality
        // ====================================================

        if (dmem_read && dmem_write) begin

            $error(
                "[DMEM] dmem_read and dmem_write both asserted"
            );

            errors++;
        end


        // ====================================================
        // Existing outstanding transaction
        // ====================================================

        if (req_waiting) begin

            // ------------------------------------------------
            // Request must remain stable
            // ------------------------------------------------

            if (dmem_read !== saved_read) begin
                $error("[DMEM] read changed while waiting");
                errors++;
            end

            if (dmem_write !== saved_write) begin
                $error("[DMEM] write changed while waiting");
                errors++;
            end

            if (dmem_addr !== saved_addr) begin

                $error(
                    "[DMEM] addr changed while waiting: %08h -> %08h",
                    saved_addr,
                    dmem_addr
                );

                errors++;
            end

            if (dmem_wdata !== saved_wdata) begin

                $error(
                    "[DMEM] wdata changed while waiting: %08h -> %08h",
                    saved_wdata,
                    dmem_wdata
                );

                errors++;
            end

            if (dmem_wstrb !== saved_wstrb) begin

                $error(
                    "[DMEM] wstrb changed while waiting: %b -> %b",
                    saved_wstrb,
                    dmem_wstrb
                );

                errors++;
            end


            // =================================================
            // Transaction completion
            // =================================================

            if (dmem_ready) begin

                if (dmem_idx >= EXPECTED_DMEM_COUNT) begin

                    $error(
                        "[DMEM] Unexpected extra transaction"
                    );

                    errors++;
                end

                else begin

                    // -----------------------------------------
                    // R/W type
                    // -----------------------------------------

                    if (saved_write !==
                        expected_dmem_write[dmem_idx]) begin

                        $error(
                            "[DMEM #%0d] TYPE mismatch: expected=%s actual=%s",
                            dmem_idx,
                            expected_dmem_write[dmem_idx] ?
                                "WRITE" : "READ",
                            saved_write ?
                                "WRITE" : "READ"
                        );

                        errors++;
                    end


                    // -----------------------------------------
                    // Address
                    // -----------------------------------------

                    if (saved_addr !==
                        expected_dmem_addr[dmem_idx]) begin

                        $error(
                            "[DMEM #%0d] ADDR mismatch: expected=%08h actual=%08h",
                            dmem_idx,
                            expected_dmem_addr[dmem_idx],
                            saved_addr
                        );

                        errors++;
                    end


                    // -----------------------------------------
                    // Store-specific information
                    // -----------------------------------------

                    if (expected_dmem_write[dmem_idx]) begin

                        if (saved_wdata !==
                            expected_dmem_wdata[dmem_idx]) begin

                            $error(
                                "[DMEM #%0d] WDATA mismatch: expected=%08h actual=%08h",
                                dmem_idx,
                                expected_dmem_wdata[dmem_idx],
                                saved_wdata
                            );

                            errors++;
                        end

                        if (saved_wstrb !==
                            expected_dmem_wstrb[dmem_idx]) begin

                            $error(
                                "[DMEM #%0d] WSTRB mismatch: expected=%b actual=%b",
                                dmem_idx,
                                expected_dmem_wstrb[dmem_idx],
                                saved_wstrb
                            );

                            errors++;
                        end
                    end


                    $display(
                        "[DMEM PASS] #%0d %s addr=%08h",
                        dmem_idx,
                        saved_write ? "WRITE" : "READ ",
                        saved_addr
                    );

                end


                dmem_idx++;

                req_waiting = 1'b0;
            end
        end


        // ====================================================
        // Start tracking a new transaction
        // ====================================================

        else if ((dmem_read || dmem_write) && !dmem_ready) begin

            req_waiting = 1'b1;

            saved_read  = dmem_read;
            saved_write = dmem_write;

            saved_addr  = dmem_addr;
            saved_wdata = dmem_wdata;
            saved_wstrb = dmem_wstrb;

        end

    end
end