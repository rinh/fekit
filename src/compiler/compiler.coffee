async = require 'async'
syspath = require 'path'
fs = require 'fs'
utils = require '../util'
_ = require 'underscore'
md5 = require "MD5"


# regex

MODULE_LINE_REGEXP = ///^
                        (
                        [^\/]*
                        )
                        (@import\s+url|require)
                        \s*
                        \(
                            \s*
                            (?:["'])
                            (.*?)
                            (?:["'])
                            \s*
                        \)
                        [\s;]*
                   $///


### ---------------------------
    模块即为单一文件
###
class Module
    
    # @uri 模块真实物理路径
    constructor:( uri ) ->
        @path = new ModulePath(uri)
        @config = new ModuleConfig(uri)
        @compiler = new Compiler()
        @guid = md5( @path.getFullPath() )
        @depends = []
        @sources = []
        


    # 得到源码中, 引用模块位置的占位符
    # line - 引用的源文件
    # override
    _getPlaceHolder: ( line ) ->
        return null

    # 检查单行是否是一个模块引用
    _check:( line ) ->
        if MODULE_LINE_REGEXP.test( line )
            return MODULE_LINETYPE.IMPORT_LINE
        else 
            return MODULE_LINETYPE.NORMAL_LINE

    hasDependencies: () ->
        return @depends.length > 0

    # 分析模块的依赖关系
    analyze:( doneCallback ) ->
        self = this
        @sources = []
        @compiler.readlines @path.getFullPath() , ( err , lines ) =>
            for line in lines
                switch @_check(line)
                    when MODULE_LINETYPE.NORMAL_LINE
                        @sources.push( line )
                    when MODULE_LINETYPE.IMPORT_LINE
                        module = Module.parse( line , this )
                        @depends.push( module )
                        @sources.push( module._getPlaceHolder( line ) )
            doneCallback.call( self , err )

    # 该方法会跟据编译模式进行不同的编译
    # override
    getSourceWithoutDependencies: () ->
        return null


    # 返回一个object, 其中是该模块下所有的引用(包含自身)
    getDependenciesURI: ( parent_uris ) ->
        uris = parent_uris or {}
        for m in @depends 
            uris[ m.guid ] = 1
            if m.hasDependencies() then m.getDependenciesURI( uris )
        uris[ @guid ] = 1
        return uris



class JSModule extends Module
    constructor:( uri ) ->
        super(uri)

    _getPlaceHolder: ( line ) ->
        if @config.isCompileTypeNormal()
            return ""
        if @config.isCompileTypeModular()
            return line.replace MODULE_LINE_REGEXP , ( match , prefix , keyword , path ) =>
                return "#{prefix}__context.____MODULES['#{@guid}'];"
        throw "找不到正确的编译方式, 请修改fekit.config中的 compiler [目前值:#{@config.compileType()}]"

    _wrap: () ->
        """

            ;(function(__context){
                var module = {
                    id : "#{@guid}" , 
                    filename : "#{@path.getFullPath()}" ,
                    exports : {}
                };
                if( !__context.____MODULES ) { __context.____MODULES = {}; }
                var r = (function( exports , module , global ){

                #{@sources.join( utils.file.NEWLINE )}

                })( module.exports , module , __context );
                __context.____MODULES[ "#{@guid}" ] = module.exports;
            })(this);

        """

    getSourceWithoutDependencies:() ->
        if @config.isCompileTypeNormal()
            return @sources.join( utils.file.NEWLINE )
        if @config.isCompileTypeModular()
            return @_wrap()
        throw "找不到正确的编译方式, 请修改fekit.config中的 compiler [目前值:#{@config.compileType()}]"



class CSSModule extends Module
    constructor:( uri ) ->
        super(uri)

    _getPlaceHolder: ( line ) ->
        return ""

    getSourceWithoutDependencies: () ->
        return @sources.join( utils.file.NEWLINE )



# 通过模块引用字符串, 跟据parentModule解析出子模块的真实路径 , 并返回正确的模块
# 从一行代码中解析出模块引用的路径
# line 是原始代码
Module.parse = ( line , parentModule ) ->
    if parentModule
        uri = ModulePath.resolvePath( line.match( MODULE_LINE_REGEXP )[3] , parentModule )
    else
        uri = line
    switch Compiler.getContentType( syspath.extname( uri ) )
        when MODULE_CONTENT_TYPE.JAVASCRIPT
            return new JSModule( uri )
        when MODULE_CONTENT_TYPE.CSS
            return new CSSModule( uri )



### ---------------------------
    模块路径
###
class ModulePath
    
    # @uri 物理真实路径
    constructor:( @uri ) ->

    parseify:( path_without_extname ) ->
        extname = @extname()
        if ~ModulePath.EXTLIST.indexOf( extname )
            return utils.file.findify( path_without_extname , ModulePath.EXTLIST )
        throw "not found extname for compile [#{extname}]"

    extname:() ->
        return syspath.extname(@uri)

    dirname:() ->
        return syspath.dirname(@uri)

    getFullPath:()->
        return @uri

    getContentType:()->
        return Compiler.getContentType( @extname() )

###
    解析子模块真实路径

    子模块路径表现形式可以是
        省略后缀名方式, 该方式会认为子模块后缀名默认与parentModule相同
            a/b/c
            a.b.c
            
            后缀名默认匹配顺序为, 如果都找不到就会报错
            [javascript]
            .js / .coffee / .mustache 
            [css]
            .css / .less

    子模块的

    子模块路径分2种
    1, 相对路径, 相对于父模块的dirname. 如 a/b/c
    2, 库引用路径, 库是由配置指定的路径. 如 core/a/b/c , core是在配置文件中进行配置的

###
ModulePath.resolvePath = ( path , parentModule ) ->
    parts = utils.path.split_path( path , ModulePath.EXTLIST )
    result = []

    # 解析全路径
    for part , i in parts
        if i == 0
            if parentModule.config.isUseLibrary( part )
                # 库引用路径
                result.push( parentModule.config.parseLibrary( part ) )    
            else
                # 相对路径
                result.push( parentModule.path.dirname() )
                result.push( part )
        else
            result.push( part )

    # 解析文件名( 猜文件名 )
    path_without_extname = syspath.join.apply( syspath , result )
    truelypath = parentModule.path.parseify( path_without_extname )
    utils.logger.info("[COMPILE] 解析子模块真实路径 #{path} >>>> #{truelypath}")
    return truelypath


# 后缀列表 
ModulePath.EXTLIST = []


### ---------------------------
    模块配置
    该配置是由指定文件的路径向上迭代得到的, 直到遇见fekit.config文件

    {
        //库的配置
        "lib" : {
            "core" : "./scripts/core"
        }
    }

###
class ModuleConfig
    constructor:(@uri) ->
        @config = utils.config.parse( @uri )

    compileType:() ->
        return @config.root.compiler

    isCompileTypeNormal:() ->
        return !@config.root.compiler

    isCompileTypeModular:() ->
        return @config.root.compiler is "modular"
        
    isUseLibrary:(libname) ->
        return !!@config.root.lib[libname]

    # 解析库的真实物理地址
    # libname 如果不是一个库名, 则直接返回. 如果是则解析 
    parseLibrary:(libname) ->
        path = @config.root.lib[libname]
        if !path
            return libname
        else
            return syspath.join( @config.fekit_root_dirname , path )

### ---------------------------
    模块中单行类型
###
MODULE_LINETYPE = 
    NORMAL_LINE : 0
    IMPORT_LINE : 1

MODULE_CONTENT_TYPE = 
    JAVASCRIPT : "javascript" 
    CSS : "css"


### ---------------------------
    不同文件的编译方案
###
class Compiler
    constructor:() ->

    readlines:( path , cb ) ->
        txt = new utils.file.reader().read( path )
        ext = syspath.extname( path )
        if Compiler.TYPES[ext]
            Compiler.TYPES[ext].process txt , path , ( err , result ) ->
                if err 
                    cb( "文件编译错误 #{path} , #{err.toString()}" , [] ) 
                else 
                    cb( err , result.split( utils.file.NEWLINE ) )
        else
            cb( "找不到对应后缀名(#{ext})的编译方案 #{path}" )

Compiler.TYPES = {}

Compiler.getContentType = ( extName ) ->
    return Compiler.TYPES[extName]?.contentType

### ---------------------------
    插件系统
###


# 增加插件, 该插件会跟据不同后缀名进行不同的渲染
addPlugin = ( extName , plugin ) ->
    ModulePath.EXTLIST.push( extName )
    # plugin.process
    # txt 是原文件的全部内容
    # path 是该文件路径
    # 返回的应该是此文件编译后的内容
    Compiler.TYPES[extName] = plugin

pluginsDir = syspath.join( syspath.dirname( __filename ) , "plugins" )

# 加载所有插件
utils.path.each_directory pluginsDir , ( filepath ) =>
    extname = syspath.extname( filepath )
    type = "." + syspath.basename( filepath , extname )
    addPlugin( type , require( filepath ) )
 

### -----------------------
    export
###

# 递归处理所有模块
getSource = ( module , options , callback ) ->
    module.analyze ( err )->

        if err 
            callback( err )
            return

        arr = []
        USED_MODULES = options.use_modules

        if options.render_dependencies 
            module.getSourceWithoutDependencies = options.render_dependencies
     
        deps = []

        if options.no_dependencies isnt true
            for sub_module in module.depends
                _tmp = (sub_module) -> 
                    ( seriesCallback ) =>
                        if USED_MODULES[ sub_module.guid ]
                            process.nextTick seriesCallback
                            return
                        getSource sub_module , options , ( e , txt ) ->
                            arr.push( txt )
                            process.nextTick ()->
                                seriesCallback( e )
                deps.push _tmp(sub_module)

        async.series deps , ( err ) ->
            if err 
                callback( err )
                return

            arr.push( module.getSourceWithoutDependencies() )
            USED_MODULES[ module.guid ] = 1

            callback( null , arr.join( utils.file.NEWLINE ) )



exports.Module = Module
exports.MODULE_LINE_REGEXP = MODULE_LINE_REGEXP

###
 options {
    // 依赖的文件列表(fullpath)
    dependencies_filepath_list : []
    // 使用非依赖模式
    no_dependencies : false , 
    // 非依赖模式的生成方案
    render_dependencies : function
 }
###
exports.compile = ( filepath , options , doneCallback ) ->
    if arguments.length is 3 
        options = options or {}
        doneCallback = doneCallback
    else if arguments.length is 2
        doneCallback = options
        options = {}

    use_modules = {}
    module = Module.parse( filepath )

    _list = ( options.dependencies_filepath_list or [] )
    _iter = ( dep_path , seriesCallback ) ->
            parent_module = new Module( dep_path )
            parent_module.analyze ( err ) ->
                _.extend( use_modules , parent_module.getDependenciesURI() )
                seriesCallback( err )
    _done = ( err ) ->
            if err 
                doneCallback( err )
                return
            getSource( module , {
                use_modules : use_modules 
                no_dependencies : !!options.no_dependencies
                render_dependencies : options.render_dependencies
            } , ( err , result ) ->
                doneCallback( err , result )
            ) 

    utils.async.series _list , _iter , _done

        



