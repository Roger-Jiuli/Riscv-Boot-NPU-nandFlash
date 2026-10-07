onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cpu_tb/rst_n
add wave -noupdate /cpu_tb/test_done
add wave -noupdate -color Salmon -radix hexadecimal /cpu_tb/u_cpu/dmem_addr
add wave -noupdate -color Salmon -radix hexadecimal /cpu_tb/u_cpu/dmem_rdata
add wave -noupdate -color Salmon /cpu_tb/u_cpu/dmem_read
add wave -noupdate -color Salmon /cpu_tb/u_cpu/dmem_ready
add wave -noupdate -color Salmon -radix hexadecimal /cpu_tb/u_cpu/dmem_wdata
add wave -noupdate -color Salmon /cpu_tb/u_cpu/dmem_write
add wave -noupdate -color Salmon /cpu_tb/u_cpu/dmem_wstrb
add wave -noupdate -color {Medium Spring Green} -radix hexadecimal /cpu_tb/u_cpu/ex_mem_alu_result
add wave -noupdate -color {Medium Spring Green} /cpu_tb/u_cpu/ex_mem_funct3
add wave -noupdate -color {Medium Spring Green} /cpu_tb/u_cpu/ex_mem_mem_read
add wave -noupdate -color {Medium Spring Green} /cpu_tb/u_cpu/ex_mem_mem_write
add wave -noupdate -color {Medium Spring Green} -radix unsigned /cpu_tb/u_cpu/ex_mem_pc4
add wave -noupdate -color {Medium Spring Green} -radix unsigned /cpu_tb/u_cpu/ex_mem_rd
add wave -noupdate -color {Medium Spring Green} /cpu_tb/u_cpu/ex_mem_reg_write
add wave -noupdate -color {Medium Spring Green} -radix hexadecimal /cpu_tb/u_cpu/ex_mem_store_data
add wave -noupdate -color {Medium Spring Green} /cpu_tb/u_cpu/ex_mem_valid
add wave -noupdate -color Magenta /cpu_tb/u_cpu/mem_stall
add wave -noupdate -color Magenta -radix unsigned /cpu_tb/u_cpu/mem_wb_alu_result
add wave -noupdate -color Magenta -radix unsigned /cpu_tb/u_cpu/mem_wb_load_data
add wave -noupdate -color Magenta -radix unsigned /cpu_tb/u_cpu/mem_wb_pc4
add wave -noupdate -color Magenta -radix unsigned /cpu_tb/u_cpu/mem_wb_rd
add wave -noupdate -color Magenta /cpu_tb/u_cpu/mem_wb_reg_write
add wave -noupdate -color Magenta /cpu_tb/u_cpu/mem_wb_valid
add wave -noupdate -radix hexadecimal /cpu_tb/u_cpu/wb_data
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/wb_rd
add wave -noupdate /cpu_tb/u_cpu/wb_we
add wave -noupdate /cpu_tb/clk
add wave -noupdate /cpu_tb/u_cpu/u_ex_stage/forward_b
add wave -noupdate -radix hexadecimal /cpu_tb/u_cpu/u_ex_stage/mem_forward_data
add wave -noupdate -radix hexadecimal /cpu_tb/u_cpu/u_ex_stage/src2_fwd
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {75356 ps} 0} {{Cursor 2} {1145095 ps} 0} {{Cursor 3} {1185270 ps} 0} {{Cursor 4} {1225058 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 246
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
WaveRestoreZoom {2049847 ps} {2214219 ps}
