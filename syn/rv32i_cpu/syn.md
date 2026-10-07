对写好的 CPU 进行综合，工具 ： DC，工艺库：SMIC 130nm

初步设定 period 为 10ns  100M Hz

约束 input ，output delay 为 1ns

约束 clock\_uncertainty 为 1ns，以期为后端留足空间

report：

生成 area，Timing，Cell，power 等 report

V1 版本 area 50437.750027+54537.622063，power 3385.98，Slack 0.00，无时序为例

V2 版本希望 CPU 探频，设定 period 为 4ns 250M Hz

    area 66519.960234 + 55393.877003，power 4669.80，Slack -0.13（period 2ns，output delay 1ns，clock\_uncertainty  1ns）

违例路径为：从 mem state 的 rd 出发，判断是否有 data Hazard 需要 forwarding 到 ALU input，再根据 ALU result 判断 branch 是否 taken，进而决定 pipeline ctrl PC_en，产生 isram req

由于 data required time 受 output delay 和 clock\_uncertainty 压缩，决定不为 `-0.13 ns` 修改 RTL

面积：

分析得 ID 的 RegFile 面积较大，因为当前没有使用专用 Register File / SRAM Macro，DC 用标准单元实现，所以面积较大

output：

```
cpu_core_netlist.v
cpu_core.ddc
cpu_core.sdc
```

用于后续 STA


