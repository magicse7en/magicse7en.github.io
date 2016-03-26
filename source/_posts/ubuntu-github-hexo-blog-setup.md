---
title: Ubuntu + Github + Hexo搭建blog小记
date: 2016/3/6
updated: 2016/3/23
tags: hexo
categories: Blog
---

当Jekyll教程在收藏夹中沉睡很久之后，发现时兴已经是Hexo了。
于是折腾了一把Hexo+Github搭建博客，总算落实夙愿了。

# Install Git & Github配置
## Install git
```bash
apt-get install git
```
然后配置username和email
```bash
git config --global user.name "xxx"
git config --global user.email "xxx@xxx.com"
```
## Generate ssh-key
```{bash}
ssh-keygen -t rsa -C "xxx@xxx.com"
```
如果没有Github账户的话，则注册一个，将.ssh/id_rsa.pub中的内容复制到Github的Settings-> SSH Keys-> New SSH Key
```{bash}
ssh -T git@github.com
```
会提示
> The authenticity of host 'github.com (207.97.227.239)' can't be established.RSA key fingerprint is 16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48.Are you sure you want to continue connecting (yes/no)?

输入yes就好，然后会提示：

>Hi xxx! You've successfully authenticated, but GitHub does not provide shell access.

## Create Repository
名字必须是GithubId.github.io

<!--more-->

# Install NodeJs
Nodejs官网下载tarball->解压->创建软链接
```bash
ln -s /home/xxx/Software/node-v4.3.2-linux-x64/bin/node /usr/local/bin/node
ln -s /home/xxx/Software/node-v4.3.2-linux-x64/bin/npm /usr/local/bin/npm
```

# Install Hexo
docs: https://hexo.io/docs/
```bash
npm install -g hexo
mkdir hexo
ln -s /home/xxx/Software/node-v4.3.2-linux-x64/bin/hexo /usr/local/bin/hexo
hexo init
hexo generate
hexo server #启动server, 在浏览器中输入 http://localhost:4000 可以看到页面
```
配置文件
将*_config.yml*中type改成如下：
```bash
deploy:
  type: git
  repository: https://github.com/githubid/githubid.github.io.git
  branch: master
```
然后部署，即可浏览https://githubid.github.io ，博客页面出现了。
```bash
npm install hexo-deployer-git --save
hexo deploy
```

# Generate & Deploy
新建博客：
```bash
hexo new hello-hexo
```
然后可以使用Markdown语法编辑source/_posts/hell-hexo.md
编辑完成之后，使用hexo generate产生，然后可以启动server: hexo server，本地浏览页面效果。
满意之后可以直接部署到github:
hexo deploy

每次deploy前最好clean一下
```bash
hexo clean
```

生成和部署可以直接使用
```bash
hexo g -d
```

# Themes configuration
有选择困难症太纠结，最后还是选择了Next主题，配置手册: [http://theme-next.iissnan.com]



