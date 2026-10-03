`timescale 1ns/1ps

module cpu_tb;

    logic clk;
    logic rst_n;

    logic        imem_en;
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;

    logic        dmem_read;
    logic        dmem_write;
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [3:0]  dmem_wstrb;
    logic [31:0] dmem_rdata;
    logic        dmem_ready;

    cpu_core u_cpu (
        .clk        (clk),
        .rst_n      (rst_n),

        .imem_en    (imem_en),
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),

        .dmem_read  (dmem_read),
        .dmem_write (dmem_write),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_wstrb (dmem_wstrb),
        .dmem_rdata (dmem_rdata),
        .dmem_ready (dmem_ready)
    );

    isram_model u_isram (
        .clk   (clk),
        .en    (imem_en),
        .addr  (imem_addr),
        .rdata (imem_rdata)
    );

    dsram_model #(
        .WORDS   (1024),
        .LATENCY (2)
    ) u_dsram (
        .clk   (clk),
        .rst_n (rst_n),

        .read  (dmem_read),
        .write (dmem_write),
        .addr  (dmem_addr),
        .wdata (dmem_wdata),
        .wstrb (dmem_wstrb),

        .rdata (dmem_rdata),
        .ready (dmem_ready)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 具体测项
    `include "tests/alu_test.sv"

endmodule