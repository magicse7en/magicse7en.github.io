---
title: magic 11s
date: 2017-03-07
tags:
- ANR
- ftrace
categories: Linux
---

The 3rd apk is hung up 11s while playback.

The direct appearance is ANR: Input event dispatching timed out sending. This ANR is caused by mediaplayer process.

Firstly, we use `top` to watch CPU loading, but find that CPU loading is not high when playback.

Secondly, check `/proc/interrupts`, we cannot find any interrupt abnormal.

This is a customer on-site issue, we only digg the log. We add some debug logs, and find that sometimes the interval printing two logs is 11s,it's weird.

We doubt that system scheduling maybe occur anomaly. So capture ftrace data.
1. start ftrace
```
mount -t debugfs nodev /sys/kernel/debug
echo nop > /sys/kernel/debug/tracing/current_tracer
echo 0 > /sys/kernel/debug/tracing/tracing_on
echo > /sys/kernel/debug/tracing/trace
echo "sched_switch sched_wakeup sched_wakeup_new sched_migrate_task irq timer" > /sys/kernel/debug/tracing/set_event
echo "workqueue_execute_start workqueue_execute_end block_rq_issue block_rq_insert block_rq_complete" >> /sys/kernel/debug/tracing/set_event
echo 20480 > /sys/kernel/debug/tracing/buffer_size_kb
echo 1 > /sys/kernel/debug/tracing/tracing_on
```
2. stop ftrace (stop ftrace immediately once be reproduced)
```
echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace > /data/ftrace.log
echo 0 > /sys/kernel/debug/tracing/trace
```

Notes: How to make ANR time printed by `logcat` to match Unix Timestamp. There is a very good tool: http://rimzy.net/tools/php_timestamp_converter.php

Go through digging ftrace data, we found a doubtful point: process X hasn't scheduled about 11s.
* use `renice` and `tasklet` to improve process priority and bind process X to specific CPU, it's no improvement.
* We found that process X `sched_wakeup` from idle process, it means process X is waked up by interrupt. The latest interrupt is uart interrupt.
So we disable uart log or change uart baud rate to 921600, the ANR disappeared.


At last, we review n_tty_write() function.
```
2019 static ssize_t n_tty_write(struct tty_struct *tty, struct file *file,
2020                            const unsigned char *buf, size_t nr)
2021 {
2022         const unsigned char *b = buf;
2023         DECLARE_WAITQUEUE(wait, current);
2024         int c;
2025         ssize_t retval = 0;
2026
2027         /* Job control check -- must be done at start (POSIX.1 7.1.1.4). */
2028         if (L_TOSTOP(tty) && file->f_op->write != redirected_tty_write) {
2029                 retval = tty_check_change(tty);
2030                 if (retval)
2031                         return retval;
2032         }
2033
2034         /* Write out any echoed characters that are still pending */
2035         process_echoes(tty);
2036
2037         add_wait_queue(&tty->write_wait, &wait);
2038         while (1) {
2039                 set_current_state(TASK_INTERRUPTIBLE);
2040                 if (signal_pending(current)) {
2041                         retval = -ERESTARTSYS;
2042                         break;
2043                 }
2044                 if (tty_hung_up_p(file) || (tty->link && !tty->link->count)) {
2045                         retval = -EIO;
2046                         break;
2047                 }
2048                 if (O_OPOST(tty)) {
2049                         while (nr > 0) {
2050                                 ssize_t num = process_output_block(tty, b, nr);
2051                                 if (num < 0) {
2052                                         if (num == -EAGAIN)
2053                                                 break;
2054                                         retval = num;
2055                                         goto break_out;
2056                                 }
2057                                 b += num;
2058                                 nr -= num;
2059                                 if (nr == 0)
2060                                         break;
2061                                 c = *b;
2062                                 if (process_output(c, tty) < 0)
2063                                         break;
2064                                 b++; nr--;
2065                         }
2066                         if (tty->ops->flush_chars)
2067                                 tty->ops->flush_chars(tty);
2068                 } else {
2069                         while (nr > 0) {
2070                                 c = tty->ops->write(tty, b, nr);
2071                                 if (c < 0) {
2072                                         retval = c;
2073                                         goto break_out;
2074                                 }
2075                                 if (!c)
2076                                         break;
2077                                 b += c;
2078                                 nr -= c;
2079                         }
2080                 }
2081                 if (!nr)
2082                         break;
2083                 if (file->f_flags & O_NONBLOCK) {
2084                         retval = -EAGAIN;
2085                         break;
2086                 }
2087                 schedule();
2088         }
2089 break_out:
2090         __set_current_state(TASK_RUNNING);
2091         remove_wait_queue(&tty->write_wait, &wait);
2092         if (b - buf != nr && tty->fasync)
2093                 set_bit(TTY_DO_WRITE_WAKEUP, &tty->flags);
2094         return (b - buf) ? b - buf : retval;
2095 }
```
Write data in while loop. When user space process uses blocking write method, if write fail, it will yield cpu and wake up untill the condition is met. In this ANR case, the root cause is that user space process instant log data is huge and block in n_tty_write().
