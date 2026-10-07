# ============================================================
# RV32I CPU
# Post-Synthesis / Pre-Layout STA Flow
#
# Tool:
#   Synopsys PrimeTime
# ============================================================


# ============================================================
# 0. Environment
# ============================================================

source ./scripts/setup_pt.tcl


# ============================================================
# 1. Read Gate-Level Netlist
# ============================================================

echo "============================================"
echo "1. Reading mapped gate-level netlist..."
echo "============================================"

read_verilog $NETLIST


# ============================================================
# 2. Set Top Design
# ============================================================

echo "============================================"
echo "2. Setting current design..."
echo "============================================"

current_design $TOP


# ============================================================
# 3. Link Design
# ============================================================

echo "============================================"
echo "3. Linking design..."
echo "============================================"

link_design $TOP


# ============================================================
# 4. Read Timing Constraints
# ============================================================

echo "============================================"
echo "4. Reading SDC..."
echo "============================================"

read_sdc $SDC


# ============================================================
# 5. Basic Timing Checks
# ============================================================

redirect $REPORT_DIR/check_timing.rpt {
    check_timing -verbose
}

redirect $REPORT_DIR/clocks.rpt {
    report_clock
}


# ============================================================
# 6. Update Timing
# ============================================================

update_timing


# ============================================================
# 7. Setup Timing
# ============================================================

redirect $REPORT_DIR/timing_setup.rpt {
    report_timing \
        -delay_type max \
        -max_paths 20 \
        -slack_lesser_than 100 \
        -path_type full
}


# ============================================================
# 8. Hold Timing
# ============================================================

redirect $REPORT_DIR/timing_hold.rpt {
    report_timing \
        -delay_type min \
        -max_paths 20 \
        -slack_lesser_than 100 \
        -path_type full
}


# ============================================================
# 9. Constraint Violations
# ============================================================

redirect $REPORT_DIR/constraint_violators.rpt {
    report_constraint -all_violators
}


# ============================================================
# 10. Global Timing Summary
# ============================================================

redirect $REPORT_DIR/global_timing.rpt {
    report_global_timing
}


# ============================================================
# Done
# ============================================================

echo ""
echo "============================================"
echo "RV32I CPU PrimeTime STA Finished"
echo "============================================"
echo "Reports:"
echo "  $REPORT_DIR/check_timing.rpt"
echo "  $REPORT_DIR/clocks.rpt"
echo "  $REPORT_DIR/timing_setup.rpt"
echo "  $REPORT_DIR/timing_hold.rpt"
echo "  $REPORT_DIR/constraint_violators.rpt"
echo "  $REPORT_DIR/global_timing.rpt"
echo "============================================"