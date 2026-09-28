| 指令   | 类型  | 功能    | 指令格式         | 运算规则                      | 关键控制信号              |
| ---- | --- | ----- | ------------ | ------------------------- | ------------------- |
| ADD  | R   | 寄存器加法 | rd, rs1, rs2 | rd = rs1 + rs2            | RegWrite=1, ALU_ADD |
| SUB  | R   | 寄存器减法 | rd, rs1, rs2 | rd = rs1 - rs2            | RegWrite=1, ALU_SUB |
| AND  | R   | 按位与   | rd, rs1, rs2 | rd = rs1 & rs2            | ALU_AND             |
| OR   | R   | 按位或   | rd, rs1, rs2 | rd = rs1 \| rs2           | ALU_OR              |
| XOR  | R   | 按位异或  | rd, rs1, rs2 | rd = rs1 ^ rs2            | ALU_XOR             |
| SLL  | R   | 逻辑左移  | rd, rs1, rs2 | rd = rs1 << rs2[4:0]      | ALU_SLL             |
| SRL  | R   | 逻辑右移  | rd, rs1, rs2 | rd = rs1 >> rs2[4:0]      | ALU_SRL             |
| SRA  | R   | 算术右移  | rd, rs1, rs2 | rd = signed(rs1) >>> rs2  | ALU_SRA             |
| SLT  | R   | 有符号比较 | rd, rs1, rs2 | rd=(rs1<rs2)?1:0          | ALU_CMP             |
| SLTU | R   | 无符号比较 | rd, rs1, rs2 | rd=(rs1<rs2)?1:0 unsigned | ALU_CMP             |

| 指令    | 类型  | 功能      | 指令格式               | 运算规则                   | 关键控制信号     |
| ----- | --- | ------- | ------------------ | ---------------------- | ---------- |
| ADDI  | I   | 加立即数    | rd, rs1, imm[11:0] | rd=rs1+imm             | ALUSrc=imm |
| ANDI  | I   | 与立即数    | rd, rs1, imm       | rd=rs1&imm             | ALU_AND    |
| ORI   | I   | 或立即数    | rd, rs1, imm       | rd=rs1\|imm            | ALU_OR     |
| XORI  | I   | 异或立即数   | rd, rs1, imm       | rd=rs1^imm             | ALU_XOR    |
| SLTI  | I   | 有符号比较   | rd, rs1, imm       | rd=(rs1<imm)           | ALU_CMP    |
| SLTIU | I   | 无符号比较   | rd, rs1, imm       | rd=(rs1<imm) unsigned  | ALU_CMP    |
| SLLI  | I   | 左移立即数   | rd, rs1, shamt     | rd=rs1<<shamt          | ALU_SLL    |
| SRLI  | I   | 逻辑右移立即数 | rd, rs1, shamt     | rd=rs1>>shamt          | ALU_SRL    |
| SRAI  | I   | 算术右移立即数 | rd, rs1, shamt     | rd=signed(rs1)>>>shamt | ALU_SRA    |

| 指令  | 类型  | 功能          | 指令格式         | 运算规则                     | 关键控制信号  |
| --- | --- | ----------- | ------------ | ------------------------ | ------- |
| LB  | I   | 读8bit有符号数据  | rd, imm(rs1) | rd=SignExt(Mem[rs1+imm]) | MemRead |
| LH  | I   | 读16bit有符号数据 | rd, imm(rs1) | rd=SignExt(Mem[addr])    | MemRead |
| LW  | I   | 读32bit数据    | rd, imm(rs1) | rd=Mem[rs1+imm]          | MemRead |
| LBU | I   | 读8bit无符号    | rd, imm(rs1) | rd=ZeroExt(Mem[addr])    | MemRead |
| LHU | I   | 读16bit无符号   | rd, imm(rs1) | rd=ZeroExt(Mem[addr])    | MemRead |

| 指令  | 类型  | 功能       | 指令格式          | 运算规则                | 关键控制信号   |
| --- | --- | -------- | ------------- | ------------------- | -------- |
| SB  | S   | 存8bit数据  | rs2, imm(rs1) | Mem[addr]=rs2[7:0]  | MemWrite |
| SH  | S   | 存16bit数据 | rs2, imm(rs1) | Mem[addr]=rs2[15:0] | MemWrite |
| SW  | S   | 存32bit数据 | rs2, imm(rs1) | Mem[addr]=rs2       | MemWrite |

| 指令   | 类型  | 功能      | 指令格式           | 运算规则                    | 关键控制信号    |
| ---- | --- | ------- | -------------- | ----------------------- | --------- |
| BEQ  | B   | 相等跳转    | rs1,rs2,offset | if(rs1==rs2) PC+=offset | Branch_EQ |
| BNE  | B   | 不等跳转    | rs1,rs2,offset | if(rs1!=rs2) PC+=offset | Branch_NE |
| BLT  | B   | 小于跳转    | rs1,rs2,offset | if(rs1<rs2) PC+=offset  | Branch_LT |
| BGE  | B   | 大于等于跳转  | rs1,rs2,offset | if(rs1>=rs2) PC+=offset | Branch_GE |
| BLTU | B   | 无符号小于   | rs1,rs2,offset | unsigned比较              | Branch_LT |
| BGEU | B   | 无符号大于等于 | rs1,rs2,offset | unsigned比较              | Branch_GE |

| 指令    | 类型  | 功能          | 指令格式           | 运算规则            | 关键控制信号   |
| ----- | --- | ----------- | -------------- | --------------- | -------- |
| LUI   | U   | 加载高20bit立即数 | rd, imm[31:12] | rd=imm<<12      | RegWrite |
| AUIPC | U   | PC加立即数      | rd, imm[31:12] | rd=PC+(imm<<12) | ALU_ADD  |

| 指令   | 类型  | 功能        | 指令格式       | 运算规则                | 关键控制信号 |
| ---- | --- | --------- | ---------- | ------------------- | ------ |
| JAL  | J   | 跳转并保存返回地址 | rd, offset | rd=PC+4; PC+=offset | Jump   |
| JALR | I   | 寄存器跳转     | rd,rs1,imm | rd=PC+4; PC=rs1+imm | Jump   |

| 类型     | 结构                                                 |
| ------ | -------------------------------------------------- |
| R-Type | opcode + rd + funct3 + rs1 + rs2 + funct7          |
| I-Type | opcode + rd + funct3 + rs1 + imm[11:0]             |
| S-Type | opcode + imm[11:5] + rs2 + rs1 + funct3 + imm[4:0] |
| B-Type | opcode + imm + rs2 + rs1 + funct3 + imm            |
| U-Type | opcode + rd + imm[31:12]                           |
| J-Type | opcode + rd + imm(offset)                          |

![RISC-V Instruction Type](../images/RISC-V_insrtuction_type.png)


