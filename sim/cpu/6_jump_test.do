onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cpu_tb/clk
add wave -noupdate /cpu_tb/cycle_count
add wave -noupdate /cpu_tb/rst_n
add wave -noupdate -radix unsigned /cpu_tb/actual_cycles
add wave -noupdate /cpu_tb/test_done
add wave -noupdate /cpu_tb/wb_idx
add wave -noupdate -color Blue -radix hexadecimal /cpu_tb/u_cpu/if_id_instr
add wave -noupdate -color Blue -radix unsigned /cpu_tb/u_cpu/if_id_pc
add wave -noupdate -color Blue /cpu_tb/u_cpu/if_id_valid
add wave -noupdate -color {Medium Spring Green} /cpu_tb/u_cpu/id_ctrl_flow
add wave -noupdate -color {Medium Spring Green} /cpu_tb/u_cpu/id_ex_ctrl_flow
add wave -noupdate -color {Medium Spring Green} -radix unsigned /cpu_tb/u_cpu/id_ex_pc
add wave -noupdate -color {Medium Spring Green} /cpu_tb/u_cpu/id_ex_valid
add wave -noupdate -color Salmon -radix unsigned /cpu_tb/u_cpu/ex_mem_pc4
add wave -noupdate -color Salmon /cpu_tb/u_cpu/ex_mem_valid
add wave -noupdate -color Magenta -radix unsigned /cpu_tb/u_cpu/mem_wb_pc4
add wave -noupdate -color Magenta /cpu_tb/u_cpu/mem_wb_valid
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/redirect_pc
add wave -noupdate /cpu_tb/u_cpu/redirect_valid
add wave -noupdate /cpu_tb/redirect_idx
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/wb_data
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/wb_rd
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/wb_we
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {625000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 238
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
WaveRestoreZoom {539444 ps} {641082 ps}
