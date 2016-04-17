---
title: how to use flux in ubuntu
date: 2016-04-17 22:44:16
tags: 
- f.lux
- Ubuntu
categories: Ubuntu
---

***[f.lux](https://justgetflux.com/)***是一款出色的护眼软件，可根据所在地的日出日落时间动态调节色温，过滤蓝光。一旦用上它，你会发现就再也无法离开它了。
<!--more-->

# Install fluxgui
```bash
sudo add-apt-repository ppa:kilian/f.lux
sudo apt-get update
sudo apt-get install fluxgui
```
然后运行fluxgui, 勾选上"Autostart f.lux indeicator applet"，填写好所在地的经纬度，设置完成。
此时发现flux并没有正常work. 还需要安装flux.
![f.lux-indicator-applet-preferences.png](/img/f.lux_indicator_applet_preferences_001.png)

# Install flux
上面安装的仅仅是一个GUI, 核心的flux还需要重新安装下。
64bit版本：[xflux64.tgz](https://justgetflux.com/linux/xflux64.tgz)
32bit版本：[xflux32.tgz](https://justgetflux.com/linux/xflux-pre.tgz)
然后解压，将解压出来的xflux拷贝到/usr/bin/下即可。
再设置fluxgui，即可生效。
