
---
title: Golang环境配置及工程管理
date: 2016-03-29 23:55:42
updated: 2016-04-02
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
## Go工程目录树结构
Go管理Project的方法比较特别，没有工程文件，而是**使用目录结构和包名来推导工程结构和构建顺序**，所以Go工程的目录结构和包名就很讲究，必须符合规定。
以一个加减乘除计算器为例。
目录结构如下：  
```bash
.
└── littlecalc
    ├── bin
    │   └── calc
    ├── pkg
    └── src
        ├── calc
        │   └── calc.go
        └── littlemath
            ├── add.go
            ├── div.go
            ├── mul.go
            └── sub.go
```
一般Go工程都会包含bin, pkg, src 3个目录。bin和pkg可以先不创建，go命令可以自动创建（比如 go install）。
`src`目录顾名思义，是源码文件，Go源文件以package方式组织，新建一个package，就是在`src`下新建一个文件夹。

如上面tree所示，`src`下有`calc`和`littlemath` 2个文件夹，即有2个package，一个littlemath package, littlemath下的4支文件中的package名称最好和目录名称保持一致，如果不一致就会比较麻烦，容易让人产生混淆，后面会说明package名称和目录名称不一致的情形。
```go
package littlemath
```
另一个`calc`文件夹，是main package，`calc.go`中有表明是main package.
```go
package main
```
## 构建工程
构建之前需要设置此工程的GOPATH. 每个工程都需要设置GOPATH环境变量，感觉还是有点小麻烦的。编辑`~/.profile`，将littlecalc路径添加到`GOPATH`中，然后`source ~/.profile`.
### 使用`go build`来构建工程
执行如下操作即可在`bin`目录下看到生成的可执行文件calc.
```bash
cd bin
go build -x calc
```
使用`-x`参数查看build中间过程。
```bash
WORK=/tmp/go-build782666460
mkdir -p $WORK/littlemath/_obj/
mkdir -p $WORK/
cd /home/joe/go/littlecalc/src/littlemath
/usr/local/go/pkg/tool/linux_amd64/compile -o $WORK/littlemath.a -trimpath $WORK -p littlemath -complete -buildid 3e05bdb1a540f52eb8c3fea594081c07afc21a07 -D _/home/joe/go/littlecalc/src/littlemath -I $WORK -pack ./add.go ./div.go ./mul.go ./sub.go
mkdir -p $WORK/calc/_obj/
mkdir -p $WORK/calc/_obj/exe/
cd /home/joe/go/littlecalc/src/calc
/usr/local/go/pkg/tool/linux_amd64/compile -o $WORK/calc.a -trimpath $WORK -p main -complete -buildid 87c3fe780b981105ecb696b77b4ab0998e93526b -D _/home/joe/go/littlecalc/src/calc -I $WORK -I /home/joe/go/littlecalc/pkg/linux_amd64 -pack ./calc.go
cd .
/usr/local/go/pkg/tool/linux_amd64/link -o $WORK/calc/_obj/exe/a.out -L $WORK -L /home/joe/go/littlecalc/pkg/linux_amd64 -extld=gcc -buildmode=exe -buildid=87c3fe780b981105ecb696b77b4ab0998e93526b $WORK/calc.a
mv $WORK/calc/_obj/exe/a.out calc
```
先会创建临时目录才存放build中间结果，真正进行编译的是`compile`命令，链接的是`link`命令。最终build的可执行文件从临时目录中移到当前工作目录下。

执行完`go build`的目录结构如下。
```bash
.
├── bin
│   └── calc
├── pkg
└── src
    ├── calc
    │   └── calc.go
    └── littlemath
        ├── add.go
        ├── div.go
        ├── mul.go
        └── sub.go
```
### 使用`go install`来构建工程
```
go install -x calc
```
得到的结果如下。
```bash
WORK=/tmp/go-build478301029
mkdir -p $WORK/littlemath/_obj/
mkdir -p $WORK/
cd /home/joe/go/littlecalc/src/littlemath
/usr/local/go/pkg/tool/linux_amd64/compile -o $WORK/littlemath.a -trimpath $WORK -p littlemath -complete -buildid 3e05bdb1a540f52eb8c3fea594081c07afc21a07 -D _/home/joe/go/littlecalc/src/littlemath -I $WORK -pack ./add.go ./div.go ./mul.go ./sub.go
    mkdir -p /home/joe/go/littlecalc/pkg/linux_amd64/
mv $WORK/littlemath.a /home/joe/go/littlecalc/pkg/linux_amd64/littlemath.a
mkdir -p $WORK/calc/_obj/
mkdir -p $WORK/calc/_obj/exe/
cd /home/joe/go/littlecalc/src/calc
/usr/local/go/pkg/tool/linux_amd64/compile -o $WORK/calc.a -trimpath $WORK -p main -complete -buildid 87c3fe780b981105ecb696b77b4ab0998e93526b -D _/home/joe/go/littlecalc/src/calc -I $WORK -I /home/joe/go/littlecalc/pkg/linux_amd64 -pack ./calc.go
cd .
/usr/local/go/pkg/tool/linux_amd64/link -o $WORK/calc/_obj/exe/a.out -L $WORK -L /home/joe/go/littlecalc/pkg/linux_amd64 -extld=gcc -buildmode=exe -buildid=87c3fe780b981105ecb696b77b4ab0998e93526b $WORK/calc.a
mkdir -p /usr/local/go/bin/
cp $WORK/calc/_obj/exe/a.out /usr/local/go/bin/calc
go install calc: open /usr/local/go/bin/calc: permission denied
```
发现最终生成的结果想要拷贝到`/usr/local/go/bin`下，因为当前时非root用户，没有权限执行此操作。奇怪的是，为什么不是往当前工作目录的`bin`下拷贝呢？原来是`$GOBIN`环境变量导致的。前面将`$GOBIN`设置成了`$GOROOT/bin`, 重新设置环境变量如下。
```bash
export GOROOT=/usr/local/go
export GOBIN=
export GOPATH=$HOME/go/littlecalc
export PATH=$PATH:$GOPATH:$GOROOT/bin
```
然后再执行`go install calc`，可以看到目录树如下。在`bin`下多了一个叫`calc`的最终可执行文件；在pkg下多了一个package文件`littlemath.a`.
```bash
.
├── bin
│   └── calc
├── pkg
│   └── linux_amd64
│       └── littlemath.a
└── src
    ├── calc
    │   └── calc.go
    └── littlemath
        ├── add.go
        ├── div.go
        ├── mul.go
        └── sub.go
```
### `go build`和`go install`的区别
其实从上述`-x`参数得到的结果也可以粗略看出二者的区别。
`go install`会创建`bin`和`pkg`，会将编译出所依赖的package放在pkg中，将最终的可执行文件放在bin中，这个bin的具体位置受到$GOBIN环境变量的影响。

