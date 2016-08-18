---
title: imprecise external abort
date: 2016-08-18 23:14:03
tags:
- imprecise abort
categories: Linux
---

# Background
CPU: ARMv7

开机到kernel某个固定阶段发生死机，死机信息都是imprecise external abort. 
> Unhandled fault: imprecise external abort (0x1c06) at 0x7cab1234

<!--more-->

# Debug
imprecise external abort比较少见，一般来讲abort的时候已经是滞后性的了，也就是说abort仔细check打印的backtrace, 都看不出任何的问题。
先看下kernel中打印`imprecise external abort`的地方。

`arch/arm/mm/fault.c`
```c
/*
 * Dispatch a data abort to the relevant handler.
 */
asmlinkage void __exception
do_DataAbort(unsigned long addr, unsigned int fsr, struct pt_regs *regs)
{
        const struct fsr_info *inf = fsr_info + fsr_fs(fsr);
        struct siginfo info;

        if (!inf->fn(addr, fsr & ~FSR_LNX_PF, regs))
                return;

        printk(KERN_ALERT "Unhandled fault: %s (0x%03x) at 0x%08lx\n",
                inf->name, fsr, addr);

        info.si_signo = inf->sig;
        info.si_errno = 0;
        info.si_code  = inf->code;
        info.si_addr  = (void __user *)addr;
        arm_notify_die("", regs, &info, fsr, 0);
}
```
`do_DataAbort`的第二个参数fsr很有参考价值，是`fault status register`, 第一个参数addr是`fault address register`. 
这2个register的具体含义可以查阅arm trm.

这个时候fault address register记录的并不一定是出错的地址。查看下fsr 0x1c06的意思是什么，对比register description.

Table 4-226 DFSR bit assignments for Short-descriptor translation table format

| Bits     |   Name        |  Function |
|---|---|---|
|[31:14]|    -       |   Reserved, RES0.|
|[13]        |   CM   |      Cache maintenance fault. For synchronous faults, this bit indicates whether a cache maintenance operation generated the fault:  0 Abort not caused by a cache maintenance operation.  1 Abort caused by a cache maintenance operation. |
|[12]      |      ExT  |       External abort type. This field indicates whether an AXI Decode or Slave error caused an abort: 0 External abort marked as DECERR.  **1 External abort marked as SLVERR.** For aborts other than external aborts this bit always returns 0. |
| [11]       |     WnR    |     Write not Read bit. This field indicates whether the abort was caused by a write or a read access: 0 Abort caused by a read access.  **1 Abort caused by a write access.** For faults on CP15 cache maintenance operations, including the VA to PA translation operations, this bit always returns a value of 1. |
|[10]      |      FS[4]     |  Part of the Fault Status field. See bits [3:0] in this table. |
|[9]        |     -      |     RAZ. |
|[8]         |    -     |      Reserved, RES0. |
|[7:4]      |     Domain |     Specifies which of the 16 domains, D15-D0, was being accessed when a data fault occurred. For permission faults that generate Data Abort exception, this field is UNKNOWN. ARMv8 deprecates any use of the domain field in the DFSR. |
| [3:0]     |      FS[3:0]   |  Fault Status bits. This field indicates the type of exception generated. Any encoding not listed is reserved. |
FS[3:0] :
0b00001 Alignment fault. 
0b00010 Debug event.
0b00011 Access flag fault, section.
0b00100 Instruction cache maintenance fault.
0b00101 Translation fault, section.
**0b00110 Access flag fault, page.**
0b00111 Translation fault, page.
0b01000 Synchronous external abort, non-translation.
0b01001 Domain fault, section.
0b01011 Domain fault, page.
0b01100 Synchronous external abort on translation table walk, first level.
0b01101 Permission fault, section.
0b01110 Synchronous external abort on translation table walk, second level.
0b01111 Permission fault, second level.
0b10000 TLB conflict abort.
0b10101 LDREX or STREX abort.
0b10110 Asynchronous external abort.
0b11000 Asynchronous parity error on memory access.
0b11001 Synchronous parity error on memory access.
0b11100 Synchronous parity error on translation table walk, first level.
0b11110 Synchronous parity error on translation table walk, second level. 

还是不知道出错的地方在哪里。突然想到这款IC有bus monitor的功能，check bus记录的发生abort的register, 还真有个写DRAM address发生abort.
进一步check发现写这个DRAM address其实是在很早之前的uboot阶段。写的DRAM address超出了DRAM size而导致的问题。将其fix掉，则没有了imprecise external abort, 可以正常开机了。

那么为什么在uboot阶段没有及时abort呢？ 因为uboot阶段CPSR.A是mask的，如果将uboot阶段CPSR.A改成unmask, 然后再复现此问题，那么uboot阶段就会比较及时地收到abort, 进入异常向量的abort处理流程。

# What is imprecise abort?
[1] https://community.arm.com/thread/5622
[2] http://stackoverflow.com/questions/27507013/synchronous-external-abort-on-arm
> An **abort** means the CPU tried to make a memory access, which for whatever reason, couldn't be completed so raises an exception.
An **external abort** is one from, well, externally to the processor, i.e. something on the bus. In other words, the access didn't fault in the MMU, went out onto the bus, and either some device or the interconnect itself came back and said "hey, I can't deal with this".
A **synchronous external** abort means you're rather fortunate, in that it's not going to be utterly hideous to debug - in the case of a prefetch abort, it means the IFAR is going to contain a valid VA for the faulting instruction, so you know exactly what caused it. The unpleasant alternative is an **asynchronous external abort**, which is little more than an interrupt to say "hey, something you did a while ago didn't actually work. No I don't know what is was either."

[3] http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.faqs/14809.html
