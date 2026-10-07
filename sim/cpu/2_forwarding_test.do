onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cpu_tb/clk
add wave -noupdate /cpu_tb/rst_n
add wave -noupdate /cpu_tb/errors
add wave -noupdate -radix unsigned /cpu_tb/imem_addr
add wave -noupdate /cpu_tb/imem_en
add wave -noupdate -radix hexadecimal /cpu_tb/imem_rdata
add wave -noupdate -color {Medium Orchid} -radix hexadecimal /cpu_tb/u_cpu/if_id_instr
add wave -noupdate -color {Medium Orchid} -radix unsigned /cpu_tb/u_cpu/if_id_pc
add wave -noupdate -color {Medium Orchid} /cpu_tb/u_cpu/if_id_valid
add wave -noupdate -color Cyan -radix unsigned /cpu_tb/u_cpu/id_ex_pc
add wave -noupdate -color Cyan -radix unsigned /cpu_tb/u_cpu/id_ex_rd
add wave -noupdate -color Cyan -radix unsigned /cpu_tb/u_cpu/id_ex_rs1_data
add wave -noupdate -color Cyan -radix unsigned /cpu_tb/u_cpu/id_ex_rs2_data
add wave -noupdate -color Cyan /cpu_tb/u_cpu/id_ex_valid
add wave -noupdate -color Coral -radix unsigned /cpu_tb/u_cpu/ex_mem_alu_result
add wave -noupdate -color Coral -radix unsigned /cpu_tb/u_cpu/ex_mem_pc4
add wave -noupdate -color Coral -radix unsigned /cpu_tb/u_cpu/ex_mem_rd
add wave -noupdate -color Coral /cpu_tb/u_cpu/ex_mem_valid
add wave -noupdate -color {Steel Blue} -radix unsigned /cpu_tb/u_cpu/mem_wb_alu_result
add wave -noupdate -color {Steel Blue} -radix unsigned /cpu_tb/u_cpu/mem_wb_pc4
add wave -noupdate -color {Steel Blue} -radix unsigned /cpu_tb/u_cpu/mem_wb_rd
add wave -noupdate -color {Steel Blue} /cpu_tb/u_cpu/mem_wb_valid
add wave -noupdate -color {Blue Violet} -radix unsigned /cpu_tb/u_cpu/wb_data
add wave -noupdate -color {Blue Violet} -radix unsigned /cpu_tb/u_cpu/wb_rd
add wave -noupdate -color {Blue Violet} /cpu_tb/u_cpu/wb_we
add wave -noupdate /cpu_tb/wb_count
add wave -noupdate /cpu_tb/cycle_count
add wave -noupdate /cpu_tb/actual_cycles
add wave -noupdate /cpu_tb/test_done
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {64831 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 233
configure wave -valuecolwidth 73
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
WaveRestoreZoom {0 ps} {224722 ps}
