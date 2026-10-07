# ============================================================
# RV32I CPU
# PrimeTime Environment Setup
# ============================================================

# ------------------------------------------------------------
# 1. Project paths
# ------------------------------------------------------------

set PROJECT_ROOT "/home/design/projects/Riscv-Boot-NPU-nandFlash"

set SYN_DIR      "$PROJECT_ROOT/syn/rv32i_cpu/"
set OUTPUT_DIR   "$SYN_DIR/outputs"

set STA_DIR      "$PROJECT_ROOT/sta/rv32i_cpu"
set REPORT_DIR   "$STA_DIR/reports"
set WORK_DIR     "$STA_DIR/work"


# ------------------------------------------------------------
# 2. Design
# ------------------------------------------------------------

set TOP "cpu_core"


# ------------------------------------------------------------
# 3. Standard Cell Library
# ------------------------------------------------------------

set LIB_DIR "/home/design/pdk/smic13/STD/Synopsys"

set_app_var search_path [list \
    $LIB_DIR \
    $OUTPUT_DIR \
]

set_app_var target_library [list \
    "$LIB_DIR/smic13_tt.db" \
]

set_app_var link_path [list \
    "*" \
    "$LIB_DIR/smic13_tt.db" \
]


# ------------------------------------------------------------
# 4. Input files
# ------------------------------------------------------------

set NETLIST "$OUTPUT_DIR/cpu_core_netlist.v"
set SDC     "$OUTPUT_DIR/cpu_core.sdc"


# ------------------------------------------------------------
# 5. Create directories
# ------------------------------------------------------------

file mkdir $REPORT_DIR
file mkdir $WORK_DIR


# ------------------------------------------------------------
# 6. Check paths
# ------------------------------------------------------------

echo "============================================"
echo "RV32I CPU PrimeTime Setup"
echo "TOP      = $TOP"
echo "NETLIST  = $NETLIST"
echo "SDC      = $SDC"
echo "LIBRARY  = $LIB_DIR/smic13_tt.db"
echo "============================================"