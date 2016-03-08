_             = require 'underscore'
async         = require 'async'
child_process = require 'child_process'
cjson         = require 'cjson'
coffee        = require 'coffee-script'
crypto        = require 'crypto'
find          = require 'find'
fs            = require 'fs'
fse           = require 'fs-extra'
fstream       = require 'fstream'
ignore        = require 'ignore'
mkdirp        = require 'mkdirp'
ncp           = require('ncp').ncp
request       = require 'request'
rimraf        = require 'rimraf'
sty           = require 'sty'
syspath       = require 'path'
sysutil       = require 'util'
tar           = require 'tar'
vm            = require 'vm'
yaml          = require 'js-yaml'
zlib          = require 'zlib'

utilself = module.exports
#----------------------------

exports.array = utilarray =
    clear_empty : ( array ) ->
        n = []
        for i in array
            if i isnt "" or i isnt null
                n.push(i)
        return n

#----------------------------


_closest = ( p , findfilename , filterFunc ) ->
    if p is "/" or ( process.platform is "win32" and p.match(/^[a-zA-Z]:(\\|\/)?$/) )
        return null

    if utilpath.is_directory(p)
        dir = p
    else
        dir = syspath.dirname(p)

    files = fs.readdirSync( dir )
    for file in files
        if file == findfilename
            if filterFunc
                if filterFunc( utilpath.join( dir , file ) )
                    return dir
            else
                return dir

    return _closest( syspath.dirname( dir ) , findfilename , filterFunc )


_closest_dir = ( p , finddirname , filterFunc ) ->
    if p is "/" or ( process.platform is "win32" and p.match(/^[a-zA-Z]:(\\|\/)?$/) )
        return null

    if utilpath.is_directory(p)
        dir = p
    else
        dir = syspath.dirname(p)

    files = fs.readdirSync( dir )
    for file in files
        if file is finddirname and utilpath.is_directory( file )
            if filterFunc
                if filterFunc( file )
                    return dir
            else
                return dir

    return _closest_dir( syspath.dirname( dir ) , finddirname , filterFunc )


_fileExistsWithCaseSync = (filepath) ->
    return false unless fs.existsSync( filepath )
    dir = syspath.dirname(filepath)
    if dir is '/' or dir is '.' or (/^\w:\\$/.test dir)
        return true
    filenames = fs.readdirSync(dir)
    if filenames.indexOf(syspath.basename(filepath)) is -1
        return false
    return _fileExistsWithCaseSync(dir)
casexists = require 'exists-case'


