async = require 'async'
child_process = require 'child_process'
syspath = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'
yaml = require 'yaml'
cjson = require 'cjson'
_ = require 'underscore'
vm = require 'vm'
coffee = require 'coffee-script'


#----------------------------

exports.array = utilarray =
    clear_empty : ( array ) ->
        n = []
        for i in array
            if i isnt "" or i isnt null 
                n.push(i)
        return n

#----------------------------

exports.path = utilpath =
    join : syspath.join 

    closest : ( path , findfilename ) ->
        return _closest( path , findfilename )

    SEPARATOR : syspath.join('a','a').replace(/a/g,'')

    exists: ( path ) ->
        if fs.existsSync
            return fs.existsSync( path )
        # 为了0.6版以前的node兼容
        if syspath.existsSync
            return syspath.existsSync( path )


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
            parts = parts.slice( 0 , parts.length - 1 )
            parts[ parts.length - 1 ] = parts[ parts.length - 1 ] + ext
        
        return parts

    is_directory: (path) ->
        try
            stats = fs.lstatSync( path )
            return stats.isDirectory()
        catch err 
            throw err
            return false

    each_directory: ( path , cb ) ->

        if !utilpath.is_directory( path )
            path = syspath.dirname( path )

        list = fs.readdirSync( path )
        for f in list 
            p = syspath.join( path , f )
            if f isnt "." and f isnt ".." and !utilpath.is_directory( p )
                cb( p )

    existsFiles: ( root , filenames ) ->

        for name in filenames
            p = syspath.join( root , name )
            if utilpath.exists( p ) 
                return p
        throw "找不到文件列表中的任一文件 #{root} 下的 [#{filenames.join()}]"

    is_absolute_path: ( path ) ->
        return ( process.platform is "win32" and p.match(/^[a-zA-Z]:(\\|\/)?$/) ) or path.charAt(0) is "/" 


_closest = ( p , findfilename ) ->
    if p is "/" or ( process.platform is "win32" and p.match(/^[a-zA-Z]:(\\|\/)?$/) )
        return null

    if utilpath.is_directory(p)
        dir = p
    else
        dir = syspath.dirname(p)

    files = fs.readdirSync( dir )
    for file in files
        if file == findfilename
            return dir

    return _closest( syspath.dirname( dir ) , findfilename )

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
        # 必须将冒号后面的内容用单引号括起来
        lines = @readlines(filepath)
        s = []
        for line in lines
            if /.*?:\s*[^\s]+/.test( line )
                s.push( line.replace( /^(.*?):\s*(.*?)\s*$/ , "$1: '$2'" ) )
            else
                s.push( line )
        code = s.join( utilfile.NEWLINE )

        try
            return yaml.eval( code )
        catch err
            throw "解析 #{filepath} 时出现错误, 请检查该文件, 该文件必须是标准YAML格式"

class Writer
    write:( filepath , content ) ->
        if !utilpath.exists( syspath.dirname( filepath ) )
            mkdirp.sync( syspath.dirname( filepath ) )
        fs.writeFileSync( filepath , content )


exports.file = utilfile = {}        
utilfile.reader = Reader
utilfile.writer = Writer
utilfile.NEWLINE = '\n'

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


utilfile.findify = ( path_without_extname , ext_list ) ->
    list = [ "" ].concat( ext_list )
    for ext in list
        path = path_without_extname + ext 
        if utilpath.exists( path )
            return path
    throw "找不到文件或对应的编译方案 [#{path_without_extname}] 后缀检查列表为[#{ext_list}]"

#----------------------------

