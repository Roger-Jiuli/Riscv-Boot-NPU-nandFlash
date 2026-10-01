# 一、IF 架构设计

架构图：

![IF ARCH](../images/IF_arch.png)



## 1、PC MUX -> reg

来源：a、PC + 4 正常执行时，走这条路

          b、来自 EX 的 redirect PC，用于 branch，jump 指令等

          c、old PC：对于 stall（由于后续模块未执行完，当前指令不能进入ID， ID/IF 和 PC 均需要 hold），和 flush 的情况（ID 解析出 branch 和 jump 指令等，在 EX 结束前，后面不能产生有效指令，因此 PC 要 hold，ID/IF 要 bubble）

控制信号：当 redirect_valid 时，说明 PC 需要跳转至来自 EX 的新地址，并且寄存一拍，if_id_en 立起，读取的新指令进入 IF/ID 

                 当 !redirect_valid & PC_en ，说明是正常流程，选择 PC+4

                 当 !redirect_valid & !PC_en，说明是 stall 或者 flush，PC 需要hold，选 old PC，同时对应着 if_id_en、if_id_flush 不同的值



## 2、instruction Memory

输入：PC & readen

输出：instruction body



## 3、IF/ID pipeline reg

寄存 PC 用于后续 ex 做计算会用到，寄存 instruction body 用于 ID decode

控制信号：

| if_id_enable | if_id_flush | 动作      | 对应               |
| ------------ | ----------- | ------- | ---------------- |
| 0            | 0           | 保持      | stall，ID 不获取指令   |
| 1            | 0           | 接收新指令   | ID 获取新指令         |
| X            | 1           | valid=0 | bubble，ID 获取到空指令 |