exports.path = utilpath =
    extname : syspath.extname
    dirname : syspath.dirname
    basename : syspath.basename
    resolve : syspath.resolve
    join : () ->
        arr = ( ( if typeof i == 'undefined' then '' else i ) for i in arguments )
        syspath.join.apply( syspath , arr )

    fname : ( path ) ->
        syspath.basename( path ).replace( syspath.extname( path ) , '' )

    get_user_home : () ->
        return process.env[ if (process.platform == 'win32') then 'USERPROFILE' else 'HOME'];

    closest : ( path , findfilename , is_directory , filterFunc ) ->
        if is_directory
            return _closest_dir( path , findfilename , filterFunc )
        else
            return _closest( path , findfilename , filterFunc )

    SEPARATOR : syspath.sep

    is_root: ( path ) ->
        if process.platform is 'win32'
            p = path.replace syspath.sep , ''
            return ///^[a-z]:\s*$///i.test( p )
        else
            return syspath.sep is path

    exists: (path, sensitive) ->
        if sensitive
            return casexists.sync(path)
        else
            return fs.existsSync(path)


    # 分割路径为数组
    # path的输入有可能以 . 或 / 或 \ 分割
    # 如果path最后一部分符合ext_list, 则认为最后一部分为扩展名而不进行分割
    split_path: ( path , ext_list ) ->

        if ~path.indexOf("/")
            parts = path.split( "/" )
        else if ~path.indexOf("\\")
            parts = path.split( "\\" )
        else
            parts = path.split( "." )

        parts = utilarray.clear_empty( parts )
        ext = "." + parts[ parts.length - 1 ]
        if ~ext_list.indexOf( ext )
            # 合并最后2个元素为真正文件名
            parts = parts.slice 0, parts.length - 1
            parts[parts.length - 1] = parts[parts.length - 1] + ext

        return parts

    is_directory: (path) ->
        try
            stats = fs.statSync( path )
            return stats.isDirectory()
        catch err
            throw err
            return false

    is_normalize_dirname: ( path ) ->
        return ( /[\w-\.\s]+/i.test(path) ) and ( path isnt '.' ) and ( path isnt '..' ) and ( path isnt '.svn' ) and ( path isnt '.git' )


    each_directory: ( path , cb , is_recursion ) ->

        if !utilpath.is_directory( path )
            path = syspath.dirname( path )

        list = fs.readdirSync( path )
        for f in list
            p = syspath.join( path , f )
            if !is_recursion
                if utilpath.is_normalize_dirname(f) and !utilpath.is_directory( p )
                    cb( p )
            else
                if utilpath.is_normalize_dirname(f)
                    if !utilpath.is_directory( p )
                        cb( p )
                    else
                        utilpath.each_directory( p , cb , is_recursion )


    existsFiles: ( root , filenames ) ->

        for name in filenames
            p = syspath.join( root , name )
            if utilpath.exists( p )
                return p
        throw "找不到文件列表中的任一文件 #{root} 下的 [#{filenames.join()}]"

    is_absolute_path: ( path ) ->
        return ( process.platform is "win32" and (/^[a-zA-Z]:(\\|\/)?/.test(path)) ) or path.charAt(0) is "/"


#----------------------------


class Reader
    readlines:( filepath ) ->
        return @read(filepath).toString().split( utilfile.NEWLINE )

    read:( filepath ) ->
        if !utilpath.exists( filepath )
            throw "找不到文件 #{filepath}"
        return fs.readFileSync( filepath ).toString().replace( /\r\n/g , '\n' )

    readJSON:( filepath ) ->
        try
            return cjson.load( filepath )
        catch err
            throw "解析 #{filepath} 时出现错误, 请检查该文件, 该文件必须是标准JSON格式"

    readYAML:( filepath ) ->
        try
            return yaml.load( fs.readFileSync( filepath ).toString() )
        catch err
            throw "解析 #{filepath} 时出现错误, 请检查该文件, 该文件必须是标准YAML格式"

    readbymtime:( filepath ) ->
        mtime = null
        cache = null
        return () ->
            stat = fs.statSync( filepath )
            if stat.mtime isnt mtime
                mtime = stat.mtime
                cache = utilfile.io.read( filepath )
            return cache


class Writer
    write:( filepath , content ) ->
        if !utilpath.exists( syspath.dirname( filepath ) )
            mkdirp.sync( syspath.dirname( filepath ) )
        fs.writeFileSync( filepath , content )


exports.file = utilfile = {}
utilfile.reader = Reader
utilfile.writer = Writer
utilfile.io = _.extend( {}, Reader.prototype , Writer.prototype )
utilfile.NEWLINE = '\n'

_watch = ( path , cb ) ->
    if !utilpath.is_directory( path )
        path = syspath.dirname( path )
    watcher = fs.watch path , cb
    watcher.on 'error' , (e) ->
        watcher.close()
        watcher = null

    list = fs.readdirSync( path )
    for f in list
        p = syspath.join( path , f )
        if utilpath.is_normalize_dirname(f) and utilpath.is_directory( p )
            _watch( p , cb )


utilfile.watch = ( dest , cb , crashCB ) ->
    _watch( dest , cb , crashCB )

