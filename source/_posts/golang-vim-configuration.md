
---
title: VIM配置Golang开发环境
date: 2016-04-01 01:03:26
updated: 2016-04-04
tags:
- Golang
- VIM
categories: Golang
---

直接使用**vim-as-golang-ide**来配置非常简单，具体操作如下。
http://farazdagi.com/blog/2015/vim-as-golang-ide/
对应Github地址：https://github.com/farazdagi/vim-go-ide
然后执行`vim -u ~/.vimrc.go`即可，如果嫌麻烦，可以设置alias.
```bash
alias vimgo='vim -u ~/.vimrc.go'
```
**vim-as-golang-ide**实际上用到的仍然是**vim-go**. vim-as-golang-ide的好处时不破坏系统vim的设置。
vim-go: https://github.com/fatih/vim-go

执行完`vim -u ~/.vimrc.go`出现如下错误。
```bash
CSApprox skipped; terminal only has 8 colors, not 88/256
Try checking :help csapprox-terminal for workarounds
请按 ENTER 或其它命令继续
```
可在`~/.vimrc.go`中进行如下设置。
```bash
set t_Co=256
```
在进行`:GoInstallBinaries`之前需要临时设置`$GOBIN`环境变量，以便vim-go需要的binary放在`/usr/local/go/bin`下。
```bash
export GOBIN=$GOROOT/bin
```

> Please be sure all necessary binaries are installed (such as gocode, godef, goimports, etc.). You can easily install them with the included :GoInstallBinaries command. If invoked, all necessary binaries will be automatically downloaded and installed to your \$GOBIN environment (if not set it will use $GOPATH/bin). Note that this command requires git for fetching the individual Go packages. Additionally, use :GoUpdateBinaries to update the installed binaries.
-- https://github.com/fatih/vim-go


