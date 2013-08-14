compiler = require "../compiler/compiler"
utils = require "../util"
connect = require "connect"
rewrite = require "connect-url-rewrite"
urlrouter = require "urlrouter"
dns = require "dns"
http = require "http"
qs = require "querystring"
sysurl = require "url"
syspath = require "path"
sysfs = require "fs"

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


mime_config = 
    ".js" : "application/javascript"
    ".css" : "text/css"

_routeRules = ( options ) ->
    
    list = []
    rs = [].concat( options.route || [] )

    for n in rs
        r = n.split(":")
        list.push( "#{r[0]} #{r[1]}" )
        utils.logger.log "已由 #{r[0]} 转发至 #{r[1]}" 

    return list


_rewriteObsoleteUrl = ( options ) ->
    
    reg = /-(\d{16})/

    unless options.transfer
        return ( req , res , next ) ->
            next()
    
    return ( req , res , next ) ->
        
        return next() unless utils.UrlConvert.PRODUCTION_REGEX.test( req.url )

        return next() if req.query.no_dependencies

        if reg.test( req.url )
            req.url = req.url.replace reg , '@$1'

        next()


setupServer = ( options ) ->

    ROOT = options.cwd

    no_combine = ( path , parents , host , params , doneCallback ) ->
        # 根据是否非依赖模式, 生成不同的结果
        if params["no_dependencies"] is "true"
            compiler.compile( path , {
                dependencies_filepath_list : parents  
                no_dependencies : true 
                root_module_path : params["root"]
            }, doneCallback )

        else

            conf = utils.config.parse path 
            custom_script = conf.root?.development?.custom_render_dependencies
            custom_script_path = utils.path.join( conf.fekit_root_dirname , custom_script )

            host = host.replace(/:\d+/,"")
            port = if options.port and options.port != "80" then ":#{options.port}" else ""

            if custom_script and utils.path.exists custom_script_path 
                ctx = utils.proc.requireScript custom_script_path
                render_func = () ->
                    _path = @path.getFullPath().replace( ROOT , "" ).replace(/\\/g,'/').replace('/src/','/prd/')
                    partial = "http://#{host}#{port}#{_path}?no_dependencies=true&root=#{encodeURIComponent(path)}"                    
                    return ctx.render({
                            type : @path.getContentType()
                            path : @path.getFullPath()
                            url : partial
                            base_path : path 
                        });
            else 
                render_func = () ->
                    _path = @path.getFullPath().replace( ROOT , "" ).replace(/\\/g,'/').replace('/src/','/prd/')
                    partial = "http://#{host}#{port}#{_path}?no_dependencies=true&root=#{encodeURIComponent(path)}"                    
                    switch @path.getContentType()
                        when "javascript"
                            return "document.write('<script src=\"#{partial}\"></script>');"
                        when "css"
                            return "@import url('#{partial}');"
            

            compiler.compile( path , {
                dependencies_filepath_list : parents  
                render_dependencies : render_func
            }, doneCallback)


    combine = ( path , parents , doneCallback ) ->
        compiler.compile( path , {
            dependencies_filepath_list : parents  
        } , doneCallback)


    fekitRouter = urlrouter (app) =>

            # PRD地址
            app.get utils.UrlConvert.PRODUCTION_REGEX , ( req , res , next ) =>

                host = req.headers['host']
                url = sysurl.parse( req.url )
                p = syspath.join( ROOT , url.pathname )
                params = qs.parse( url.query )
                is_deps = params["no_dependencies"] is "true"

                if utils.path.exists(p) and utils.path.is_directory(p)
                    next()
                    return

                urlconvert = new utils.UrlConvert(p,ROOT)
                srcpath = urlconvert.to_src()

                utils.logger.trace("由 PRD #{req.url} 解析至 SRC #{srcpath}")
                
                switch compiler.getContentType(urlconvert.uri) 
                    when "javascript" then ctype = ".js"
                    when "css" then ctype = ".css"
                    else ctype = ""

                res.writeHead( 200, { 'Content-Type': mime_config[ctype] });

                # 判断如果有 cache 则使用，否则进行编译
                cachekey = srcpath + ( if is_deps then "_deps" else "" ) 
                cache = compiler.booster.get_compiled_cache( cachekey )
                if cache
                    res.end( cache )
                    return

                _render = ( err , txt ) ->
                    if err 
                        res.writeHead( 500 )
                        res.end( err )
                    else
                        # 编译后将内容加入 cache
                        compiler.booster.set_compiled_cache( cachekey , txt ) 
                        res.end( txt ) 

                if utils.path.exists( srcpath )
                    config = new utils.config.parse( srcpath )
                    config.findExportFile srcpath , ( path , parents ) =>
                        path = srcpath if options.noexport or is_deps
                        if path 
                            if options.combine 
                                combine path , parents , _render
                            else 
                                no_combine path , parents , host , params , _render
                        else
                            res.end( "请确认文件 #{srcpath} 存在于 fekit.config 的 export 中。" )

                else
                    res.end( "文件不存在 #{srcpath}" )

    app = connect()
            .use( connect.logger( 'tiny' ) ) 
            .use( connect.query()  ) 
            .use( _rewriteObsoleteUrl( options ) )
            .use( rewrite( _routeRules( options ) ) )
            .use( connect.bodyParser() ) 
            .use( fekitRouter )
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

    compiler.boost({
            cwd : process.cwd() , 
            directories : [].concat( options.boost || [] )
        })

    setupServer( options )





