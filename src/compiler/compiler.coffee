async = require 'async'
syspath = require 'path'
fs = require 'fs'
utils = require '../util'
_ = require 'underscore'

Module = require("./module/module").Module

### ---------------------------
    插件系统
###

# 增加插件, 该插件会跟据不同后缀名进行不同的渲染
addPlugin = ( extName , plugin ) ->
    # plugin.process
    # txt 是原文件的全部内容
    # path 是该文件路径
    # 返回的应该是此文件编译后的内容
    Module.addExtensionPlugin( extName , plugin )

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
                            seriesCallback()
                            return
                        getSource sub_module , options , ( e , txt ) ->
                            arr.push( txt )
                            seriesCallback( e )
                deps.push _tmp(sub_module)

        async.series deps , ( err ) ->
            if err 
                callback( err )
                return

            arr.push( module.getSourceWithoutDependencies() )
            USED_MODULES[ module.guid ] = 1

            callback( null , arr.join( utils.file.NEWLINE ) )


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

        



