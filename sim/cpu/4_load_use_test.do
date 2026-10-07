onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cpu_tb/actual_cycles
add wave -noupdate /cpu_tb/clk
add wave -noupdate /cpu_tb/cycle_count
add wave -noupdate -radix unsigned /cpu_tb/imem_addr
add wave -noupdate /cpu_tb/imem_en
add wave -noupdate -radix hexadecimal /cpu_tb/imem_rdata
add wave -noupdate /cpu_tb/load_stall_count
add wave -noupdate /cpu_tb/rst_n
add wave -noupdate /cpu_tb/test_done
add wave -noupdate /cpu_tb/wb_idx
add wave -noupdate /cpu_tb/u_cpu/hold_forward
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/id_ex_rs1
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/id_ex_rs2
add wave -noupdate /cpu_tb/u_cpu/id_ex_valid
add wave -noupdate /cpu_tb/u_cpu/load_use_hazard
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/mem_forward_data
add wave -noupdate /cpu_tb/u_cpu/mem_stall
add wave -noupdate /cpu_tb/u_cpu/pc_en
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/redirect_pc
add wave -noupdate /cpu_tb/u_cpu/redirect_valid
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/wb_data
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/wb_rd
add wave -noupdate /cpu_tb/u_cpu/wb_we
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {395000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 236
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {562800 ps}