# 默认的配置文件
# baseUri是根据该路径找到最近的一个fekit.config
# 内容为
###
    {
        // 库配置
        "lib" : {
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
        @fekit_config_path = syspath.join( @fekit_root_dirname , @fekit_config_filename )
        try 
            @root = new utilfile.reader().readJSON( @fekit_config_path )
            if !@root.lib then @root.lib = {}
        catch err
            if utilpath.exists( @fekit_config_path )
                throw "@fekit_config_filename 解析失败, 请确认该文件格式是否符合正确的JSON格式"
            else
                # 如果没有fekit, 有可能是使用单独文件编译模式, 则使用默认配置
                @root = { "lib" : {} , "export" : [] }

    each_export_files : ( cb ) ->
        list = @root["export"] || []
        for file in list
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

            if utilpath.exists( path ) 
                cb( path , parents , opts )
            else
                utillogger.error("找不到文件 #{path}")

    each_export_files_async : ( cb , doneCallback ) ->
        tasks = []
        list = @root["export"] || []
        for file in list
            _tmp = (file) =>
                ( seriesCallback ) =>
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
                        opts.path = file
                        opts.partial_path = file

                    if utilpath.exists( path ) 
                        cb( path , parents , opts , seriesCallback )
                    else
                        utillogger.error("找不到文件 #{path}")
                        seriesCallback()

            tasks.push _tmp(file)

        async.series tasks , ( err ) ->
            if err then throw err 
            doneCallback()

    findExportFile : ( filepath , cb ) ->
    
        list = @root["export"] || []

        for file in list
            if _.isObject( file )
                path = syspath.join( @fekit_root_dirname , "src" , file.path )
                parents = _.map file.parents or [] , ( ppath ) =>
                                syspath.join( @fekit_root_dirname , "src" , ppath )
            else
                path = syspath.join( @fekit_root_dirname , "src" , file )
                parents = []

            if filepath is path
                cb( filepath , parents )

        cb( filepath , [] )

    doScript : ( type , context ) ->

        ctx = context || {} 
        ctx.path = utilpath
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
        @filename = filename
        @fnames = fnames

        @has_version = true

    set_no_version : () ->
        @has_version = false

    set_has_version : () ->
        @has_version = true

    to_prd: ( md5 ) ->
        prefix = @baseuri.replace( @REPLACE_STRING , "prd" )
        if @has_version
            name = @fnames[0] + "@" + md5 + @extname
        else
            name = @fnames[0] + @extname
        return syspath.join( prefix , name )

    to_dev: () ->
        prefix = @baseuri.replace( @REPLACE_STRING , "dev" )
        if @has_version
            name = @fnames[0] + "@dev" + @extname
        else 
            name = @fnames[0] + @extname
        return syspath.join( prefix , name )

    to_src: () ->
        prefix = @baseuri.replace( @REPLACE_STRING , "src" )
        name = @fnames[0] + @extname
        return syspath.join( prefix , name )

    # 转变为对应路径的ver文件
    to_ver: () ->
        prefix = @baseuri.replace( @REPLACE_STRING , "ver" )
        name = @fnames[0] + @extname + ".ver"
        return syspath.join( prefix , name )        

UrlConvert.PRODUCTION_REGEX = /\/prd\//

exports.UrlConvert = UrlConvert

#---------------------------


exports.proc = utilproc = 
    exec : ( cmd ) ->
        child_process.exec cmd , ( error , stdout , stderr ) =>
            if error then utillogger.error( error )


#---------------------------

exports.sys = utilsys = 
    isWindows : process.platform is 'win32'


#---------------------------


exports.logger = utillogger = 
    debug : false ,
    setup : ( options ) ->
        if options && options.debug then utillogger.debug = true 
    info : () ->
        if !utillogger.debug then return
        console.info("[TRACE] " , Array.prototype.join.call( arguments , " " ) )
    error : () ->
        console.info("[ERROR] " , Array.prototype.join.call( arguments , " " ) )
    log : () ->
        console.info("[LOG] " , Array.prototype.join.call( arguments , " " ) )


#---------------------------

exports.exit = exit = (exitCode) ->
    if process.stdout._pendingWriteReqs or process.stderr._pendingWriteReqs
        process.nextTick () ->
            exit(exitCode)
    else
        process.exit(exitCode)


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


