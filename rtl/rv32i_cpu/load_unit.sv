module load_unit (
    input  logic [31:0] addr,
    input  logic [2:0]  funct3,
    input  logic [31:0] rdata,

    output logic [31:0] load_data
);

    logic [7:0]  selected_byte;
    logic [15:0] selected_half;


    always_comb begin

        // Byte选择
        case (addr[1:0])
            2'b00: selected_byte = rdata[7:0];
            2'b01: selected_byte = rdata[15:8];
            2'b10: selected_byte = rdata[23:16];
            2'b11: selected_byte = rdata[31:24];
        endcase


        // Halfword选择
        case (addr[1])
            1'b0: selected_half = rdata[15:0];
            1'b1: selected_half = rdata[31:16];
        endcase


        // Load类型
        case (funct3)

            // LB
            3'b000:
                load_data =
                    {{24{selected_byte[7]}}, selected_byte};

            // LH
            3'b001:
                load_data =
                    {{16{selected_half[15]}}, selected_half};

            // LW
            3'b010:
                load_data = rdata;

            // LBU
            3'b100:
                load_data =
                    {24'b0, selected_byte};

            // LHU
            3'b101:
                load_data =
                    {16'b0, selected_half};

            default:
                load_data = 32'b0;

        endcase

    end

endmodule