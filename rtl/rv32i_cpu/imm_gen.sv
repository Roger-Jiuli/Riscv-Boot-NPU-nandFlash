module imm_gen (
    input  logic [31:0] instr,
    input  logic [2:0]  imm_sel,

    output logic [31:0] imm
);

    localparam logic [2:0] IMM_I = 3'd0;
    localparam logic [2:0] IMM_S = 3'd1;
    localparam logic [2:0] IMM_B = 3'd2;
    localparam logic [2:0] IMM_U = 3'd3;
    localparam logic [2:0] IMM_J = 3'd4;


    always_comb begin

        case (imm_sel)

            // I-type
            // ADDI / LW / JALR ...
            IMM_I: begin
                imm = {{20{instr[31]}},
                       instr[31:20]};
            end


            // S-type
            // SB / SH / SW
            IMM_S: begin
                imm = {{20{instr[31]}},
                       instr[31:25],
                       instr[11:7]};
            end


            // B-type
            // BEQ / BNE / BLT ...
            IMM_B: begin
                imm = {{19{instr[31]}},
                       instr[31],
                       instr[7],
                       instr[30:25],
                       instr[11:8],
                       1'b0};
            end


            // U-type
            // LUI / AUIPC
            IMM_U: begin
                imm = {instr[31:12],
                       12'b0};
            end


            // J-type
            // JAL
            IMM_J: begin
                imm = {{11{instr[31]}},
                       instr[31],
                       instr[19:12],
                       instr[20],
                       instr[30:21],
                       1'b0};
            end


            default: begin
                imm = 32'b0;
            end

        endcase

    end

endmodule