# 二、ID 架构

IF/ID ——> ID 的信号有三个：if_id_valid、if_id_pc、if_id_instr
![ID_arch](../images/ID_arch.png)

## 1、decode -> read reg

首先，就要根据 32 位指令格式，解析出 Field Split

```
opcode = if_id_instr[6:0];
rd     = if_id_instr[11:7];
funct3 = if_id_instr[14:12];
rs1    = if_id_instr[19:15];
rs2    = if_id_instr[24:20];
funct7 = if_id_instr[31:25];
```

![RISC-V Instruction Type](../images/RISC-V_insrtuction_type.png)

但后续要怎样使用，还要看具体的控制信号;

获取到 RS，接下来就是读寄存器，值得注意的是，读操作为组合逻辑，写操作的 data 来着 ALU 或者 Mem，为时序逻辑

x0 是一个特殊的寄存器，其值永远是 0

此外，还设计允许寄存器 bypass read，即对同一个寄存器同时发起 读 和 写 操作，直接讲write data -> read output，防止读到旧值

对于 forwarding 的设计，后面再介绍



## 2、decode -> immediate

对于某些 type instruction，ALU 操作的另一个 src 不来自 RS，而来自立即数，但不同type 的 immediate 位置各不相同，所以需要根据不同的 opcode 和 func，将其重新拼接

I-Type：imm = {{20{instr[31]}}, instr[31:20]}; （immediate 可以是负数，所以要进行符号位扩展）

S-Type：imm = { {20{instr\[31\]}}, instr\[31:25\], instr\[11:7\] };

B-Type：为什么单独补 0 呢，因为指令是四字节对齐，所以最低位永远是0，高位同样符号位扩展

```
imm[12]   = instr[31]
imm[11]   = instr[7]
imm[10:5] = instr[30:25]
imm[4:1]  = instr[11:8]
imm[0]    = 0
```

U-Type：就是将 immediate << 12 

```
imm = {instr[31:12], 12'b0};
```

J-Type:同样描述指令，最低位为 0，高位同样符号位扩展

```
imm[20]    = instr[31]
imm[19:12] = instr[19:12]
imm[11]    = instr[20]
imm[10:1]  = instr[30:21]
imm[0]     = 0
```

同时定义一个控制信号，通过 MUX 选择，来决定正确拼法

```
typedef enum logic [2:0] {
    IMM_I,
    IMM_S,
    IMM_B,
    IMM_U,
    IMM_J
} imm_sel_t;IMM_J
```

## 3、decode -> ctrl

a、源寄存器使用信息 use_rs1、use_rs2

代表当前指令，用到了 rs1、rs2 中的哪个，用于后续 module 获取源操作数，或者展开冒险判断

b、ALU 控制 alu\_op

来决定 ALU 执行那种操作

```
ALU_ADD
ALU_SUB
ALU_SLL
ALU_SLT
ALU_SLTU
ALU_XOR
ALU_SRL
ALU_SRA
ALU_OR
ALU_AND
```

c、ALU 两个输入从哪里来

alu\_src\_a：有可能来自 rs1、pc、0

alu\_src\_b：有可能来自 rs2、immediate

d、Memory 控制

mem\_read ：lw

mem\_write：sw

同时 RV32I 支持不同长度存储操作：LB、LH、LW、LBU、LHU   SB、SH、SW；因此还要作以区分，func3 包含了这个信息，因此也必须一路送到 MEM

e、Register Writeback

reg\_write：表示是否需要写回操作

wb\_sel：写回的数据来自哪里：ALU，Mem read data，PC+4

f、Immediate 类型：上面立即数时候已经介绍过来

imm\_sel：立即数类型，用于 immediate generate

g、Control Flow

ctrl\_flow：用于指示 EX 该做什么操作，branch 有很多种，具体 beq 还是 bne 还是 blt 等等取决于 func3，同样将 func3 传过去

```
FLOW_NORMAL
FLOW_BRANCH
FLOW_JAL
FLOW_JALR
```

总结：并且还有随流水传递 rd、rs1、rs2 用于 forwarding 和 RAW Hazard Detection，以及 funct3

