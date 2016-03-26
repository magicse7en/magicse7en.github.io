---
title: lzo decompress kernel zImage crash analysis
date: 2016-03-08 23:05:08
tags: [lzo,zImage]
categories: Linux
---

# Background
CPU: ARMv7
Kernel: 3.10.26

最近把压缩kernel的算法由gzip改成lzo，在boot自解压kernel阶段CPU会abort. 

<!--more-->

# Debug
先check压缩kernel的算法是否已经是lzo了，check arch/arm/boot/compressed下已经有piggy.lzo文件了。check系统从flash中load的zImage也是正确的，自解压kernel之前位于DRAM中的zImage的data也是正确的。出现crash之后，再去check DRAM中zImage data，发现并没有发现变化，说明zImage src data是正确的，并没有被盖写，只能是在自解压过程中出现问题了。

debug发现每次都是解压固定的某块数据时出错，C code是位于**include/linux/unaligned/le_struct.h**
```c
static inline u16 get_unaligned_le16(const void *p)
{
    return __get_unaligned_cpu16((const u8 *)p);
}
```
对应的具体出错的汇编指令是
```asm
ldrh r12, [r8], #02
```
出错时r8的值是奇数，比如是0x04000003，于是怀疑是对齐问题。check了下kernel config，也没有发现漏掉了跟对齐相关的config. 查看DFAR和DFSR register，发现Fault Status bits是0x1, 对照ARM手册，就是alignment fault.
>FS[3:0]	 Fault Status bits. This field indicates the type of exception generated. Any encoding not listed is reserved:
>       **0b00001 Alignment fault.**
>       0b00010 Debug event.
>       0b00011 Access flag fault, section.
>       0b00100 Instruction cache maintenance fault.
>       0b00101 Translation fault, section.
>       0b00110 Access flag fault, page.
>       0b00111 Translation fault, page.
>       0b01000 Synchronous external abort, non-translation.
>       0b01001 Domain fault, section.
>       0b01011 Domain fault, page.
>       0b01100 Synchronous external abort on translation table walk, first level.
>       0b01101 Permission fault, section.
>       0b01110 Synchronous external abort on translation table walk, second level.
>       0b01111 Permission fault, second level.
>       0b10000 TLB conflict abort.
>       0b10101 LDREX or STREX abort.
>       0b10110 Asynchronous external abort.
>       0b11000 Asynchronous parity error on memory access.
>       0b11001 Synchronous parity error on memory access.
>       0b11100 Synchronous parity error on translation table walk, first level.
>       0b11110 Synchronous parity error on translation table walk, second level.
    
进一步debug, 发现在解压过程中上述指令中的r8值经常会出现奇数，也没有发生crash，为什么唯独到了解压某个固定的block时就会出问题呢？于是乎怀疑出问题时的这段memory跟其他memory属性不一样，check MMU table，果不其然，crash时指令访问的memory的属性是outer, Device的，而其他段mapping的memory属性是可读可写的。

接下来就来check 自解压kernel时MMU table是何时打开的？何时mapping的？
**arch/arm/boot/compressed/head.S**
```c
__setup_mmu:    sub     r3, r4, #16384          @ Page directory size
                 bic     r3, r3, #0xff           @ Align the pointer
                 bic     r3, r3, #0x3f00
 /*
  * Initialise the page tables, turning on the cacheable and bufferable
  * bits for the RAM area only.
  */
                 mov     r0, r3
                 mov     r9, r0, lsr #18
                 mov     r9, r9, lsl #18         @ start of RAM
                 add     r10, r9, #0x10000000    @ a reasonable RAM size
                 mov     r1, #0x12               @ XN|U + section mapping
                 orr     r1, r1, #3 << 10        @ AP=11
                 add     r2, r3, #16384
 1:              cmp     r1, r9                  @ if virt > start of RAM
                 cmphs   r10, r1                 @   && end of RAM > virt
                 bic     r1, r1, #0x1c           @ clear XN|U + C + B
                 orrlo   r1, r1, #0x10           @ Set XN|U for non-RAM
                 orrhs   r1, r1, r6              @ set RAM section settings
                 str     r1, [r0], #4            @ 1:1 mapping
                 add     r1, r1, #1048576
                 teq     r0, r2
                 bne     1b
```
这段汇编code设定了mapping的属性。

# RootCause
uImage中设定zImage的execute address不合适导致的上述code设定的MMU属性不对。