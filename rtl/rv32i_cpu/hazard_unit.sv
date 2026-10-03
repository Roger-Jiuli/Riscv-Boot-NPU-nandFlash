module hazard_unit (
    // ==============================
    // Current instruction in ID
    // ==============================
    input  logic       id_valid,
    input  logic [4:0] id_rs1,
    input  logic [4:0] id_rs2,
    input  logic       id_use_rs1,
    input  logic       id_use_rs2,

    // ==============================
    // Current instruction in EX
    // ==============================
    input  logic       ex_valid,
    input  logic       ex_mem_read,
    input  logic [4:0] ex_rd,

    // ==============================
    // Hazard result
    // ==============================
    output logic       load_use_hazard
);


    always_comb begin

        load_use_hazard =
            id_valid       &&
            ex_valid       &&
            ex_mem_read    &&
            (ex_rd != 5'd0) &&
            (
                (id_use_rs1 && (id_rs1 == ex_rd)) ||
                (id_use_rs2 && (id_rs2 == ex_rd))
            );

    end

endmodule