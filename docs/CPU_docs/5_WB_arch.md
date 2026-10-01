# 五、WB架构

接上文，收到 wb sel 后选择写回数据的来源

```
always_comb begin
    case (mem_wb_wb_sel)
        WB_ALU: wb_data = mem_wb_alu_result;
        WB_MEM: wb_data = mem_wb_load_data;
        WB_PC4: wb_data = mem_wb_pc4;
        default: wb_data = 32'b0;
    endcase
end
```

根据 `reg_write` 与 mem\_wb\_valid  决定是否要写入

同时这个选择好的 wb_data 也用于 exe 的 forwarding unit，在 EX 章节已经介绍过了

有一个情况是 ID 读和 wb 写 同一个寄存器，要直接 bypass，rdata = wb_data，这个在 ID 已经介绍过了

