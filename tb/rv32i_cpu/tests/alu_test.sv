initial begin

    rst_n = 1'b0;

    // addi x1,x0,10
    u_isram.mem[0] = 32'h00A00093;

    // addi x2,x0,20
    u_isram.mem[1] = 32'h01400113;

    // add x3,x1,x2
    u_isram.mem[2] = 32'h002081B3;

    // add x4,x3,x1
    u_isram.mem[3] = 32'h00118233;

    // sub x5,x4,x2
    u_isram.mem[4] = 32'h402202B3;

    for (int i = 5; i < 32; i++)
        u_isram.mem[i] = 32'h00000013;

    #20;
    rst_n = 1'b1;

    repeat (20) @(posedge clk);

    if (u_cpu.u_id_stage.u_regfile.regs[1] !== 32'd10)
        $error("x1 ERROR");

    if (u_cpu.u_id_stage.u_regfile.regs[2] !== 32'd20)
        $error("x2 ERROR");

    if (u_cpu.u_id_stage.u_regfile.regs[3] !== 32'd30)
        $error("x3 ERROR");

    if (u_cpu.u_id_stage.u_regfile.regs[4] !== 32'd40)
        $error("x4 ERROR");

    if (u_cpu.u_id_stage.u_regfile.regs[5] !== 32'd20)
        $error("x5 ERROR");

    $display("ALU TEST PASS");

    $finish;
end