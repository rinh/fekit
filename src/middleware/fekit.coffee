compiler = require "../compiler/compiler"
urlrouter = require "urlrouter"
utils = require "../util"
dns = require "dns"
qs = require "querystring"
sysurl = require "url"
syspath = require "path"
sysfs = require "fs"
md5 = require "MD5"
request = require "request"

# ---------------------------

mime_config =
    ".js" : "application/javascript"
    ".css" : "text/css"

charset = ";charset=UTF-8"


PARAM_CACHE = {}

toMD5 = ( str ) ->
    m = md5(str).toString().slice(9).slice(0,16)
    PARAM_CACHE[m] = str
    return m

toPARAM = ( md5str ) ->
    return PARAM_CACHE[md5str]


module.exports = ( options ) ->

    domains_dns = {}

    if options.opposite and options.opposite isnt true
        options.opposite.split(',').forEach ( domainAndAddress ) =>
            map = domainAndAddress.split(':')
            domain = map[0]
            if map[1]
                domains_dns[domain] = {
                    custom : true,
                    address : map[1]
                }
            else
                dns.resolve4 domain, (err, addresses) =>
                    if !err
                        domains_dns[domain] = {
                            custom : false,
                            address : addresses[0]
                        }


    compiler.boost({
        cwd : process.cwd() ,
        directories : [].concat( options.boost || [] )
    })

    ROOT = options.cwd

    protocol = if options.ssl then "https" else "http"
    port = if options.port and options.port != "80" then ":#{options.port}" else ""

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

                _setHead = ( code , remote ) ->
                    res.writeHead code , {
                        'Content-Type': mime_config[ctype] + charset
                        'Server': 'Fekit ' + (if remote then 'Remote ' + remote.address + ' ( ' + ( if remote.custom then 'Custom' else 'DNS') + ' ) ' else 'Local')
                    }


                _setHead 200

                # 判断如果有 cache 则使用，否则进行编译
                cachekey = srcpath + ( if is_deps then "_deps" else "" )
                cache = compiler.booster.get_compiled_cache( cachekey )
                if cache
                    res.end( cache )
                    return

                _render = ( err , txt ) ->
                    if err
                        _setHead 500
                        utils.logger.error err
                        res.end err
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
                            _setHead 404
                            err = "请确认文件 #{url.pathname} 存在于 fekit.config 的 export 中。"
                            utils.logger.error err
                            res.end err

                else
                    if domains_dns[host]
                        request "#{protocol}://#{domains_dns[host].address}#{port}#{url.pathname}", (error, response, body) =>
                            if !error
                                _setHead response.statusCode , domains_dns[host]
                                res.end body
                            else
                                _setHead 500 , domains_dns[host]
                                err = "获取线上资源失败"
                                utils.logger.error err
                                res.end err
                    else
                        _setHead 404
                        err = "文件不存在 #{url.pathname}"
                        utils.logger.error err
                        res.end err
