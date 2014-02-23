compiler = require "../compiler/compiler"
urlrouter = require "urlrouter"
utils = require "../util"
dns = require "dns"
qs = require "querystring"
sysurl = require "url"
syspath = require "path"
sysfs = require "fs"
md5 = require "MD5"

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

    compiler.boost({
        cwd : process.cwd() , 
        directories : [].concat( options.boost || [] )
    })

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
                    
                    partial = "http://#{host}#{port}#{_path}?" + toMD5("no_dependencies=true&root=#{encodeURIComponent(path)}")
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
                    partial = "http://#{host}#{port}#{_path}?" + toMD5("no_dependencies=true&root=#{encodeURIComponent(path)}")
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

                res.writeHead 200, { 'Content-Type': mime_config[ctype] + charset }

                # 判断如果有 cache 则使用，否则进行编译
                cachekey = srcpath + ( if is_deps then "_deps" else "" ) 
                cache = compiler.booster.get_compiled_cache( cachekey )
                if cache
                    res.end( cache )
                    return

                _render = ( err , txt ) ->
                    if err 
                        res.writeHead 500, { 'Content-Type': mime_config[ctype] + charset }
                        utils.logger.error err
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


