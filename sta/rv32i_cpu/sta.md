根据 DC 生成的 网表文件 cpu\_core\_netlist.v，以及约束 cpu\_core.sdc 进行 STA

工具：Primetime，工艺库：SMIC 130nm

目的：只是前端再次详细进行 静态时序分析

无建立违例，保持违例，

遇到的问题：

出现 1502 unconstrained endpoints，不过分析发现，都是xxx/RN，即为 从 rstn 到 ff 路径，因此当前 pre-layout STA 将 reset 从普通数据路径排除
