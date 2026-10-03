module dsram_model #(
    parameter int WORDS   = 1024,
    parameter int LATENCY = 2
)(
    input  logic        clk,
    input  logic        rst_n,

    input  logic        read,
    input  logic        write,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic [3:0]  wstrb,

    output logic [31:0] rdata,
    output logic        ready
);

    logic [31:0] mem [0:WORDS-1];

    logic        busy;
    integer      count;

    logic        req_write;
    logic [31:0] req_addr;
    logic [31:0] req_wdata;
    logic [3:0]  req_wstrb;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy      <= 1'b0;
            count     <= 0;
            ready     <= 1'b0;
            rdata     <= 32'b0;

            req_write <= 1'b0;
            req_addr  <= 32'b0;
            req_wdata <= 32'b0;
            req_wstrb <= 4'b0;
        end
        else begin
            // ready只拉高一个周期
            ready <= 1'b0;

            // ====================================================
            // 接收新事务
            // ====================================================
            if (!busy && !ready && (read || write)) begin
                busy      <= 1'b1;
                count     <= LATENCY;

                req_write <= write;
                req_addr  <= addr;
                req_wdata <= wdata;
                req_wstrb <= wstrb;
            end

            // ====================================================
            // 等待事务完成
            // ====================================================
            else if (busy) begin

                if (count > 1) begin
                    count <= count - 1;
                end
                else begin
                    busy  <= 1'b0;
                    ready <= 1'b1;

                    // ----------------------------
                    // Store
                    // ----------------------------
                    if (req_write) begin
                        if (req_wstrb[0])
                            mem[req_addr[31:2]][7:0]
                                <= req_wdata[7:0];

                        if (req_wstrb[1])
                            mem[req_addr[31:2]][15:8]
                                <= req_wdata[15:8];

                        if (req_wstrb[2])
                            mem[req_addr[31:2]][23:16]
                                <= req_wdata[23:16];

                        if (req_wstrb[3])
                            mem[req_addr[31:2]][31:24]
                                <= req_wdata[31:24];
                    end

                    // ----------------------------
                    // Load
                    // ----------------------------
                    else begin
                        rdata <= mem[req_addr[31:2]];
                    end
                end
            end
        end
    end

endmodule