utilfile.copy = (srcFile, destFile) ->
    BUF_LENGTH = 64*1024
    buff = new Buffer(BUF_LENGTH)
    fdr = fs.openSync(srcFile, 'r')
    fdw = fs.openSync(destFile, 'w')
    bytesRead = 1
    pos = 0
    while bytesRead > 0
        bytesRead = fs.readSync(fdr, buff, 0, BUF_LENGTH, pos)
        fs.writeSync(fdw,buff,0,bytesRead)
        pos += bytesRead
    fs.closeSync(fdr)
    fs.closeSync(fdw)

utilfile.cpr = ( src , dest , cb ) ->
    ncp src , dest , cb

utilfile.cprSync = fse.copySync

utilfile.rmrf = ( dest , cb ) ->
    if cb
        rimraf dest , cb
    else
        rimraf.sync dest

utilfile.rmrfSync = fse.removeSync

utilfile.mkdirp = mkdirp.sync


# 按照给定的后缀名列表找到文件
utilfile.findify = ( path_without_extname , ext_list ) ->
    return path_without_extname if utilpath.exists( path_without_extname ) and !utilpath.is_directory( path_without_extname )
    list = [ "" ].concat( ext_list )
    for ext in list
        path = path_without_extname + ext
        if utilpath.exists( path ) and !utilpath.is_directory( path )
            return path
    return null

#----------------------------

# 默认的配置文件
# baseUri是根据该路径找到最近的一个fekit.config
# 内容为
###
    {
        // 别名配置
        "alias" : {
            "core" : "./src/scripts/core"
        } ,
        // 导出配置 , 默认是以src为根目录
        // 输出至 dev 就变为 scripts/page-a@dev.js
        // 输出至 prd 就变为 scripts/page-a@(md5).js
        "export" : [
            "scripts/page-a.js"
        ] ,
        // sync 使用的配置
        "dev" : {
            "host" : "127.0.0.1"
            "path" : "/home/q/"
        }
    }