```
Decoder
    use_rs1
    use_rs2
 
    alu_op
    alu_src_a
    alu_src_b
 
    imm_sel
 
    mem_read
    mem_write

    reg_write
    wb_sel

    ctrl_flow

    func3
```



## 4、ID：RAW Hazard Detection

1、最普通的 RAW

```
I1: add x5, x1, x2
I2: sub x6, x5, x3 

存在 WAR，     但是我们不 Stall
Cycle        1       2       3       4       5       6

I1 ADD       IF      ID      EX      MEM     WB
I2 SUB               IF      ID      EX      MEM      WB 

因为 Cycle 3 ADD 在 EX 算出结果，在 cycle 4 直接送到 ALU 输入，给 sub 用，这就是EX/MEM → EX Forwarding

在 EX 存在如下 MUX，即 ID 读出的数据不一定就是 EX 最终使用的数据：
RegFile旧值 ─────┐
                 │
EX/MEM结果 ──────┼──► MUX ──► ALU
                 │
MEM/WB结果 ──────┘ 
```

所以普通 ALU RAW 不需要 Stall，forwarding 就能解决

2、lw + add  RAW  比如：

```
I1: lw  x5, 0(x1)
I2: add x6, x5, x2
```

I1 在 cycle 4 结束才能得到 x5 的值，但 I2 cycle 的开始就需要用，所以 I2 必须 Stall 一拍

即当 I2 在 ID state时，发现，

```
ID/EX.mem_read = 1
ID/EX.rd == ID.rs1
```

就需要 stall，

```
PC       HOLD
IF/ID    HOLD
ID/EX    BUBBLE
```

等到 cycle4 ，load data done forward -> ALU src

```
load_use_hazard =
    id_ex_mem_read &&
    (id_ex_rd != 5'd0) &&
    (
        (use_rs1 && (rs1 == id_ex_rd)) ||
        (use_rs2 && (rs2 == id_ex_rd))
    );
```

对于 lw & sw 的情况，同样适用

```
lw x5,0(x1)
sw x5,0(x2)
```

综上，RAW Hazard 的处理分两部分，在 ID 中处理哪些情况必须 stall，然后给 EX 发 bubble

                                                            在 EX 中处理哪些情况无需 stall，然后 拿到 ALU 或者 Mem 的 forward

## 5、branch、jump wait

ID 识别到 Branch/JAL/JALR 后，PC停止正常fetch ，IF/ID不允许产生下一条有效指令，Branch正常进入ID/EX，等 EX 给出 redirect

所以 cycle1，PC = beq，而后取指令

        cycle2，PC = PC+4，IF/ID = beq，而后 ID 开始 decode，发现 instruction 为 beq，另 PC_en = 0

        cycle3,   PC 由于 PC_en = 0，所以 hold old PC + 4，IF_ID_valid = 0，向 ID 传递 bubble，ID/EX = beq，而后 EX 开始执行，本周期结束计算出结果，redirect = 1

        cycle4，EX done，由于 redirect = 1，PC = redirect PC，并且令PC_en = 1，redirect = 0，并且if_id_enable = 1，同时 IF_ID_valid = 0，ID_EX_valid = 0

        cycle5，PC= redirect PC +4，采样到 if_id_enable == 1，令 IF_ID_valid = 1，而 ID_EX_valid 还是 0

即遇到分支，PC hold，IF/ID bubble，ID/EX 正常传 beq 等



## 6、EX busy

        虽然当前设计 EX 只会运行 1 周期，但保留 busy 架构，当 busy 发生，同时控制 PC，IF/ID，ID/EX 均 hold old，即当 EX_ready ==0 时，if_id_en = 0，id_ex_en = 0，

## 7、分支和 Load-use 同时发生

```
lw  x5,0(x1)
beq x5,x2,LABEL
```

先要 bubble 等 Mem forward ALU，再要 bubble wait 分支

## 8、if\_id\_valid = 0

表明 要传递 bubble，直接让 id_ex_en = 0，从而让 id_ex_valid = 0，bubble 就会向后传递