### package名称与目录名称不一致的情形
对上面小工程的目录树结构稍作改变，将`littlemath`改名成`mymath`.
```bash
.
└── src
    ├── calc
    │   └── calc.go
    └── mymath
        ├── add.go
        ├── div.go
        ├── mul.go
        └── sub.go
```
`mymath`中的源文件中package名字仍然保留littlemath.
```go
package littlemath
```
`calc/calc.go`import的package也保留littlemath.
```go
import "littlemath"
```
然后`go install -x calc`会提示找不到littlemath package.
```bash
src/calc/calc.go:5:8: cannot find package "littlemath" in any of:
	/usr/local/go/src/littlemath (from $GOROOT)
	/home/joe/go/littlecalc/src/littlemath (from $GOPATH)
```
但将`calc/calc.go`中import的package改成`mymath`，则可编译成功。
```
import "mymath"
```
go install -x calc
```bash
WORK=/tmp/go-build875817729
mkdir -p $WORK/mymath/_obj/
mkdir -p $WORK/
cd /home/joe/go/littlecalc/src/mymath
/usr/local/go/pkg/tool/linux_amd64/compile -o $WORK/mymath.a -trimpath $WORK -p mymath -complete -buildid 3e05bdb1a540f52eb8c3fea594081c07afc21a07 -D _/home/joe/go/littlecalc/src/mymath -I $WORK -pack ./add.go ./div.go ./mul.go ./sub.go
mkdir -p /home/joe/go/littlecalc/pkg/linux_amd64/
mv $WORK/mymath.a /home/joe/go/littlecalc/pkg/linux_amd64/mymath.a
mkdir -p $WORK/calc/_obj/
mkdir -p $WORK/calc/_obj/exe/
cd /home/joe/go/littlecalc/src/calc
/usr/local/go/pkg/tool/linux_amd64/compile -o $WORK/calc.a -trimpath $WORK -p main -complete -buildid b26a0e0d54c06e74fff3641e2e7c712ad9527d73 -D _/home/joe/go/littlecalc/src/calc -I $WORK -I /home/joe/go/littlecalc/pkg/linux_amd64 -pack ./calc.go
cd .
/usr/local/go/pkg/tool/linux_amd64/link -o $WORK/calc/_obj/exe/a.out -L $WORK -L /home/joe/go/littlecalc/pkg/linux_amd64 -extld=gcc -buildmode=exe -buildid=b26a0e0d54c06e74fff3641e2e7c712ad9527d73 $WORK/calc.a
mkdir -p /home/joe/go/littlecalc/bin/
mv $WORK/calc/_obj/exe/a.out /home/joe/go/littlecalc/bin/calc
```
以上可以发现，编译产生的静态包(package)文件是以目录名来命名的。import时应该是目录名，而在引用包时则需要包名。
虽然将`littlemath`改成了`mymath`，`calc/calc.go`中的`import "littlemath"`改成了`import "mymath"`，
但是`mymath`下的源文件中仍然定义的是`package littlemath`，
`calc/calc.go`中引用包中的函数仍然是类似于`little.Add()`这样的。

## 摆脱每新建一个工程就需要重新设置GOPATH的方法
来自于[Go项目的目录结构](http://blog.studygolang.com/2012/12/go%E9%A1%B9%E7%9B%AE%E7%9A%84%E7%9B%AE%E5%BD%95%E7%BB%93%E6%9E%84/)。
与`src`平行路径新建一支`build.sh`文件，内容如下。
```bash
#!/usr/bin/env bash

pkg=$1

CURDIR=`pwd`
OLDGOPATH="$GOPATH"
export GOPATH="$CURDIR"

gofmt -w src

go install -x $1

export GOPATH="$OLDGOPATH"

echo 'finished'
```
使用方法：`sh build.sh [packages]`，如`sh build.sh calc`.

# Appendix
calc源码: 
https://github.com/magicse7en/go-practice/commit/668cd75c498bfd1c8542eeefb8547c53dd2e7cde
修改包名与目录名不一致的源码: 
https://github.com/magicse7en/go-practice/commit/fce999305dd0c025493a4e3282379291c8d8f69e
[build.sh](https://github.com/magicse7en/go-practice/commit/0b0fdd9f75431d6afb64d86d1398dbd80e86a70b)

# Reference
[Go项目的目录结构](http://blog.studygolang.com/2012/12/go%E9%A1%B9%E7%9B%AE%E7%9A%84%E7%9B%AE%E5%BD%95%E7%BB%93%E6%9E%84/)