syspath = require 'path'
utils = require '../../util'
parser = require '../parser'
_ = require 'underscore'
util = require 'util'
events = require('events')

ModulePath = require('./path').ModulePath
ModuleConfig = require('./config').ModuleConfig


# ---------------------------

MODULE_COMPILE_TYPE = ModuleConfig.MODULE_COMPILE_TYPE

MODULE_CONTENT_TYPE =
    JAVASCRIPT : "javascript"
    CSS : "css"


### ---------------------------
    模块即为单一文件
###
class Module

    # @uri 模块真实物理路径
    constructor:( uri , @options ) ->
        @path = new ModulePath(uri)
        @config = new ModuleConfig(uri)
        @source = utils.file.io.read( @path.getFullPath() )
        @depends = []
        @ast = null
        Module.booster.init_cached( @path.uri ) if Module.booster
        checksum = Module.booster && Module.booster.get_checksum_cache( @path.uri )
        @guid = checksum or utils.md5( @source )
        @root_module = null
        @parent = null

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
                    module = Module.parse( node.value , self.options , self , self.root_module )
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
        plugin = ModulePath.getPlugin(ext, @config.config.fekit_root_dirname)

        if ext is ".json" and @getCompileType() is MODULE_COMPILE_TYPE.NORMAL
            utils.logger.error "#{path} 只支持模块化模式编译"

        if plugin
            # 去除 BOM 头
            source = utils.removeBOM @source
            # 处理宏
            try
                env = utils.getCurrentEnvironment( @options )
                source = utils.replaceEnvironmentConfig 'text' , source , @config.config.getEnvironmentConfig()[ env ]
            catch err
                utils.logger.error "在 environment 配置中找不到 #{env}"
                source = source

            plugin.process source , path , this , ( err , result ) ->
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
    getDependenciesURI: ( cb , parent_uris ) ->
        self = @
        @analyze ( err ) ->
            return cb( err ) if err
            uris = parent_uris or {}
            utils.async.series @depends , ( m , done ) ->
                    uris[ m.guid ] = 1
                    m.getDependenciesURI ( err , _uris ) ->
                        return done( err ) if err
                        _.extend uris , _uris
                        done()
                     , uris
                , ( err ) ->
                    uris[ self.guid ] = 1
                    cb( err , uris )

Module.prototype.__proto__ = events.EventEmitter.prototype

# 通过模块引用字符串, 跟据parentModule解析出子模块的真实路径 , 并返回正确的模块
# 从一行代码中解析出模块引用的路径
Module.parse = ( path , options , parentModule , rootModule ) ->

    if parentModule
        uri = ModulePath.resolvePath( path , parentModule )
    else
        uri = path
    switch ModulePath.getContentType( syspath.extname( uri ) )
        when MODULE_CONTENT_TYPE.JAVASCRIPT
            m = new JSModule( uri )
        when MODULE_CONTENT_TYPE.CSS
            m = new CSSModule( uri )

    m.root_module = rootModule if rootModule
    m.parent = parentModule
    m.options = options
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
        @iscss = true

    analyzed:() ->
        @ast.defineType 'REQUIRE' , ( node ) ->
            return ""

    getSourceWithoutDependencies: () ->
        return @ast.print()




exports.Module = Module

