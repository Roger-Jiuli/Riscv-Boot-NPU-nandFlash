# 三、EX 架构

EX 主要负责四件事：

1. Forwarding
2. ALU 运算
3. Branch / JAL / JALR resolve
4. 产生送往 EX/MEM 的结果

![EX_arch](../images/EX_arch.png)

## 1、forwarding UNIT

EX 第一件事就是 Forwarding，把 rs1 和 rs2 的data 更新成真正的最新的数据，而后再和其他输入一起，进入 ALU input mux，或者 branch input mux，或者直接送 EX/Mem 

forwarding unit 的判断方式有两个：

一个是源操作数来自 EX 的 result：

```
id_ex_use_rs1 &&
ex_mem_reg_write && (ex_mem_wb_sel == ALU | PC+4) &&
(ex_mem_rd != 5'd0) &&
(id_ex_rs1 == ex_mem_rd)

src1_fwd = ex_mem_data (要进一步选择 data 来自 alu_result 还是 PC+4)
```

另一个是源操作数来自 MEM lw 的 result：

```
mem_wb_reg_write && (mem_wb_wb_sel == MEM) &&
(mem_wb_rd != 5'd0) &&
(id_ex_rs1 == mem_wb_rd)

src1_fwd = ex_mem_data (要进一步选择 data 来自 alu_result 还是 mem data 还是 PC+4)
```

还有一个特殊情况是，EX 与 MEM 同时匹配上了，应该选哪个呢，比如

```
add  x5,x1,x2
addi x5,x5,1
sub  x6,x5,x3
```

肯定要选择 EX\MEM 的，这里的是离当前指令最近的生产者，也就是最新值

数据流：
![forwarding_mux](../images/forwarding_mux.png)



## 2、ALU 数据通路

首先就是根据 ID/EX 传来的 alu\_src\_a、 alu\_src\_b选定 ALU 的输入 A B 来源：

A：ALU_A_RS1、ALU_A_PC、ALU_A_ZERO

B：ALU_B_RS2、ALU_B_IMM

接下来是所有需要的 ALU 计算单元，根据ID/EX 传来的 ALUop 来定，这个在 ID 章节已经讲过了

要注意，ALU 不止计算普通的 R type 和 I type 的指令，还会计算 S B U J 指令的运算 



## 3、Control Flow

EX 要根据 id\_ex\_ctrl\_flow 来决断出：

    要不要改 PC → redirect\_valid
    PC 改成多少 → redirect\_pc

### 1、redirect\_valid

    对于我们的微架构，对于 BRANCH taken 的情况，redirect\_valid 要等于 1，同时给出 redirect\_pc 指示 PC 进行跳转，而 BRANCH taken、JAL、JALR ，redirect\_pc 都有各自的计算规则

    对于 BRANCH not taken，要控制 IF 的控制信号 pc_en=1、if_id_en=1，恢复 PC 正常取值，以及恢复 id_if_valid

#### 1.1 branch 怎么判断 taken 还是 not taken

    要根据 funct3 决定 **src1\_fwd** vs **src2\_fwd** 的比较方式

### 2、redirect\_pc

redirect\_pc = alu\_result，由 ALU 直接计算获取得到，ALU 的操作数来源和 opcode 在 ID 阶段就已经生成好了

Branch 还要加额外的组合判断，来 src1\_fwd vs src2\_fwd，判断 taken or not taken，以决定 redirect\_pc 是 alu\_result 还是 PC + 4

### 3、id_ex_valid

如果 id_ex_valid == 0，说明期望传一个 bubble，不期望后续有新的结果产生，也不期望有数据传给 EX/Mem，方法就是，EX 的组件生成结果时，都要 & id_ex_valid，并且传给 Mem 时，要 ex\_mem\_valid \<= id\_ex\_valid;



## 4、EX/MEM 的输出信号

![EX_MEM_output](../images/EX_MEM_output.png)

以及 控制 EX/MEM 寄存器怎么更新的组合信号：ex\_mem\_en、ex\_mem\_flush



