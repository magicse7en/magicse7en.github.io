---
title: bad pmd issue analysis
date: 2016-08-19
tags: hwbp
categories: Linux
---

# Background
Kernel: linux3.10

发生概率性死机：

>mm/memory.c:399: bad pmd 15141312
Segmentation fault
BUG: Bad rss-counter state mm:ce964380 idx:0 val:5
BUG: Bad rss-counter state mm:ce964380 idx:1 val:1

<!--more-->

对发生Segmentation fault的user space process注册signal handler, 发现死机时并没有进入到signal handler中。在kernel `__do_uesr_fault`中判断SIGSEGV时dump register, rebuild出backtrace, 发现每次都不一样，结合汇编code来看，没有发现可疑的地方。
bad pmd的提示比较怀疑该process的地址空间的pgd已经出现问题，然后再发生的SIGSEGV.
因为是烧机问题，所以利用hw breakpoint来监控process的task_struct的mm->pgd.

hw breakpoint config
```
CONFIG_HAVE_HW_BREAKPOINT=y
CONFIG_PERF_EVENTS=y
# CONFIG_HAVE_PERF_EVENTS is not sest
# CONFIG_DEBUG_PERF_USE_VMALLOC is not set
# CONFIG_HW_PERF_EVENTS is not set
```
参考`samples/hw_breakpoint/data_breakpoint.c`的code对出问题的process的mm->pgd添加写监控。

```c
/* init & register hwbp handler*/
hw_break_module_init()
    -> hw_breakpoint_init()
    -> register_wide_hw_breakpoint(&attr, sample_hbp_handler, NULL)
/* exit & unregister hwbp */
hw_break_module_exit()
```
然后再重新烧机复制，果然发现pgd有被盖写，通过打印的backtrace即可锁定凶手。
