utils = require "../util"
fs = require "fs"
syspath = require 'path'
connect = require "connect"
http = require "http"
https = require "https"
compiler = require "../compiler/compiler"
ModulePath = require('../compiler/module/path').ModulePath
http_proxy = require "./_server_http_proxy"
host_rule = require "./_server_host_rule"

middleware = require "../middleware/index"

exports.usage = "创建本地服务器, 可以基于其进行本地开发"

exports.set_options = ( optimist ) ->

    optimist.alias 'p' , 'port'
    optimist.describe 'p' , '服务端口号, 一般无法使用 80 时设置, 并且需要自己做端口转发'

    optimist.alias 'c' , 'combine'
    optimist.describe 'c' , '指定所有文件以合并方式进行加载, 启动该参数则请求文件不会将依赖展开'

    optimist.alias 'n' , 'noexport'
    optimist.describe 'n' , '默认情况下，/prd/的请求需要加入export中才可以识别。 指定此选项则可以无视export属性'

    optimist.alias 'b' , 'boost'
    optimist.describe 'b' , '可以对编译结果缓存，以进行加速'

    optimist.alias 's' , 'ssl'
    optimist.describe 's' , '指定ssl证书文件，后缀为.crt'

    optimist.alias 'm' , 'mock'
    optimist.describe 'm' , '指定mock配置文件'

    optimist.alias 'o' , 'proxy'
    optimist.describe 'o' , '是否启用代理服务器, 默认端口为13180'

    optimist.alias 'r' , 'reverse'
    optimist.describe 'r' , '是否启用反向代理服务。'

    optimist.alias 'e' , 'environment'
    optimist.describe 'e' , '设置环境为`local`,`dev`,`beta`或`prd`'

    optimist.alias 'w', 'without-java'
    optimist.describe 'w', '不使用 java 编译 velocity'

setupProxyServer = ( options ) ->

    http_proxy.run( options )


setupServer = ( options ) ->

    app = connect()
            .use( connect.logger( 'tiny' ) )
            .use( connect.query() )
            .use( connect.bodyParser() )
            .use( middleware.mock( options ) )
            .use( middleware.velocity(options) )
            .use( middleware.html(options) )
            .use( middleware.fekit(options) )
            .use( connect.static( options.cwd , { hidden: true, redirect: true, index: 'null' })  )
            .use( connect.directory( options.cwd ) )
    # TODO: <meta name="viewport" content="initial-scale=1,maximum-scale=1,minimum-scale=1,user-scalable=no" />
    # TODO: padding: 80px 20px;



    if options.ssl

        name = utils.path.fname options.ssl
        path = utils.path.dirname options.ssl
        opts =
            key : fs.readFileSync utils.path.join( path , name + ".key" )
            cert : fs.readFileSync utils.path.join( path , name + ".crt" )

        listenPort( https.createServer( opts , app ) , options.port || 443 )

    else

        listenPort( http.createServer( app ) , options.port || 80 )



listenPort = ( server, port ) ->
    # TODO 貌似不能捕获error, 直接抛出异常
    server.on "error", (e) ->
        if e.code is 'EADDRINUSE' then console.log "[ERROR]: 端口 #{port} 已经被占用, 请关闭占用该端口的程序或者使用其它端口."
        if e.code is 'EACCES' then console.log "[ERROR]: 权限不足, 请使用sudo执行."
        process.exit 1

    server.on "listening", (e) ->
        utils.logger.log "fekit server 运行成功, 端口为 #{port}."
        utils.logger.log "按 Ctrl + C 结束进程."

    server.listen( port )

getProjectCompile = () ->
    cwd = process.cwd()
    fs.readdirSync(cwd).forEach((folder) ->
        ModulePath.getCompile(cwd, folder)
    )

exports.run = ( options ) ->

    if options.proxy or options.reverse
        options.rule = host_rule.load( if typeof options.proxy is 'string' then options.proxy else options.reverse )

    #  本地启动之前遍历项目，获取每个项目的自定义编译方法
    getProjectCompile()

    setupServer( options )

    setupProxyServer( options )
