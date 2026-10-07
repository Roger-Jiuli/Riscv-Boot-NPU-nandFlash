onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cpu_tb/u_cpu/clk
add wave -noupdate /cpu_tb/u_cpu/rst_n
add wave -noupdate -color Cyan -radix unsigned /cpu_tb/u_cpu/u_if_stage/if1_pc_q
add wave -noupdate -color Cyan -radix unsigned /cpu_tb/u_cpu/if_id_pc
add wave -noupdate -color Cyan -radix hexadecimal /cpu_tb/u_cpu/if_id_instr
add wave -noupdate -color Cyan /cpu_tb/u_cpu/if_id_valid
add wave -noupdate -color Pink /cpu_tb/u_cpu/id_ex_alu_op
add wave -noupdate -color Pink /cpu_tb/u_cpu/id_ex_alu_src_a
add wave -noupdate -color Pink -radix unsigned /cpu_tb/u_cpu/id_ex_alu_src_b
add wave -noupdate -color Pink /cpu_tb/u_cpu/id_ex_ctrl_flow
add wave -noupdate -color Pink /cpu_tb/u_cpu/id_ex_funct3
add wave -noupdate -color Pink -radix unsigned /cpu_tb/u_cpu/id_ex_imm
add wave -noupdate -color Pink /cpu_tb/u_cpu/id_ex_mem_read
add wave -noupdate -color Pink /cpu_tb/u_cpu/id_ex_mem_write
add wave -noupdate -color Pink -radix unsigned /cpu_tb/u_cpu/id_ex_pc
add wave -noupdate -color Pink -radix unsigned /cpu_tb/u_cpu/id_ex_rd
add wave -noupdate -color Pink /cpu_tb/u_cpu/id_ex_reg_write
add wave -noupdate -color Pink -radix unsigned /cpu_tb/u_cpu/id_ex_rs1
add wave -noupdate -color Pink -radix unsigned /cpu_tb/u_cpu/id_ex_rs1_data
add wave -noupdate -color Pink -radix unsigned /cpu_tb/u_cpu/id_ex_rs2
add wave -noupdate -color Pink -radix unsigned /cpu_tb/u_cpu/id_ex_rs2_data
add wave -noupdate -color Pink /cpu_tb/u_cpu/id_ex_use_rs1
add wave -noupdate -color Pink /cpu_tb/u_cpu/id_ex_use_rs2
add wave -noupdate -color Pink /cpu_tb/u_cpu/id_ex_valid
add wave -noupdate -color Pink /cpu_tb/u_cpu/id_ex_wb_sel
add wave -noupdate -color Yellow -radix unsigned /cpu_tb/u_cpu/ex_mem_alu_result
add wave -noupdate -color Yellow /cpu_tb/u_cpu/ex_mem_funct3
add wave -noupdate -color Yellow /cpu_tb/u_cpu/ex_mem_mem_read
add wave -noupdate -color Yellow /cpu_tb/u_cpu/ex_mem_mem_write
add wave -noupdate -color Yellow -radix hexadecimal /cpu_tb/u_cpu/ex_mem_pc4
add wave -noupdate -color Yellow -radix unsigned /cpu_tb/u_cpu/ex_mem_rd
add wave -noupdate -color Yellow /cpu_tb/u_cpu/ex_mem_reg_write
add wave -noupdate -color Yellow -radix unsigned /cpu_tb/u_cpu/ex_mem_store_data
add wave -noupdate -color Yellow /cpu_tb/u_cpu/ex_mem_valid
add wave -noupdate -color Yellow /cpu_tb/u_cpu/ex_mem_wb_sel
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/mem_wb_alu_result
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/mem_wb_load_data
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/mem_wb_pc4
add wave -noupdate -radix unsigned /cpu_tb/u_cpu/mem_wb_rd
add wave -noupdate /cpu_tb/u_cpu/mem_wb_reg_write
add wave -noupdate /cpu_tb/u_cpu/mem_wb_valid
add wave -noupdate /cpu_tb/u_cpu/mem_wb_wb_sel
add wave -noupdate -color {Medium Slate Blue} -radix unsigned /cpu_tb/u_cpu/wb_data
add wave -noupdate -color {Medium Slate Blue} -radix unsigned /cpu_tb/u_cpu/wb_rd
add wave -noupdate -color {Medium Slate Blue} /cpu_tb/u_cpu/wb_we
add wave -noupdate -radix unsigned /cpu_tb/actual_cycles
add wave -noupdate /cpu_tb/cycle_count
add wave -noupdate /cpu_tb/wb_idx
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {34908 ps} 0} {{Cursor 2} {120898 ps} 0} {{Cursor 3} {45011 ps} 0} {{Cursor 4} {54937 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 227
configure wave -valuecolwidth 60
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
WaveRestoreZoom {340030 ps} {441052 ps}
