# 六、Pipeline Control

每一级的流水寄存器都是：                

   x_x_en      x_x_flush         state

       1                0                valid

       0               0                 hold

       x                1                 bubble



## case 1：Load-Use Hazard 如

```
lw   x5, 0(x1)
add  x6, x5, x2
```

当 I1 在 EX 计算结束时，还没有进入 Mem，x5 的值还没拿到，I2 已经在 ID 中，准备进入 EX 进行计算了，但 x5 还是旧值，所以不允许进入 EX，这时应该：

```
PC       HOLD
IF/ID    HOLD
ID/EX    Bubble

EX/MEM   正常前进
MEM/WB   正常前进
```

对应的控制信号：

```
pc_en       = 0;    // hold PC

if_id_en    = 0;    // hold IF/ID 
if_id_flush = 0;

id_ex_en    = 0;  // flush ID/EX，向 ex 传递 bubble，将 I2 留在 ID
id_ex_flush = 1;

ex_mem_en    = 1;    // keep EX/MEM
ex_mem_flush = 0;

mem_wb_en    = 1;    // keep MEM/WB
mem_wb_flush = 0;
```



## case 2：mem stall 如

```
lw   x5, 0(x1)     // I1
add  x6, x7, x8    // I2
sub  x9, x10,x11   // I3
```

lw 进入 Mem 后，要发起 load 操作，但 SRAM / MMIO 需要几个周期才能拿到 rdata ，

```
mem_stall = ex_mem_valid &&
            (ex_mem_mem_read || ex_mem_mem_write) &&
            !dmem_ready;
```

所以要将 PC IF ID MEM 全部 stall，向 wb 传递 bubble，即

```
PC       HOLD
IF/ID    HOLD
ID/EX    HOLD
EX/MEM   HOLD
MEM/WB   Bubble
```

控制信号：

```
pc_en       = 0;    // hold PC

if_id_en    = 0;     // hold IF/ID 
if_id_flush = 0;

id_ex_en    = 0;    // hold ID/EX
id_ex_flush = 0;

ex_mem_en    = 0;   // hold EX/MEM
ex_mem_flush = 0;

mem_wb_en    = 0;    // flush MEM/WB，传递 bubble    
mem_wb_flush = 1;
```

等几个周期后  `dmem_ready = 1`  再 refresh 各 module



## case 3：IF stall

IF 取指令也要访问 SRAM，也会出现 需要等到 ready的情况，ready 后才能拿到下一条指令向下传递，此时需要向下游传递 bubble，而已经在流水线里的老指令完全可以继续跑

```
PC      HOLD          // 当前取指地址不能变
IF/ID   ?             // 第一拍当前指令消费后，应变 Bubble
ID/EX   ADVANCE
EX/MEM  ADVANCE
MEM/WB  ADVANCE
```



## case 4：Branch / JAL / JALR 的 control hazard

以 beq 为例；

```
I1: beq x1, x2, TARGET
I2: add x3, x4, x5       // 顺序下一条
...
TARGET:
I5: sub x6, x7, x8
```

当 beq 到达 ID 时，会解析出 ctrl\_flow  = FLOW\_BRANCH，于是会令

```
PC       HOLD
IF/ID    FLUSH
ID/EX    ADVANCE
```

即 PC 保持在 I2，向 ID 传递 bubble，并且把 ID 中的 I1 送进 EX 中计算

### case a、EX 决断：BEQ not taken

那么 redirect_valid = 0，此时 PC 还在 hold I2，接下来恢复 PC & IF/ID ，直接将 I2 送进 ID，PC <= I3

```
pc_en    = 1
if_id_en = 1 
if_id_flush = 0 
```

### case b、EX 决断：BEQ taken

那么 branch\_taken = 1，并准备好 redirect_pc，在 EX 允许前进时，即 ex_mem_en == 1 (这是为了防止 branch 的上一条指令为 mem 操作，此时需要 stall，等待 mem_ready，才能继续前进，送回 redirect_pc) 时，redirect\_valid  = 1；

```
redirect_valid =
    id_ex_valid &&
    ex_mem_en &&
    branch_taken;
```

在时钟沿到达时，PC detect 到 redirect\_valid ，则 PC <= redirect_pc，然后 IF 从 TARGET 发起取指，等待 mem_ready 恢复 if_id_en，pc_en，将指令送给 ID

并且由于本轮 EX 收到的指令为 bubble，因此会使得 redirect_valid = 0，



## case 4：上游 x_x_valid == 0

传递 下级 valid <= 上级 valid

```
if (id_ex_flush)
    id_ex_valid <= 1'b0;        // 主动塞 Bubble
else if (id_ex_en)
    id_ex_valid <= if_id_valid; // 正常传递，包括 valid=0
else
    ;                           // HOLD，保持原来的 valid
```

## case 5：summy

control uniu  priority：

```
Reset
  ↓
MEM stall
  ↓
Redirect
  ↓
Load-use hazard
  ↓
ID control-flow wait
  ↓
IF wait
  ↓
Normal
```
