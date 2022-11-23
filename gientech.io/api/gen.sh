#!/bin/bash

# 下载https://github.com/protocolbuffers/protobuf/releases  安装protoc 放入GOPATH/bin下
go install github.com/golang/protobuf/protoc-gen-go@latest
go get github.com/cncf/udpa@v0.0.1
go get github.com/envoyproxy/envoy@v1.24.0
go get istio.io/api@v0.0.0-20220311210319-8ded0745323c
go get github.com/cncf/xds@v0.0.0-20220314180256-7f1daf1720fc
go install github.com/envoyproxy/protoc-gen-validate@v0.6.2
for name in {defaulter-gen,client-gen,lister-gen,informer-gen,deepcopy-gen}; do go install k8s.io/code-generator/cmd/$name@v0.23.5; done
for name in {cue-gen,kubetype-gen,protoc-gen-golang-deepcopy,protoc-gen-golang-jsonshim}; do go install istio.io/tools/cmd/$name@v0.0.0-20221005164640-5249a540d22c; done
go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.8.0

export PATH=$PATH:$GOPATH/bin

# 自动生成go struct、deepcopy、json、validate文件
cd networking/v1beta1
protoc -I $GOPATH/pkg/mod/github.com/cncf/xds@v0.0.0-20220314180256-7f1daf1720fc -I $GOPATH/pkg/mod/github.com/envoyproxy/envoy@v1.24.0/api -I $GOPATH/pkg/mod/istio.io/api@v0.0.0-20220311210319-8ded0745323c/common-protos -I $GOPATH/pkg/mod/github.com/envoyproxy/protoc-gen-validate@v0.6.2 -I $GOPATH/pkg/mod/github.com/cncf/udpa@v0.0.1 -I ./  --go_out=../../../.. --golang-deepcopy_out=../../../../ --golang-jsonshim_out=../../../../ --validate_out="lang=go:../../../../" *.proto

cd ../..
cd authentication/v1beta1
protoc -I $GOPATH/pkg/mod/github.com/cncf/xds@v0.0.0-20220314180256-7f1daf1720fc -I $GOPATH/pkg/mod/github.com/envoyproxy/envoy@v1.24.0/api -I $GOPATH/pkg/mod/istio.io/api@v0.0.0-20220311210319-8ded0745323c/common-protos -I $GOPATH/pkg/mod/github.com/envoyproxy/protoc-gen-validate@v0.6.2 -I $GOPATH/pkg/mod/github.com/cncf/udpa@v0.0.1 -I ./  --go_out=../../../.. --golang-deepcopy_out=../../../../ --golang-jsonshim_out=../../../../ --validate_out="lang=go:../../../../" *.proto

cd ../..
cd extend/v1beta1
protoc -I $GOPATH/pkg/mod/github.com/cncf/xds@v0.0.0-20220314180256-7f1daf1720fc -I $GOPATH/pkg/mod/github.com/envoyproxy/envoy@v1.24.0/api -I $GOPATH/pkg/mod/istio.io/api@v0.0.0-20220311210319-8ded0745323c/common-protos -I $GOPATH/pkg/mod/github.com/envoyproxy/protoc-gen-validate@v0.6.2 -I $GOPATH/pkg/mod/github.com/cncf/udpa@v0.0.1 -I ./  --go_out=../../../.. --golang-deepcopy_out=../../../../ --golang-jsonshim_out=../../../../ --validate_out="lang=go:../../../../" *.proto

cd ../..
cd canary/v1beta1
protoc -I $GOPATH/pkg/mod/github.com/cncf/xds@v0.0.0-20220314180256-7f1daf1720fc -I $GOPATH/pkg/mod/github.com/envoyproxy/envoy@v1.24.0/api -I $GOPATH/pkg/mod/istio.io/api@v0.0.0-20220311210319-8ded0745323c/common-protos -I $GOPATH/pkg/mod/github.com/envoyproxy/protoc-gen-validate@v0.6.2 -I $GOPATH/pkg/mod/github.com/cncf/udpa@v0.0.1 -I ./  --go_out=../../../.. --golang-deepcopy_out=../../../../ --golang-jsonshim_out=../../../../ --validate_out="lang=go:../../../../" *.proto

