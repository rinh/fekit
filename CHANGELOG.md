# 0.2.144
* 将node-sass-china的依赖固定到3.4.2版本以编译yo

# 0.2.143
* 增加支持项目自定义编译方案，使用方法见README

# 0.2.142
* 增加jsx预编译

# 0.2.141
* 默认不使用 exists-case

# 0.2.140
* 用 exists-case 模块替换 fileExistsWithCaseSync, 解决耗时问题

# 0.2.139
* 加了一个处理html的中间件，可以把html文件中的环境变量替换掉

# 0.2.138
* 给doScript 运行的脚本增加几个全局变量，file、cwd、refs_path, https://github.com/rinh/fekit/pull/110

# 0.2.137
* rollback: 回滚模块 guid 为 md5(source)

# 0.2.136
* modified: 使用 node-sass-china 替代之前方案

# 0.2.134
* modified: 修改模块 guid 为 md5(source + path)

# 0.2.133
* fixed: 增加 autoprefixer 出错处理方式

# 0.2.132
* added: 新增 autoprefixer 支持

# 0.2.131
* fixed: velocity.java 多 root 加载问题

# 0.2.130
* updated: 升级 node-sass 3.3.2

# 0.2.129
* fixed: windows 平台 velocity 加载路径问题

# 0.2.128
* fixed: server --proxy 的 bug

# 0.2.127
* added: 添加 json 模块引用支持

# 0.2.126
* upgrade: 升级 node-tar

# 0.2.125
* removed: 去除对 .ng、.ngc、.styl 文件编译支持
* added: 增加新 velocity 模块环境变量支持

# 0.2.124
* fixed: 修复 helper\_reverse 一枚 bug
* 替换 submodule git 协议为 https
* 去除 jar 包，引入 velocity.java 模块
* server 指令增加 --without-java 参数

# 0.2.123
* 改进了一下 node-sass 的安装

# 0.2.122
* fixed: 防止 mac 弹提示

# 0.2.121
* fixed: test 命令错误
* added: java 实现 velocity 中间件，http://gitlab.corp.qunar.com/fed/velocity-for-fekit/

# 0.2.120
* fixed: plugin 命令在 windows 上无法安装的问题

# 0.2.119
* fixed: 修改 sass 编译模块上一版本的疏忽
* fixed: 编译报错时，result[0] 取不到问题
* removed: 去除不可用的 liveload 支持

# 0.2.118
* fixed: window下import css文件路径编译错误的问题

# 0.2.117
* 去除第三方 MD5 模块，转用内置模块 crypto

# 0.2.116
* update sass 支持更多形式的import;修复css中require失败的问题;支持打印错误信息的上下文
* 对 compute-cluster 做最大进程数限制

# 0.2.115
* fixed: sass import 私有文件的问题

# 0.2.114
* fixed: npmrc 设置了 prefix 的安装问题

# 0.2.113
* 解决 node-sass 安装困难的问题

# 0.2.112
* fixed: Scss Import Once 问题修复
* fixed: versions.mapping 扩展名不一致的问题

# 0.2.111
* 优化 completion 命令

# 0.2.110
* removed: 删除误添加进来的 haha.txt

# 0.2.109
* add: 增加 fekit completion 命令

# 0.2.108
* upgrade: node-sass 升级及去重优化
* fixed: ignore 修复

# 0.2.107
* fixed: 回滚 uglify-js 到 1.3.x

# 0.2.106
* fixed: 修复 versions.mapping 版本号问题
* add: 增加 .fekitignore 功能

# 0.2.105
* update: 升级 node-sass 到 3.0.0 稳定版

# 0.2.103
* fixed: 修复 velocity 引用变量没有成功的问题

# 0.2.102
* fixed: 修复 velocity 解析时的错误

# 0.2.101
* fixed: 升级 http-proxy 以修复其使用 eventemitter3 的错误

# 0.2.100
* fixed: 修正发布点

# 0.2.99
* add: 增加环境变量的设置

# 0.2.98
* add: 增加 server 的 boost 选项，默认情况不开启

# 0.2.97
* fixed: 修正 utils.path.is_absolute_path 对 windows 的判断错误

# 0.2.96
* add: 优化 pack 及 min 的编译速度
* fixed: 修改了 versions.mapping 文件名一致会被覆盖的问题，将文件路径恢复

# 0.2.95
* add: server 增加缓存机制

# 0.2.94
* add: server 增加缓存机制

# 0.2.93
* add: 更新 node-sass 版本为 2.0.1
* add: 更新 uglify 2.0

# 0.2.92
* none

# 0.2.91
* fix: fileExistsWithCaseSync 在 Windows 平台错误

# 0.2.90
* fix: mock 支持 post

# 0.2.89
* add: vm 支持 include
* add: vmjs 中可以使用 request , response
* fix: 开发时 require 区分大小写
* fix: fekit test 命令找不到测试用例时的提示不够友好且无法找到命令 Fixes #57
* add: fekit vm 添加 layout Fixes #64
* fix: 编译非标准js/css文件生成的version.mapping扩展名修正为js/css Fixes #72
* fix: fekit 预编译 sass 文件模块去重 Fixes #54
* add: stylus支持 from netwjx