###
class FekitConfig

    constructor: ( @baseUri ) ->
        @fekit_config_filename = "fekit.config"
        @fekit_root_dirname = utilpath.closest( @baseUri , @fekit_config_filename )
        @fekit_config_path = syspath.join( @fekit_root_dirname || "" , @fekit_config_filename )
        try
            @root = new utilfile.reader().readJSON( @fekit_config_path )
            if !@getAlias() then @root.alias = {}
        catch err
            if utilpath.exists( @fekit_config_path )
                throw "#{@fekit_config_filename} 解析失败, 请确认该文件格式是否符合正确的JSON格式"
            else
                # 如果没有fekit, 有可能是使用单独文件编译模式, 则使用默认配置
                @root = { "alias" : {} , "export" : [] }

    getAlias: ( name ) ->
        unless name
            return @root.alias or @root.lib
        else
            return @root.alias?[name] or @root.lib?[name]

    getExportFileConfig : ( fullpath ) ->
        n = null
        @each_export_files ( path , parents , opts ) ->
            n = opts if path is fullpath
        return n

    get_export_list : () ->
        return @root["export"] || []

    get_export_info : ( file ) ->
        opts = {}
        if _.isObject( file )
            path = syspath.join( @fekit_root_dirname , "src" , file.path )
            parents = _.map file.parents or [] , ( ppath ) =>
                            syspath.join( @fekit_root_dirname , "src" , ppath )
            opts = file
            opts.partial_path = file.path
        else
            path = syspath.join( @fekit_root_dirname , "src" , file )
            parents = []
            opts.path = path
            opts.partial_path = file

        return {
            path : path
            parents : parents
            opts : opts
        }


    each_export_files : ( cb ) ->
        self = @
        list = @root["export"] || []
        for file in list
            o = self.get_export_info( file )
            if utilpath.exists( o.path )
                cb( o.path , o.parents , o.opts )
            else
                utillogger.error("找不到文件 #{o.path}")

    each_export_files_async : ( cb , doneCallback ) ->
        self = @
        tasks = []
        list = @root["export"] || []
        for file in list
            _tmp = (file) =>
                ( seriesCallback ) =>
                    o = self.get_export_info( file )
                    if utilpath.exists( o.path )
                        cb( o.path , o.parents , o.opts , seriesCallback )
                    else
                        utillogger.error("找不到文件 #{o.path}")
                        utilproc.setImmediate seriesCallback

            tasks.push _tmp(file)

        async.series tasks , ( err ) ->
            if err then throw err
            doneCallback()

    findExportFile : ( filepath , cb ) ->

        list = @root["export"] || []

        hit = false

        for file in list
            if _.isObject( file )
                path = syspath.join( @fekit_root_dirname , "src" , file.path )
                parents = _.map file.parents or [] , ( ppath ) =>
                                syspath.join( @fekit_root_dirname , "src" , ppath )
            else
                path = syspath.join( @fekit_root_dirname , "src" , file )
                parents = []

            if filepath is path
                hit = true
                cb( filepath , parents )

        cb( null , [] ) unless hit

    doScript : ( type , context ) ->
        ctx = context || {}
        ctx.path = utilpath
        ctx.file = utilfile
        ctx.cwd = @baseUri
        ctx.refs_path = @refs_path
        ctx.io =
            reader : new Reader()
            writer : new Writer()

        path = @root?.scripts?[type]
        return unless path
        path = syspath.join( @fekit_root_dirname , path )
        return unless utilpath.exists(path)

        utillogger.log("检测到自动脚本 #{type} , 开始执行.")
        _runCode( path , ctx )
        utillogger.log("自动脚本 #{type} , 执行完毕.")


    doRefs : ( options ) ->
        @refs_path = utilpath.join @baseUri , "refs"
        utilfile.rmrfSync @refs_path
        utilfile.mkdirp @refs_path
        utillogger.log "[refs] start"
        list = @root.refs || {}
        for k , v of list
            fn = @["_doRefs_"+k]
            if fn
                fn.apply @ , ( unless sysutil.isArray(v) then [v] else v )
            else
                utillogger.error "[refs] 构建任务失败, 找不到命令 #{k}"
        @_doRefs_env( options )

    _doRefs_cp : () ->
        for dir in arguments
            from = utilpath.join @baseUri , dir
            to = utilpath.join @refs_path , dir
            utillogger.log "\t >>> #{from} -> #{to}"
            if utilpath.exists from
                utilfile.cprSync from , to
            else
                utillogger.error "\t#{from} 不存在"

    _doRefs_sh : ( script ) ->
        script_path = utilpath.join @baseUri , script
        return unless utilpath.exists script_path

        utillogger.log "\t >>> run script [#{script}]"
        ctx = {}
        ctx.path = utilpath
        ctx.file = utilfile
        ctx.cwd = @baseUri
        ctx.refs_path = @refs_path

        _runCode script_path , ctx

    _doRefs_env : ( options ) ->
        for k , fn of _filters
            reg = new RegExp(k,"i")
            files = find.fileSync( reg , @refs_path )
            for file in files
                @_do_filter( fn.bind( @ ) , file , options , @ )

    getEnvironmentConfig : () ->
        j = utilpath.join
        has = utilpath.exists

        p = j( @fekit_root_dirname , "environment.yaml" )
        return utilfile.io.readYAML(p) if has p

        p = j( @fekit_root_dirname , "environment.json" )
        return utilfile.io.readJSON(p) if has p

        default_json =
            dev: {}
            beta: {}
            prd: {}

        return @root?.environment or default_json


    _do_filter : ( fn, filepath , options , conf ) ->
        source = utilfile.io.read( filepath )
        source = fn( source , options , conf )
        utilfile.io.write( filepath , source )


