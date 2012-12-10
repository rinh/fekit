async = require 'async'
syspath = require 'path'
fs = require 'fs'
utils = require '../util'

### ---------------------------
    模块即为单一文件
###
class Module
    
    # @uri 模块真实物理路径
    # @checker 如果没有checker, 基本上可以代表是根模块
    constructor:( uri , checker ) ->
        @path = new ModulePath(uri)
        @config = new ModuleConfig(uri)
        @compiler = new Compiler()
        @sources = []
        if !checker
            @checker = new ModuleChecker( this )
        else
            @checker = checker

    # 分析模块的依赖关系
    _analyze:() ->
        @sources = []
        lines = @compiler.readlines(@path.getFullPath())
        for line in lines
            switch @checker.check(line)
                when MODULE_LINETYPE.NORMAL_LINE
                    @sources.push(line)
                when MODULE_LINETYPE.IMPORT_LINE
                    module = Module.parse( line , this )
                    module._analyze()
                    @sources.push(module)

    # 模块去重
    _uniq:() ->
        list = []
        for line in @sources
            if line instanceof Module
                if !@checker.existsModuleReference( line )
                    list = list.concat( line._uniq() )
                    @checker.addModuleReference( line )
            else
                list.push( line )
        return list

    toString:() ->
        @_analyze()
        return @_uniq().join( utils.file.NEWLINE )



# 通过模块引用字符串, 跟据parentModule解析出子模块的真实路径 , 并返回正确的模块
# line 是原始代码
Module.parse = ( line , parentModule ) ->
    uri = ModulePath.resolvePath( parentModule.checker.parseImportURL( line ) , parentModule )
    return new Module( uri , parentModule.checker )


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
    模块检查器
###
class ModuleChecker
    
    constructor:( @rootmodule ) ->
        @module_reference_list = {}
        @reg = ///^
                    \s*
                    \b
                    (import|require)
                    \s*
                    \(
                        \s*
                        (?:["'])
                        (.*?)
                        (?:["'])
                        \s*
                    \)
                    \s*[;]?\s*
               $///

    # 从一行代码中解析出模块引用的路径
    parseImportURL: ( line ) ->
        return line.match( @reg )[2]

    # 检查单行是否是一个模块引用
    check:( line ) ->
        if @reg.test( line )
            return MODULE_LINETYPE.IMPORT_LINE
        else 
            return MODULE_LINETYPE.NORMAL_LINE

    existsModuleReference:( module ) ->
        return !!@module_reference_list[module.path.getFullPath()] 

    #增加模块引用, 用来去重使用
    addModuleReference:( module ) ->
        @module_reference_list[module.path.getFullPath()] = module


### ---------------------------
    模块中单行类型
###
MODULE_LINETYPE = 
    NORMAL_LINE : 0
    IMPORT_LINE : 1


### ---------------------------
    不同文件的编译方案
###
class Compiler
    constructor:() ->

    readlines:( path ) ->
        txt = new utils.file.reader().read( path )
        ext = syspath.extname( path )
        if Compiler.TYPES[ext]
            return Compiler.TYPES[ext]( txt , path ).split( utils.file.NEWLINE )
        else
            throw "找不到对应后缀名的编译方案 #{path}"

Compiler.TYPES = {}

### ---------------------------
    插件系统
###


# 增加插件, 该插件会跟据不同后缀名进行不同的渲染
addPlugin = ( extName , compileFunc ) ->
    ModulePath.EXTLIST.push( extName )
    # compileFunc
    # txt 是原文件的全部内容
    # path 是该文件路径
    # 返回的应该是此文件编译后的内容
    Compiler.TYPES[extName] = compileFunc

pluginsDir = syspath.join( syspath.dirname( __filename ) , "plugins" )

# 加载所有插件
utils.path.each_directory pluginsDir , ( filepath ) =>
    type = "." + syspath.basename( filepath , ".js" )
    addPlugin( type , require( filepath ).process )
 


### -----------------------
    export
###

exports.Module = Module
exports.ModuleChecker = ModuleChecker
exports.compile = ( filepath ) ->
    m = new Module( filepath )
    return m.toString()

