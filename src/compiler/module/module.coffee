syspath = require 'path'
utils = require '../../util'
md5 = require "MD5"

ModulePath = require('./path').ModulePath
ModuleConfig = require('./config').ModuleConfig


### ---------------------------
    模块中单行类型
###
MODULE_LINETYPE = 
    NORMAL_LINE : 0
    IMPORT_LINE : 1

MODULE_CONTENT_TYPE = 
    JAVASCRIPT : "javascript" 
    CSS : "css"


    
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

exports.MODULE_LINE_REGEXP = MODULE_LINE_REGEXP

### ---------------------------
    模块即为单一文件
###
class Module
    
    # @uri 模块真实物理路径
    constructor:( uri ) ->
        @path = new ModulePath(uri)
        @config = new ModuleConfig(uri)
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
        @readlines @path.getFullPath() , ( err , lines ) =>
            for line in lines
                switch @_check(line)
                    when MODULE_LINETYPE.NORMAL_LINE
                        @sources.push( line )
                    when MODULE_LINETYPE.IMPORT_LINE
                        module = Module.parse( line , this )
                        @depends.push( module )
                        @sources.push( module._getPlaceHolder( line ) )
            doneCallback.call( self , err )

    readlines:( path , cb ) ->
        txt = new utils.file.reader().read( path )
        ext = syspath.extname( path )
        if ModulePath.EXTTABLE[ext]
            ModulePath.EXTTABLE[ext].process txt , path , ( err , result ) ->
                if err 
                    cb( "文件编译错误 #{path} , #{err.toString()}" , [] ) 
                else 
                    cb( err , result.split( utils.file.NEWLINE ) )
        else
            cb( "找不到对应后缀名(#{ext})的编译方案 #{path}" )


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




# 通过模块引用字符串, 跟据parentModule解析出子模块的真实路径 , 并返回正确的模块
# 从一行代码中解析出模块引用的路径
# line 是原始代码
Module.parse = ( line , parentModule ) ->
    if parentModule
        uri = ModulePath.resolvePath( line.match( MODULE_LINE_REGEXP )[3] , parentModule )
    else
        uri = line
    switch ModulePath.getContentType( syspath.extname( uri ) )
        when MODULE_CONTENT_TYPE.JAVASCRIPT
            return new JSModule( uri )
        when MODULE_CONTENT_TYPE.CSS
            return new CSSModule( uri )


Module.addExtensionPlugin = ( extName , plugin ) ->
    ModulePath.addExtensionPlugin( extName , plugin )

#--------------------



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
                var module_exports = {};
                if( !__context.____MODULES ) { __context.____MODULES = {}; }
                var r = (function( exports ){

                #{@sources.join( utils.file.NEWLINE )}

                })( module_exports );
                if ( r ) { module_exports = r; } 
                __context.____MODULES[ "#{@guid}" ] = module_exports;
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



exports.Module = Module