_filters =

    ".*\\.html$" : ( source , options , conf ) ->
        env = utilself.getCurrentEnvironment( options )
        return utilself.replaceEnvironmentConfig 'text' , source , @getEnvironmentConfig()[ env ]

    ".*\\.htm$" : ( source , options ) ->
        env = utilself.getCurrentEnvironment( options )
        return utilself.replaceEnvironmentConfig 'text' , source , @getEnvironmentConfig()[ env ]

    ".*\\.vm$" : ( source , options ) ->
        env = utilself.getCurrentEnvironment( options )
        return utilself.replaceEnvironmentConfig 'text' , source , @getEnvironmentConfig()[ env ]



_runCode = ( path , ctx ) ->
    Module = require('module')
    mod = new Module( path )
    context = _.extend( {} , global , ctx )
    context.module = mod
    context.__filename = path
    context.__dirname = syspath.dirname( path )
    context.require = ( path ) ->
        return mod.require( path )

    code = new Reader().read( path )
    switch syspath.extname( path )
        when ".js"
            code = code
        when ".coffee"
            code = coffee.compile code
        else
            throw "没有正确的自动化脚本解析器 #{path}"

    m = vm .createScript( code )
    m.runInNewContext( context )


exports.config = utilconfig =
    parse : ( baseUri ) ->
        return new FekitConfig( baseUri )
    createEmptySchema : () ->
        return {
            "compiler" : "modular"
            "name" : ""
            "version" : ""
            "dependencies" : {}
            "alias" : {}
            "export" : []
        }

#---------------------------

class UrlConvert

    # 传入的uri有可能是物理路径, 有可能是url.
    # 有可能是3种url, dev版本/src版本/prd版本
    # dev版本: http://qunarzz.com/home/dev/a@dev.js
    # src版本: http://qunarzz.com/home/src/a.js
    # prd版本: http://qunarzz.com/home/prd/a@(md5值).js
    constructor: ( @uri , @root ) ->
        @REPLACE_STRING = "##REPLACE##"
        if !@root
            baseuri = @uri.replace /[\/\\](dev|prd|src)[\/\\]/ , ($0,$1) =>
                        return "/#{@REPLACE_STRING}/"
        else
            _tmp = ( @uri.replace @root , "" ).replace /[\/\\](dev|prd|src)[\/\\]/ , ($0,$1) =>
                        return "/#{@REPLACE_STRING}/"
            baseuri = syspath.join( @root , _tmp )

        extname = syspath.extname( baseuri )
        filename = syspath.basename( baseuri , extname )
        baseuri = baseuri.replace( filename + extname , "" )
        fnames = filename.split("@")

        @baseuri = baseuri
        @extname = extname
        @replaced_extname = extname
        @filename = filename
        @fnames = fnames

        @has_version = true

    set_extname_type : ( type ) ->
        type = type or ""
        switch type.toLowerCase()
            when "javascript"
                @replaced_extname = ".js"
            when "css"
                @replaced_extname = ".css"
            else
                throw "no extname type"

    set_no_version : () ->
        @has_version = false

    set_has_version : () ->
        @has_version = true

    to_prd: ( md5 ) ->
        prefix = @baseuri.replace( @REPLACE_STRING , "prd" )
        if @has_version
            name = @fnames[0] + "@" + md5 + @replaced_extname
        else
            name = @fnames[0] + @replaced_extname
        return syspath.join( prefix , name )

    to_dev: () ->
        prefix = @baseuri.replace( @REPLACE_STRING , "dev" )
        if @has_version
            name = @fnames[0] + "@dev" + @replaced_extname
        else
            name = @fnames[0] + @replaced_extname
        return syspath.join( prefix , name )

    to_src: () ->
        prefix = @baseuri.replace( @REPLACE_STRING , "src" )
        name = @fnames[0] + @replaced_extname
        return syspath.join( prefix , name )

    # 转变为对应路径的ver文件
    to_ver: () ->
        prefix = @baseuri.replace( @REPLACE_STRING , "ver" )
        name = @fnames[0] + @replaced_extname + ".ver"
        return syspath.join( prefix , name )

UrlConvert.PRODUCTION_REGEX = /\/prd\//