# 生成crd
cd ../..
cue-gen -f=cue.yaml -paths=$GOPATH/pkg/mod/github.com/cncf/xds@v0.0.0-20220520190051-1e77728a1eaa,$GOPATH/pkg/mod/github.com/envoyproxy/envoy@v1.24.0/api,$GOPATH/pkg/mod/istio.io/api@v0.0.0-20220311210319-8ded0745323c/common-protos,$GOPATH/pkg/mod/github.com/envoyproxy/protoc-gen-validate@v0.6.2,$GOPATH/pkg/mod/github.com/cncf/udpa@v0.0.1 -crd=true
go mod tidy -compat=1.17

cd ../..
# 没有看kubetype-gen逻辑 GOOT下还得有一份代码
rm -rf $GOROOT/src/gientech.io
cp -r gientech.io $GOROOT/src/
kubetype-gen -v 10 --log_dir=log --logtostderr -i gientech.io/api/networking/v1beta1,gientech.io/api/authentication/v1beta1,gientech.io/api/extend/v1beta1,gientech.io/api/canary/v1beta1 -p gientech.io/client-go/pkg/apis -h gientech.io/boilerplate.go.txt
rm -rf $GOROOT/src/gientech.io

cd gientech.io/client-go
test -s go.mod || go mod init gientech.io/client-go

echo "module gientech.io/client-go

go 1.17

require (
	gientech.io/api v0.0.1
	istio.io/api v0.0.0-20220311210319-8ded0745323c
	k8s.io/apimachinery v0.23.5
)

replace gientech.io/api v0.0.1 => ../api
" > go.mod

go mod tidy -compat=1.17
controller-gen object:headerFile="../boilerplate.go.txt" paths="./..."
go mod tidy -compat=1.17

cd ../..

# 没有看逻辑 GOOT下还得有一份代码
cp -r gientech.io $GOROOT/src/
client-gen --clientset-name versioned --input-base "" --input gientech.io/client-go/pkg/apis/networking/v1beta1,gientech.io/client-go/pkg/apis/authentication/v1beta1,gientech.io/client-go/pkg/apis/extend/v1beta1,gientech.io/client-go/pkg/apis/canary/v1beta1 --output-package gientech.io/client-go/pkg/clientset -h gientech.io/boilerplate.go.txt
lister-gen --input-dirs gientech.io/client-go/pkg/apis/networking/v1beta1,gientech.io/client-go/pkg/apis/authentication/v1beta1,gientech.io/client-go/pkg/apis/extend/v1beta1,gientech.io/client-go/pkg/apis/canary/v1beta1 --output-package gientech.io/client-go/pkg/listers -h gientech.io/boilerplate.go.txt
informer-gen --input-dirs gientech.io/client-go/pkg/apis/networking/v1beta1,gientech.io/client-go/pkg/apis/authentication/v1beta1,gientech.io/client-go/pkg/apis/extend/v1beta1,gientech.io/client-go/pkg/apis/canary/v1beta1 --versioned-clientset-package gientech.io/client-go/pkg/clientset/versioned --listers-package gientech.io/client-go/pkg/listers --output-package gientech.io/client-go/pkg/informers -h gientech.io/boilerplate.go.txt
rm -rf $GOROOT/src/gientech.io

# gientech.io/client-go  go.mod 中缺少k8s.io/client-go，直接go mod tidy 会导致同k8s.io/apimachinery版本不一致冲突
cd gientech.io/client-go
echo "module gientech.io/client-go

go 1.17

require (
	gientech.io/api v0.0.1
	istio.io/api v0.0.0-20220311210319-8ded0745323c
	k8s.io/apimachinery v0.23.5
	k8s.io/client-go v0.23.5
)

replace gientech.io/api v0.0.1 => ../api
" > go.mod
go mod tidy -compat=1.17