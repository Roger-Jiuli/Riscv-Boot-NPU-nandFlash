# 一、计算机体系结构

CPU 处理指令有五个阶段：

1. IF 取指令，根据条件，决定 PC 是多少，根据 PC 去 instruction mem 取指令，并计算 PC + 4

2. ID 译码，将指令拆分，获取 opcode，rd，立即数等，并读寄存器

3. EXE 执行，用 ALU 进行加，乘，比较等计算

4. MEM 访存，就读写数据存储器，LW SW 会操作这个

5. WB 写回，将 ALU 结果，或者 读存储器的结果写回 寄存器



CPU 执行方式：

单周期处理器：一条指令，从取指到执行完成，全部在一个时钟周期内搞定。

多周期处理器：每个周期只执行一个阶段，但同一时刻只执行一条指令

流水线处理器：一条指令仍然分多个阶段、多个周期执行，但允许多条指令同时处于不同阶段

in order 流水线处理器：指令顺序执行，但如果某条指令在某个阶段处理的特别久，后续指令就只能 stall 住等着，但好处是，在经典单发射五级顺序流水中，寄存器读取和写回发生在固定流水阶段，且指令保持顺序推进，因此 WAR/WAW 不会形成需要额外处理的 hazard

out of other 流水线处理器：指令可以乱序执行，比如，如果有 某条老指令因为操作数未就绪、Cache Miss、长延迟执行单元等原因迟迟不能执行，而后面的独立指令已经 Ready，所以后续没有依赖，就没必要等它，可以先完成执行，但是会引入 WAW 和 WAR 的依赖，这需要新的算法解决



forwarding：是为了解决，如下一个指令要用到上一个指令的结果，那它其实不用等到写回，再读寄存器，可以ALU 结束直接 forward 到 exe 的输入

打分板：为乱序执行提供一种方法，但是无法解决依赖，仍是 stall，没有像 Tomasulo 那样通过寄存器重命名消除 WAR/WAW

Tomasulo：能够解决WAW 和 WAR，原理是通过保留站，记录 tag 和 广播，以产生结果的保留站标识为tag，如果有想要读取某个值，来自这个计算单元，那么就记录这个 tag，等到它算好了，会广播结果，匹配上 Tag 的就会更新对应的值，如果有WAW，就直接更新成新的 tag，如果有 WAR ，可以直接将数据读到保留栈，不会阻塞后续写，但是就会出现没有按照顺序写回的问题

ROB：同样保存 tag，广播时会更新值，但不立即commit，而是乱序完成、顺序提交，同时读取某一个寄存器的值时，既要看寄存器，又要看 ROB，因为最新的值可能在 ROB 里

物理寄存器重命名：物理寄存器比架构寄存器远远多出，维护 Rename Map Table & Free List，给每个要写的架构寄存器分配新的物理寄存器，并记录上一次分配的物理寄存器，顺序 commit 的时候，当本次物理寄存器的结果计算出来了，就把上次的旧物理寄存器释放，改成新的映射，来解决写后写，和读后写（因为虽然是同一个寄存器，但实际写的已经是另一个被 mapping 的物理寄存器了），并且完成实现了顺序提交，有异常时，按照已经 commit 的恢复现场（有些架构选择保存旧映射，异常时回滚旧映射，有些选择另外维护一份 commit table 展示给架构）

分支预测：



# 二、IF 架构设计

架构图：

![IF ARCH](../images/IF_arch.png)



1、PC MUX -> reg

来源：a、PC + 4 正常执行时，走这条路

          b、来自 EX 的 redirect PC，用于 branch，jump 指令等

          c、old PC：对于 stall（由于后续模块未执行完，当前指令不能进入ID， ID/IF 和 PC 均需要 hold），和 flush 的情况（ID 解析出 branch 和 jump 指令等，在 EX 结束前，后面不能产生有效指令，因此 PC 要 hold，ID/IF 要 bubble）

控制信号：当 redirect_valid 时，说明 PC 需要跳转至来自 EX 的新地址，并且寄存一拍，if_id_en 立起，读取的新指令进入 IF/ID 

                 当 !redirect_valid & PC_en ，说明是正常流程，选择 PC+4

                 当 !redirect_valid & !PC_en，说明是 stall 或者 flush，PC 需要hold，选 old PC，同时对应着 if_id_en、if_id_flush 不同的值



2、instruction Memory

输入：PC & readen

输出：instruction body



3、IF/ID pipeline reg

寄存 PC 用于后续 ex 做计算会用到，寄存 instruction body 用于 ID decode

控制信号：

| if_id_enable | if_id_flush | 动作      | 对应               |
| ------------ | ----------- | ------- | ---------------- |
| 0            | 0           | 保持      | stall，ID 不获取指令   |
| 1            | 0           | 接收新指令   | ID 获取新指令         |
| X            | 1           | valid=0 | bubble，ID 获取到空指令 |