exports.UrlConvert = UrlConvert

#---------------------------


exports.proc = utilproc =

    npmbin : ( cmdname ) ->
        p = utilpath.join( __dirname , '..' , 'node_modules' , '.bin' , cmdname )
        if utilsys.isWindows
            p = p + ".cmd"
        return p

    exec : ( cmd ) ->
        child_process.exec cmd , ( error , stdout , stderr ) =>
            if error then utillogger.error( error )

    setImmediate : ( callback ) ->
        fn = if typeof setImmediate is 'function' then setImmediate else process.nextTick
        fn callback

    spawn : ( cmd , args , cb , options ) ->
        r = child_process.spawn cmd , args || [] , _.extend({
            cwd : process.cwd ,
            env : process.env
        }, options || {} )

        r.stderr.pipe process.stderr, end: false
        r.stdout.pipe process.stdout, end: false
        r.on 'exit' , ( code ) ->
            cb( code )

    requireScript : ( path , ctx = {} ) ->
        Module = require('module')
        mod = new Module( path )
        context = _.extend( {} , global , ctx )
        context.module = mod
        context.__filename = path
        context.__dirname = syspath.dirname( path )
        context.require = ( path ) ->
            return mod.require( path )
        context.exports = context.module.exports

        code = new Reader().read( path )
        switch syspath.extname( path )
            when ".js"
                code = code
            when ".vmjs"
                code = code
            when ".coffee"
                code = coffee.compile code
            else
                throw "没有正确的自动化脚本解析器 #{path}"

        m = vm.createScript( code )
        m.runInNewContext( context )
        return context.module.exports


utilproc.run = utilproc.spawn

#---------------------------

exports.sys = utilsys =
    isWindows : process.platform is 'win32'


#---------------------------

exports.http = utilhttp =

    get : ( url , cb ) ->
        if typeof url is 'object'
            opts = url
        else
            opts =
                url : url
        utillogger.log "fekit #{sty.red 'http'} #{sty.green 'GET'} #{opts.url}"
        request opts , cb

    put : ( url , filepath_or_formdata , formdata , cb ) ->
        utillogger.log "fekit #{sty.red 'http'} #{sty.green 'PUT'} #{url}"

        if arguments.length is 4 and typeof filepath_or_formdata is 'string' and typeof formdata is 'object' and typeof cb is 'function'

            r = request.put url , ( err , res , body ) ->
                cb err , body , res

            form = r.form()

            for k, v of formdata
                form.append k , v

            form.append('file', fs.createReadStream( filepath_or_formdata ))


        else if arguments.length is 3

            cb = formdata

            if typeof filepath_or_formdata is 'string'

                fs.createReadStream( filepath_or_formdata ).pipe(
                    request.put url, ( err , res , body ) ->
                        cb err , body , res
                )

            else if typeof filepath_or_formdata is 'object'

                request.put url , {
                    form : filepath_or_formdata
                } , ( err , res , body ) ->
                    cb err , body , res


    del : ( url , formdata , cb ) ->
        if typeof url is 'object'
            opts = url
        else
            opts =
                url : url

        if typeof formdata == 'function'
            cb = formdata
            formdata = {}

        opts.method = 'DELETE'
        opts.form = formdata

        utillogger.log "fekit #{sty.red 'http'} #{sty.green 'DELETE'} #{url}"
        request opts , cb


#---------------------------


exports.logger = utillogger =
    debug : false ,
    setup : ( options ) ->
        if options && options.debug then utillogger.debug = true
    start : () ->
        @_tick = new Date()
    stop : () ->
        return ( new Date().getTime() - @_tick.getTime() ) + 'ms'
    trace : () ->
        if !utillogger.debug then return
        utillogger.to("[TRACE] " , Array.prototype.join.call( arguments , " " ) )
    error : () ->
        utillogger.to("[ERROR] " , Array.prototype.join.call( arguments , " " ) )
    log : () ->
        utillogger.to("[LOG] " , Array.prototype.join.call( arguments , " " ) )
    to : () ->
        n = Array.prototype.join.call( arguments , "" )
        console.info n


