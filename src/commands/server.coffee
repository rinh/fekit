utils = require "../util"
connect = require "connect"
http = require "http"
middleware = require "../middleware/index"

exports.usage = "创建本地服务器, 可以基于其进行本地开发"

exports.set_options = ( optimist ) ->

    optimist.alias 'p' , 'port'
    optimist.describe 'p' , '服务端口号, 一般无法使用 80 时设置, 并且需要自己做端口转发'

    optimist.alias 'r' , 'route'
    optimist.describe 'r' , '路由,将指定路径路由到其它地址, 物理地址需要均在当前执行目录下。格式为 -r 原路径名:路由后的物理目录名'

    optimist.alias 'c' , 'combine'
    optimist.describe 'c' , '指定所有文件以合并方式进行加载, 启动该参数则请求文件不会将依赖展开'

    optimist.alias 'n' , 'noexport'
    optimist.describe 'n' , '默认情况下，/prd/的请求需要加入export中才可以识别。 指定此选项则可以无视export属性'

    optimist.alias 't' , 'transfer'
    optimist.describe 't' , '当指定该选项后，会识别以前的 qzz 项目 url'

    optimist.alias 'b' , 'boost'
    optimist.describe 'b' , '可以指定目录进行编译加速。格式为 -b 目录名'    



setupServer = ( options ) ->

    app = connect()
            .use( connect.logger( 'tiny' ) ) 
            .use( connect.query() ) 
            .use( middleware.rewriteObsoleteUrl( options ) )
            .use( middleware.rewriteRule( options ) ) 
            .use( connect.bodyParser() ) 
            .use( middleware.velocity(options) )
            .use( middleware.fekit(options) )
            .use( connect.static( options.cwd , { hidden: true, redirect: true })  ) 
            .use( connect.directory( options.cwd ) ) 

    listenPort( http.createServer(app) , options.port || 80 )



listenPort = ( server, port ) ->
    # TODO 貌似不能捕获error, 直接抛出异常
    server.on "error", (e) ->
        if e.code is 'EADDRINUSE' then console.log "[ERROR]: 端口 #{port} 已经被占用, 请关闭占用该端口的程序或者使用其它端口."
        if e.code is 'EACCES' then console.log "[ERROR]: 权限不足, 请使用sudo执行."
        process.exit 1

    server.on "listening", (e) ->
        console.log "[LOG]: fekit server 运行成功, 端口为 #{port}."
        console.log "[LOG]: 按 Ctrl + C 结束进程." 

    server.listen( port )



exports.run = ( options ) ->

    setupServer( options )





