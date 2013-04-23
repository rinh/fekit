syspath = require 'path'
utils = require '../../util'
md5 = require "MD5"
parser = require '../parser'

ModulePath = require('./path').ModulePath
ModuleConfig = require('./config').ModuleConfig


# ---------------------------


MODULE_CONTENT_TYPE = 
    JAVASCRIPT : "javascript" 
    CSS : "css"


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
        @ast = null

    hasDependencies: () ->
        return @depends.length > 0

    # 分析模块的依赖关系
    analyze:( doneCallback ) ->
        self = this
        @_process @path.getFullPath() , ( err , source ) ->
            self.ast = parser.parseAST( source )
            self.ast.find 'REQUIRE' , ( node ) ->
                module = Module.parse( node.value , self )
                self.depends.push( module )
                self.analyzed()
            doneCallback.call( self , err )

    # override
    analyzed:()->


    _process:( path , cb ) ->
        txt = new utils.file.reader().read( path )
        ext = syspath.extname( path )
        plugin = ModulePath.getPlugin(ext)
        if plugin
            plugin.process txt , path , ( err , result ) ->
                if err 
                    cb( "文件编译错误 #{path} , #{err.toString()}" , "" ) 
                else 
                    cb( err , result )
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
Module.parse = ( path , parentModule ) ->
    if parentModule
        uri = ModulePath.resolvePath( path , parentModule )
    else
        uri = path
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

    analyzed: () ->
        if @config.isCompileTypeNormal()
            @ast.defineType 'REQUIRE' , ( node ) ->
                return ""
        else if @config.isCompileTypeModular()
            @ast.defineType 'REQUIRE' , ( node ) ->
                return "__context.____MODULES['#{@guid}'];"
        else 
            throw "找不到正确的编译方式, 请修改fekit.config中的 compiler [目前值:#{@config.compileType()}]"


    _wrap: ( source ) ->
        """

            ;(function(__context){
                var module = {
                    id : "#{@guid}" , 
                    filename : "#{@path.getFullPath()}" ,
                    exports : {}
                };
                if( !__context.____MODULES ) { __context.____MODULES = {}; }
                var r = (function( exports , module , global ){

                #{source}

                })( module.exports , module , __context );
                __context.____MODULES[ "#{@guid}" ] = module.exports;
            })(this);

        """

    getSourceWithoutDependencies:() ->
        if @config.isCompileTypeNormal()
            return @ast.print()
        if @config.isCompileTypeModular()
            return @_wrap( @ast.print() )
        throw "找不到正确的编译方式, 请修改fekit.config中的 compiler [目前值:#{@config.compileType()}]"



class CSSModule extends Module
    constructor:( uri ) ->
        super(uri)

    analyzed:() ->
        @ast.defineType 'REQUIRE' , ( node ) ->
            return ""

    getSourceWithoutDependencies: () ->
        return @ast.print()



exports.Module = Module