#---------------------------


exports.removeBOM = ( txt ) ->
    if txt.charAt(0) is "\uFEFF" then return txt.substr(1)  else return txt


exports.exit = exit = (exitCode) ->
    if process.stdout._pendingWriteReqs or process.stderr._pendingWriteReqs
        utilproc.setImmediate () ->
            exit(exitCode)
    else
        process.exit(exitCode)


#---------------------------

# tar util

exports.tar =

    pack : ( source , dest , callback ) ->

        fs.stat source, (err, stat) ->

            utilproc.setImmediate ->
                gzip = zlib.createGzip
                    level : 6
                    memLevel : 6

                ig = ignore().addIgnoreFile(syspath.join(source, '.fekitignore'))

                reader = fstream.Reader
                    path : source
                    type : 'Directory'
                    depth : 1
                    filter : (entry) ->
                        if this.basename.match(/^fekit_modules$/) then return false
                        if this.basename.match(/^\..+$/) then return false
                        if ig.filter([syspath.relative(source, this.path)]).length is 0 then return false
                        # Make sure readable directories have execute permission
                        if entry.props.type is "Directory" then entry.props.mode |= (entry.props.mode >>> 2) & 0o0111;
                        return true

                # 依赖 https://github.com/rinh/node-tar 修改过的版本
                props =
                    noProprietary : false
                    fromBase : true

                writer = fstream.Writer
                    path : dest

                reader.pipe(tar.Pack(props)).pipe(gzip).pipe writer.on 'close', ->
                    callback null if typeof callback == 'function'


    unpack : ( tarfile , dest , callback ) ->

        utilproc.setImmediate ->
            fstream.Reader(
                path : tarfile
                type : 'File'
            ).pipe(zlib.createGunzip()).pipe(tar.Extract({path: dest})).on 'end', ->
                callback null if typeof callback == 'function'

#---------------------------

exports.async = utilasync =
    series : ( list , iter , done ) ->
        _list = []
        for item in list
            _tmp = ( item ) ->
                return ( seriesCallback ) ->
                    iter( item , seriesCallback )
            _list.push( _tmp(item) )
        async.series _list , done

#---------------------------

exports._ = _;

_.compactObject = (o) ->
    _.each( o, (v, k) ->
             delete o[k] if v == null )
    return o


exports.extend = () ->
    list = [].concat( _.map arguments , ( i  ) ->
                return _.compactObject( _.extend( {} , i ) ) )
    return _.extend.apply( _ , list )


exports.version = utilfile.io.readJSON( syspath.join( __dirname , "../package.json" ) ).version


exports.getCurrentEnvironment = ( options ) ->
    type = 'prd'

    # 如果命令行中存在 environment 参数，则优先使用该参数
    if options.environment
        type = options.environment
    else if process.env['FEKIT_ENVIRONMENT']
        type = process.env['FEKIT_ENVIRONMENT']

    type = type.toLowerCase()
    switch type
        when 'prd' then return type
        when 'beta' then return type
        when 'dev' then return type
        when 'local' then return type
        else
            utillogger.error "获取当前 environment 配置出错(#{type}) , 值必须为`local`,`dev`,`beta`或`prd`其中之一"


exports.replaceEnvironmentConfig = ( type , source , config ) ->
    config = config or {}
    reg = ///
        /\*\[([^\]]+?)\]\*/
    ///ig
    return source.replace reg , ( $0 , $1 ) ->
            if config[$1] isnt null and typeof config[$1] isnt 'undefined'
                switch type
                    when "js" then return util.inspect( config[$1] )
                    else return config[$1]
            else
                return ""


exports.md5 = (data) ->
    data = new Buffer data
    hash = crypto.createHash 'md5'
    hash.update data
    hash.digest 'hex'
