module store_unit (
    input  logic [31:0] addr,
    input  logic [2:0]  funct3,
    input  logic [31:0] store_data,

    output logic [31:0] wdata,
    output logic [3:0]  wstrb
);

    always_comb begin

        wdata = 32'b0;
        wstrb = 4'b0000;

        case (funct3)

            // SB
            3'b000: begin
                case (addr[1:0])
                    2'b00: begin
                        wdata = {24'b0, store_data[7:0]};
                        wstrb = 4'b0001;
                    end

                    2'b01: begin
                        wdata = {16'b0, store_data[7:0], 8'b0};
                        wstrb = 4'b0010;
                    end

                    2'b10: begin
                        wdata = {8'b0, store_data[7:0], 16'b0};
                        wstrb = 4'b0100;
                    end

                    2'b11: begin
                        wdata = {store_data[7:0], 24'b0};
                        wstrb = 4'b1000;
                    end
                endcase
            end


            // SH
            3'b001: begin
                if (addr[1] == 1'b0) begin
                    wdata = {16'b0, store_data[15:0]};
                    wstrb = 4'b0011;
                end
                else begin
                    wdata = {store_data[15:0], 16'b0};
                    wstrb = 4'b1100;
                end
            end


            // SW
            3'b010: begin
                wdata = store_data;
                wstrb = 4'b1111;
            end


            default: begin
                wdata = 32'b0;
                wstrb = 4'b0000;
            end

        endcase

    end

endmodule