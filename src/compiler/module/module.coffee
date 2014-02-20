syspath = require 'path'
utils = require '../../util'
md5 = require "MD5"
parser = require '../parser'

ModulePath = require('./path').ModulePath
ModuleConfig = require('./config').ModuleConfig


# ---------------------------

MODULE_COMPILE_TYPE = ModuleConfig.MODULE_COMPILE_TYPE

MODULE_CONTENT_TYPE = 
    JAVASCRIPT : "javascript" 
    CSS : "css"
    HTML : "html"


### ---------------------------
    模块即为单一文件
###
class Module
    
    # @uri 模块真实物理路径
    constructor:( uri ) ->
        @path = new ModulePath(uri)
        @config = new ModuleConfig(uri)
        @source = utils.file.io.read( @path.getFullPath() )
        @depends = []
        @ast = null

        Module.booster.init_cached( @path.uri ) if Module.booster
        checksum = Module.booster && Module.booster.get_checksum_cache( @path.uri )
        @guid = checksum or md5( @source )

    hasDependencies: () ->
        return @depends.length > 0

    # 得到当前模块编译模式
    getCompileType: () ->
        type = @config.getCompileType()

        ### [Obsolete] 如果是组件编译模式，寻找当前模块的上级fekit.config，如果没有，则报UNKNOWN
        if type is MODULE_COMPILE_TYPE.COMPONENT
            fkconf_path = utils.path.closest @path.getFullPath() , 'fekit.config' , false , ( path ) ->
                config = utils.file.io.readJSON( path )
                config.compiler isnt 'component'
            return MODULE_COMPILE_TYPE.UNKNOWN if !fkconf_path

            fkconf = new ModuleConfig( fkconf_path )
            return fkconf.getCompileType()
        ###

        # 如果是组件编译模式，自动转为 modular。 这样意味着非 modular 的项目不能使用组件
        return MODULE_COMPILE_TYPE.MODULAR if type is MODULE_COMPILE_TYPE.COMPONENT

        return type

    # 分析模块的依赖关系
    analyze:( doneCallback ) ->
        self = this
        is_err = false
        @_process @path.getFullPath() , ( err , source ) ->
            self.ast = parser.parseAST( source )
            self.ast.find 'REQUIRE' , ( node ) ->
                try 
                    module = Module.parse( node.value , self , self.root_module )
                    module.parent_module = module
                    node.module = module
                    self.depends.push( module )
                    self.analyzed()
                catch err 
                    is_err = true
                    doneCallback.call( self , err )
            unless is_err then doneCallback.call( self , err )

    # override
    analyzed:()->

 
    _process:( path , cb ) ->
        #txt = new utils.file.reader().read( path )
        ext = syspath.extname( path )
        plugin = ModulePath.getPlugin(ext)
        if plugin
            plugin.process @source , path , this , ( err , result ) ->
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
Module.parse = ( path , parentModule , rootModule ) ->

    if parentModule
        uri = ModulePath.resolvePath( path , parentModule )
    else
        uri = path
    switch ModulePath.getContentType( syspath.extname( uri ) )
        when MODULE_CONTENT_TYPE.JAVASCRIPT
            m = new JSModule( uri )
        when MODULE_CONTENT_TYPE.CSS
            m = new CSSModule( uri )
        when MODULE_CONTENT_TYPE.HTML
            m = new HTMLModule( uri )
    m.root_module = rootModule if rootModule
    return m


Module.addExtensionPlugin = ( extName , plugin ) ->
    ModulePath.addExtensionPlugin( extName , plugin )

Module.getContentType = ( extName ) ->
    ModulePath.getContentType( extName )

# 使用 booster 进行加速
Module.booster = null

Module.path = ModulePath 

#--------------------



class JSModule extends Module
    constructor:( uri ) ->
        super(uri)

    analyzed: () ->
        switch @getCompileType()
            when MODULE_COMPILE_TYPE.NORMAL
                @ast.defineType 'REQUIRE' , ( node ) ->
                    return ""
            when MODULE_COMPILE_TYPE.MODULAR
                @ast.defineType 'REQUIRE' , ( node ) ->
                    return "__context.____MODULES['#{node.module.guid}']" + ( if node.is_line_end then ";" else "" )
            else 
                throw "找不到正确的编译方式, 请修改fekit.config中的 compiler [目前值:#{@config.compileType()}]"


    _wrap: ( source ) ->
        """

            ;(function(__context){
                var module = {
                    id : "#{@guid}" , 
                    filename : "#{syspath.basename(@path.getFullPath())}" ,
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
        switch @getCompileType()
            when MODULE_COMPILE_TYPE.NORMAL
                return @ast.print()
            when MODULE_COMPILE_TYPE.MODULAR
                return @_wrap( @ast.print() )
            else
                throw "找不到正确的编译方式, 请修改fekit.config中的 compiler [目前值:#{@config.compileType()}]"



class CSSModule extends Module
    constructor:( uri ) ->
        super(uri)

    analyzed:() ->
        @ast.defineType 'REQUIRE' , ( node ) ->
            return ""

    getSourceWithoutDependencies: () ->
        return @ast.print()

class HTMLModule extends Module
    constructor:( uri ) ->
        super(uri)

    analyzed:() ->
        @ast.defineType 'REQUIRE' , ( node ) ->
            return ""

    getSourceWithoutDependencies: () ->
        return @ast.print()

exports.Module = Module

