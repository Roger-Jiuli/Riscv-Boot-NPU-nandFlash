# ============================================================
# RV32I CPU Timing Constraints
# Baseline Constraint Set
# ============================================================


# ============================================================
# 1. Primary Clock
#
# Target:
#   Period    = 10 ns
#   Frequency = 100 MHz
# ============================================================

create_clock \
    -name clk \
    -period 10.000 \
    -waveform {0.000 5.000} \
    [get_ports clk]


# ------------------------------------------------------------
# Setup Clock Uncertainty
# ------------------------------------------------------------

set_clock_uncertainty \
    -setup 1.0 \
    [get_clocks clk]


# ============================================================
# 2. Input Delay
#
# Exclude:
#   clk   : primary clock
#   rst_n : asynchronous reset
# ============================================================

set DATA_INPUTS \
    [remove_from_collection \
        [all_inputs] \
        [get_ports {clk rst_n}]]

set_input_delay \
    -clock clk \
    1.0 \
    $DATA_INPUTS


# ============================================================
# 3. Output Delay
# ============================================================

set_output_delay \
    -clock clk \
    1.0 \
    [all_outputs]


# ============================================================
# End
# ============================================================