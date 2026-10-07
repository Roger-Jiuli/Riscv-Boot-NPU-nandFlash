// ============================================================
// Common CPU Test Checkers
// ============================================================

integer errors;


// ============================================================
// Check Register
// ============================================================

task automatic check_reg(
    input int          reg_num,
    input logic [31:0] expected
);
begin
    if (u_cpu.u_id_stage.u_regfile.regs[reg_num] !== expected) begin
        $error(
            "[REG CHECK] x%0d: expected=%0d (0x%08h), actual=%0d (0x%08h)",
            reg_num,
            expected,
            expected,
            u_cpu.u_id_stage.u_regfile.regs[reg_num],
            u_cpu.u_id_stage.u_regfile.regs[reg_num]
        );
        errors++;
    end
end
endtask


// ============================================================
// Report Result
// ============================================================

task automatic report_result(
    input string test_name
);
begin
    if (errors == 0) begin
        $display("");
        $display("================================");
        $display("  %s PASS", test_name);
        $display("================================");
    end
    else begin
        $display("");
        $display("================================");
        $display("  %s FAIL : %0d errors", test_name, errors);
        $display("================================");
    end
end
endtask

integer cycle_count;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cycle_count <= 0;
    else
        cycle_count <= cycle_count + 1;
end