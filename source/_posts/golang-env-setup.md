
---
title: Golang环境配置
date: 2016-03-29 23:55:42
updated: 2016-03-29
tags: Golang
categories: Golang
---

# Install Golang
Golang安装参考https://golang.org/doc/install
# 相关环境变量
环境变量设置，将如下设置写到~/.profile文件中：
```bash
export GOROOT=/usr/local/go
export GOBIN=$GOROOT/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH:$GOBIN
```
## GOROOT
GOROOT是go的安装路径
package runtime中：
[/src/runtime/extern.go:213](https://golang.org/src/runtime/extern.go?h=GOROOT#L213)
```go
   210	// GOROOT returns the root of the Go tree.
   211	// It uses the GOROOT environment variable, if set,
   212	// or else the root used during the Go build.
   213	func GOROOT() string {
   214		s := gogetenv("GOROOT")
   215		if s != "" {
   216			return s
   217		}
   218		return sys.DefaultGoroot
   219	}
```
<!--more-->
## GOPATH
GOPATH是go的工作目录
package build中：
[/src/go/build/build.go:204](https://golang.org/src/go/build/build.go?h=gopath#L204)
```go
   203	// gopath returns the list of Go path directories.
   204	func (ctxt *Context) gopath() []string {
   205		var all []string
   206		for _, p := range ctxt.splitPathList(ctxt.GOPATH) {
   207			if p == "" || p == ctxt.GOROOT {
   208				// Empty paths are uninteresting.
   209				// If the path is the GOROOT, ignore it.
   210				// People sometimes set GOPATH=$GOROOT.
   211				// Do not get confused by this common mistake.
   212				continue
   213			}
   214			if strings.HasPrefix(p, "~") {
   215				// Path segments starting with ~ on Unix are almost always
   216				// users who have incorrectly quoted ~ while setting GOPATH,
   217				// preventing it from expanding to $HOME.
   218				// The situation is made more confusing by the fact that
   219				// bash allows quoted ~ in $PATH (most shells do not).
   220				// Do not get confused by this, and do not try to use the path.
   221				// It does not exist, and printing errors about it confuses
   222				// those users even more, because they think "sure ~ exists!".
   223				// The go command diagnoses this situation and prints a
   224				// useful error.
   225				// On Windows, ~ is used in short names, such as c:\progra~1
   226				// for c:\program files.
   227				continue
   228			}
   229			all = append(all, p)
   230		}
   231		return all
   232	}
```
## GOBIN
GOBIN指向go安装目录中bin的位置
package main中：
[/src/cmd/go/build.go:742](https://golang.org/src/cmd/go/build.go?h=gobin#L742)
```go
   740	var (
   741		goroot    = filepath.Clean(runtime.GOROOT())
   742		gobin     = os.Getenv("GOBIN")
   743		gorootBin = filepath.Join(goroot, "bin")
   744		gorootPkg = filepath.Join(goroot, "pkg")
   745		gorootSrc = filepath.Join(goroot, "src")
   746	)
```
## 扩展：go env
***go env***可查看更多的环境变量。
```bash
$go env
GOARCH="amd64"                  # 编译之后可执行程序的CPU体系架构
GOBIN="/usr/local/go/bin"
GOEXE=""                        # ？
GOHOSTARCH="amd64"              # 主题CPU体系架构
GOHOSTOS="linux"                # 主机操作系统
GOOS="linux"                    # GO程序的运行的操作系统
GOPATH=""
GORACE=""                       # 应该是跟race有关？
GOROOT="/usr/local/go"
GOTOOLDIR="/usr/local/go/pkg/tool/linux_amd64"          # tool路径，比如cgo, compile, etc.
GO15VENDOREXPERIMENT="1"                                # 即将废除的东西
CC="gcc"                                                # C编译器, default是gcc, 也支持clang
GOGCCFLAGS="-fPIC -m64 -pthread -fmessage-length=0"     # 编译参数
CXX="g++"                                               # C++编译器，default是g++，也支持clang++
CGO_ENABLED="1"                                         # 在build过程中控制cgo的用法
```
***GO15VENDOREXPERIMENT***
package main
[/src/cmd/go/pkg.go:273](https://golang.org/src/cmd/go/pkg.go?h=go15VendorExperiment#L273)
```go
   266	// The Go 1.5 vendoring experiment was enabled by setting GO15VENDOREXPERIMENT=1.
   267	// In Go 1.6 this is on by default and is disabled by setting GO15VENDOREXPERIMENT=0.
   268	// In Go 1.7 the variable will stop having any effect.
   269	// The variable is obnoxiously long so that years from now when people find it in
   270	// their profiles and wonder what it does, there is some chance that a web search
   271	// might answer the question.
   272	// There is a copy of this variable in src/go/build/build.go. Delete that one when this one goes away.
   273	var go15VendorExperiment = os.Getenv("GO15VENDOREXPERIMENT") != "0"
```
# 编译运行
hello.go
```go
package main

import "fmt"

func main() {
    fmt.Println("Hello, World");
}
```
Refer to "Go Playground" https://play.golang.org/p/F8Ev-6husG
```bash
go run hello.go
```
***go run***是集编译，链接，运行于一体。运行完之后在当前目录下看不到任何中间文件和最终的可执行文件
```bash
go build hello.go
./hello
```
***go build***是编译，链接。执行完之后可以在当前目录下看见可执行程序hello. 使用*-work*参数可以生成临时文件。
```bash
file /tmp/go-build373605995/command-line-arguments.a
/tmp/go-build373605995/command-line-arguments.a: current ar archive
```
# 工程管理
TBD