# 0.2.88
* update: sass升级到`1.2.3`支持`BEM`等特性

# 0.2.87
* fix: ip代理

# 0.2.86
* add: server 增加代理模式

# 0.2.85
* add: sync 添加远程通用脚本执行
* add: sync 添加初始化功能

# 0.2.84
* add: pack 时添加 ver 处理
* add: 配置中加入 refs， refs用于js/css之外的文件发布目录内容，在 pack 与 min 后执行

# 0.2.83
* fix: 修复模板文件名包含多 '.' 问题

# 0.2.82
* fix: 修复在 CMD 中 rsync 运行出错的问题，并增加提示
* add: 为 .string, .handlebars 添加模块化支持

# 0.2.81
* fix: 在上一版本解决问题中，出现其他问题，做相应恢复

# 0.2.80
* fix: require 文件名中含有多个 '.' 时的 bug
* fix: mustache 预编译，在非模块编译时的 bug
* add: 添加部分文档

# 0.2.79
* add: export 指令
* add: mustache 预编译添加模块导出

# 0.2.78
* add: mock jsonp 回调名称的配置
* add: mock raw 处理方式的 jsonp 功能
* add: mock [操作文档](https://github.com/rinh/fekit/tree/master/docs/mock)

# 0.2.77
* fix: mock 的端口问题

# 0.2.76
* fix: mock 时使用正则的多路径的问题

# 0.2.75
* fix: server environment 的 bug 问题

# 0.2.74
* fix: server environment 的 bug 问题

# 0.2.73
* fix: server 的 bug 问题

# 0.2.72
* fix: tag 添加脚本
* add: 添加环境变量功能

# 0.2.71
* modify: livereload 改为非默认开启，使用 server -l 开启
* add: mock jsonp 支持
* fix: mock 的配置文件路径修正
* fix: 同名且不同后缀名引用问题
* fix: 修正强制分布为 simg1

# 0.2.70
* add: 添加 sass 和 scss 扩展名的支持
* add: 删除 UTF-8 的 BOM 头
* add: 添加 fekit server 对于 mock 的支持
* modify: 强制分布各 css 中的图片到不同域
* add: 添加 livereload 支持

# 0.2.64
* modify: 修改 https 的 document.write

# 0.2.63
* add: 添加对 https 的支持

# 0.2.62
* modify: 修改 vmjs 不需要重启服务器

# 0.2.61
* modify: 对 velocity(vm) 支持 vmjs(语法同js) , json(语法同json) 的扩展。

# 0.2.60
* modify: 对 velocity(vm) 的 parse 扩展支持。默认使用相对路径，可由配置变为绝对路径
* fix: parent module的正确解析
* fix: server -r 引用错误

# 0.2.59
* add: 增加sass的支持 (from zhiyan)
* add: 隐藏 server 的长参数
* add: 支持handlebars编译类型 (from zhiyan)
* add: fekit server 增加 velocity(vm) 语法支持 (from Robinlim)
* modify: 修改 fekit server 实时编译文件 url 过长的问题

# 0.2.58
* fix: 修复某些项目的编译问题

# 0.2.57
* add: 针对循环调用的处理变为跳出操作

# 0.2.56
* fix: 修正 windows 下编译失败的问题

# 0.2.55
* fix: 修正 windows 下 util.is_root

# 0.2.54
* change: 修改 string 文件的编译结果为支持 module 模式

# 0.2.53
* add: fekit plugin 命令，可以添加或删除插件
* add: fekit server 500 时，需要在控制台输出错误
* fix: 修正 fekit server 返回 500 时的 charset 为 UTF-8
* fix: 编译时，require 会优先寻找匹配的组件
* add: init时，增加html,images目录
* add: 添加 string 文件类型的支持

# 0.2.52
* change: 配置为 no version 的文件，在 min 后，将生成空内容的 ver 文件，及 version.mapping 对应项目也为空字符串

# 0.2.51
* fix: watchr@2.4.3 以上版本，安装后出现问题，故锁定版本在2.4.3

# 0.2.50
* change: fekit sync 添加 -d 功能，允许删除服务器中的文件
* change: 首引用文件（export中定义）可为非js,css扩展名。 https://github.com/rinh/fekit/issues/30
* fix: 组件版本号递归问题 https://github.com/rinh/fekit/issues/31
* change: 删除源上的组件时加入版本号的输入验证，禁止直接删除组件的全部版本
* fix: fekit min 单文件模式下报错输出不正确的问题
* change: less 解析使用 [qless.js](https://github.com/rinh/qless.js)

# 0.2.45
* change: 不再使用 vendor 中提供的 tar

# 0.2.44 #
* change: 修正安装问题

# 0.2.43 #
* change: 修正安装问题

# 0.2.42 #
* change: 修正安装问题

# 0.2.41 #
* change: 修正安装问题

# 0.2.40 #
* add: 添加 server 的 custom_render_dependencies 其中 context 的 base_params
* add: 添加 angular.js 支持，可以使用 ng(javascript) 或 ngc(coffee) 进行开发
* change: domain_mapping 的作用域修改为 全局 及 关联文件

# 0.2.39 #
* add: 添加 css/less 多域名图片替换方案

# 0.2.38 #
* add: 增加sync的non exec功能
* add: mustache 开启 useArrayBuffer 模式
* add: sync 以 spawn 方式调用
* add: 增加 fekit upgrade 功能
* add: 增加 fekit.config 中的配置 development 节点，可以对开发中的渲染内容进行修改

# 0.2.33 #
* add: 增加 fekit config -s 和 -d 功能
* add: 增加源的用户管理，fekit login 与 fekit logout
* add: 增加源的发布管理，必须以组件作者身份才能进行 publish 与 unpublish

# 0.2.32  #
* fix: fekit 支持 less @import 语法

# 0.2.31 #
* change: fekit publish 时过滤所有隐藏文件
* change: 可以通过 fekit.config 文件的 min 节点进行自定义编译参数设定
* add: fekit init 增加 README.md 的自动创建
* fix: fekit server 时支持使用软链

# 0.2.30 #
* change: fekit init 默认 config 文件修改为 modular 模式
* change: fekit install xxx -c，强制使用配置文件中的版本范围。 如果没有配置文件或配置文件中没有配置，则不安装

# 0.2.29 #
* change: fekit min 之前，删除 ver & prd 后再生成

# 0.2.28 #
* fix: require了不存在的文件时，编译出错应输出 [ERROR]

# 0.2.27  #
* fix: fekit server 全局 cache 问题

# 0.2.26 #
* change: fekit publish 时，过滤.git , .svn
* fix: fekit server 刷新 cache 时消除 deps 的内容
* change: fekit min 支持只生成 ver 或 mapping

# 0.2.25 #
* change: fekit server -r aaa:bbb，进行路由功能时，不自动添加前后斜线 https://github.com/rinh/fekit/issues/25
* change: 修改加速方案，改为缓存编译内容

# 0.2.24  #
* change: 编译js时，判断require后如果没有任何字符，则在后面追加分号

# 0.2.23 #
* change: fekit server -b ./project，server功能默认不开启全目录加速，需要时请指定特定目录进行加速
* change: fekit server -r aa:bb -r cc:dd，server的路由功能可以使用多个
* fix: fekit install，在 windows 下会将目录权限丢失

# 0.2.22 #
* fix: fekit min 当指定压缩某非fekit项目文件时失败
* fix: module 被编译后不追加 ;

# 0.2.21  #
* change: fekit convert --qzz，将转换后的require路径设置为以 ./ 开始
* add: fekit min 后，会在 ver 文件中生成 versions.mapping 文件，该文件包括本次编辑产生的所有版本号文件及版本号的键值对

# 0.2.20 #
* fix: compiler 修改 modular 模式为 basename

# 0.2.19 #
* fix: fekit server , contnet-type bug

# 0.2.18 #
* add: 增加单元测试方案(mocha) fekit test
* fix: 解决 server 中不可识别后缀名的 content-type。 https://github.com/rinh/fekit/pull/20
* change: fekit min 的路径可指定，使用 -o
* change: fekit min 编译出现错误时的提示信息更友好
* add: fkeit min -n 可以指定不进行压缩处理
* add: fekit sync 时可以指定 shell 执行
* fix: fekit server 当遇到引错路径的情况会导致 server crash

# 0.2.17 #
* fix: 处理 require 的匹配方式 , 识别 // 及 Ext.require 这样的代码

# 0.2.16  #
* add: 兼容 0.1.x 的源码格式

# 0.2.15  #
* fix: server transfer 没有正确处理非 -t 的情况
* add: 导出 minCode 功能

# 0.2.14 #
* add: server 添加了 transfer 功能
* add: min 添加了编译使用的毫秒数
* add: min 添加了使用版本

# 0.2.13  #
* change: 组件(定义为compiler:component)的编译模式强制使用 modular

# 0.2.12 #
* fix: convert 时，export 中的路径永远使用 /
* fix: 删除文件夹会导致 watch 中断

# 0.2.11 #
* fix: convert 中使用的 findit 在 windows 下不能正常工作  https://github.com/substack/node-findit/issues/5
* add: 增加 server 的 boost 功能 , 使用 watch file 方式动态缓存 file checksum

# 0.2.10 #
* fix: 使用 node 0.10.x 中的 setImmediate ，并兼容老版本 node 的 process.nextTick
* 优化 module io 读入次数
* fix: min -f 单独压缩文件的问题
* fix: 当引用路径为 require('../xxx') 或 require('xxx') 时，加载错误的问题

# 0.2.9 #
* fix: 修正 cake bump 的方式， 将exec改为spawn

# 0.2.8  #

* add: 增加 cake bump
* add: 增加 unpublish 前的警告

# 0.2.7  #

* add: 使用changelog记录变更

# 0.2.6 #

* fix: 由async引起的 RangeError: Maximum call stack size exceeded

# 0.2.0 #

* 完成组件化工作

# 0.1.29 #

# 0.0.1 #

* initial
