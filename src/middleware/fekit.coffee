compiler       = require "../compiler/compiler"
dns            = require "dns"
helper_reverse = require "./helper_reverse"
qs             = require "querystring"
sysfs          = require "fs"
syspath        = require "path"
sysurl         = require "url"
urlrouter      = require "urlrouter"
utils          = require "../util"

# ---------------------------

mime_config =
    ".js" : "application/javascript"
    ".css" : "text/css"

charset = ";charset=UTF-8"

PARAM_CACHE = {}

toMD5 = ( str ) ->
    m = utils.md5(str).toString().slice(9).slice(0,16)
    PARAM_CACHE[m] = str
    return m

toPARAM = ( md5str ) ->
    return PARAM_CACHE[md5str]


writeHeader = ( res, code, type ) ->
    res.writeHead code, {
        'Content-Type': mime_config[type] + charset,
        'Server': 'Fekit - Local File'
    }

module.exports = ( options ) ->

    ROOT = options.cwd

    protocol = if options.ssl then "https" else "http"

    port = if options.port and options.port != "80" then ":#{options.port}" else ""

    if options.boost
        utils.logger.log "已启动加速模式"

    helper_reverse.load options

    no_combine = ( path , parents , host , params , doneCallback ) ->
        # 根据是否非依赖模式, 生成不同的结果
        if params["no_dependencies"] is "true"

            compiler.compile( path , {
                dependencies_filepath_list : parents
                no_dependencies : true
                root_module_path : params["root"]
                environment : 'local'
            }, doneCallback )

        else

            conf = utils.config.parse path
            custom_script = conf.root?.development?.custom_render_dependencies
            custom_script_path = utils.path.join( conf.fekit_root_dirname , custom_script )

            host = host.replace(/:\d+/,"")

            if custom_script and utils.path.exists custom_script_path
                ctx = utils.proc.requireScript custom_script_path
                render_func = () ->
                    _path = @path.getFullPath().replace( ROOT , "" ).replace(/\\/g,'/').replace('/src/','/prd/')

                    partial = "#{protocol}://#{host}#{port}#{_path}?" + toMD5("no_dependencies=true&root=#{encodeURIComponent(path)}")
                    return ctx.render({
                            type : @path.getContentType()
                            path : @path.getFullPath()
                            url : partial
                            base_path : path
                            base_params : params
                        });
            else
                render_func = () ->
                    _path = @path.getFullPath().replace( ROOT , "" ).replace(/\\/g,'/').replace('/src/','/prd/')
                    partial = "#{protocol}://#{host}#{port}#{_path}?" + toMD5("no_dependencies=true&root=#{encodeURIComponent(path)}")
                    switch @path.getContentType()
                        when "javascript"
                            return "document.write('<script src=\"#{partial}\"></script>');"
                        when "css"
                            return "@import url('#{partial}');"


            compiler.compile( path , {
                dependencies_filepath_list : parents
                render_dependencies : render_func
                environment : 'local'
            }, doneCallback)


    combine = ( path , parents , doneCallback ) ->
        compiler.compile( path , {
            dependencies_filepath_list : parents
            environment : 'local'
        } , doneCallback)


    fekitRouter = urlrouter (app) =>

            # PRD地址
            app.get utils.UrlConvert.PRODUCTION_REGEX , ( req , res , next ) =>

                host = req.headers['host']
                url = sysurl.parse( req.url )
                p = syspath.join( ROOT , url.pathname )
                params = qs.parse( toPARAM(url.query) or url.query )
                is_deps = params["no_dependencies"] is "true"

                if utils.path.exists(p) and utils.path.is_directory(p)
                    next()
                    return

                urlconvert = new utils.UrlConvert(p,ROOT)
                srcpath = urlconvert.to_src()
                srcpath = compiler.path.findFileWithoutExtname( srcpath )

                utils.logger.trace("由 PRD #{req.url} 解析至 SRC #{srcpath}")

                switch compiler.getContentType(urlconvert.uri)
                    when "javascript" then ctype = ".js"
                    when "css" then ctype = ".css"
                    else ctype = ""

                # 判断如果有 cache 则使用，否则进行编译
                if options.boost
                    cache = compiler.booster.get_compiled_cache( srcpath , is_deps )
                    if cache
                        writeHeader res , 200 , ctype
                        res.end cache
                        return

                _render = ( err , txt , module ) ->
                    if err
                        writeHeader res , 500 , ctype
                        utils.logger.error err
                        res.end err
                    else
                        # 编译后将内容加入 cache
                        writeHeader res , 200 , ctype
                        compiler.booster.watch module
                        compiler.booster.set_compiled_cache( srcpath , txt , is_deps )
                        res.end txt

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
                            writeHeader res , 404 , ctype
                            res.end "请确认文件 #{url.pathname} 存在于 fekit.config 的 export 中。"

                else
                    if options.reverse and helper_reverse.exists( host )
                        helper_reverse.request req.headers , protocol , host , port , url.pathname , res, ctype
                    else
                        writeHeader res , 404 , ctype
                        res.end "文件不存在 #{url.pathname}。"
