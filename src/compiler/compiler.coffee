_            = require 'underscore'
async        = require 'async'
autoprefixer = require 'autoprefixer'
fs           = require 'fs'
postcss      = require 'postcss'
syspath      = require 'path'
utils        = require '../util'


exports.booster = booster = require './module/booster'

Module = require("./module/module").Module
Module.booster = booster

ModulePath = require('./module/path').ModulePath

exports.path = Module.path

### ---------------------------
    插件系统
###

# 返回插件后缀所代表的 contentType
exports.getContentType = ( url ) ->
    Module.getContentType( syspath.extname( url ) )

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

# 加载项目插件
ModulePath.getCompile(process.cwd(), './')

### -----------------------
    export
###

# 判断是否循环引用
LOOPS = {}
MAX_LOOP_COUNT = 70

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
                        LOOPS[sub_module.guid] = ( LOOPS[sub_module.guid] || 0 ) + 1
                        if LOOPS[sub_module.guid] > MAX_LOOP_COUNT
                            seriesCallback "出现循环调用，请检查 #{sub_module.path.uri} 的引用"
                        #console.info USED_MODULES[ sub_module.guid ] , sub_module.guid , sub_module.path.uri
                        if USED_MODULES[ sub_module.guid ]
                            utils.proc.setImmediate seriesCallback
                            return
                        getSource sub_module , options , ( e , txt ) ->
                            arr.push( txt )
                            utils.proc.setImmediate ()->
                                seriesCallback( e )
                deps.push _tmp(sub_module)

        async.series deps, (err) ->
            if err
                callback err
                return null

            source = module.getSourceWithoutDependencies()
            c = module.config.config?.root?.autoprefixer
            if _.isObject(c) and module.iscss
                plugin = autoprefixer c
                return postcss([plugin]).process(source).then((out) ->
                    arr.push out.css
                    USED_MODULES[module.guid] = 1

                    callback(null ,arr.join(utils.file.NEWLINE))
                )['catch']((out) ->
                    console.error '\n%s %s',
                        syspath.relative(process.cwd(),
                        module.path.uri), out.message
                    process.exit 1)

            arr.push source
            USED_MODULES[module.guid] = 1

            callback(null ,arr.join(utils.file.NEWLINE))


###
 options {
    // 依赖的文件列表(fullpath)
    dependencies_filepath_list : []
    // 使用非依赖模式
    no_dependencies : false ,
    // 非依赖模式的生成方案
    render_dependencies : function ,
    // 根模块文件路径(可有可无,如果没有则默认当前处理文件为root_module)
    root_module_path : ""
    // 开发环境
    environment : "local" / "dev" / "prd"
 }
###
exports.compile = ( filepath , options , doneCallback ) ->
    LOOPS = {}
    if arguments.length is 3
        options = options or {}
        doneCallback = doneCallback
    else if arguments.length is 2
        doneCallback = options
        options = {}

    use_modules = {}
    module = Module.parse( filepath , options , null , Module.parse( options.root_module_path or filepath ) )

    _list = ( options.dependencies_filepath_list or [] )

    _iter = ( dep_path , seriesCallback ) ->
        parent_module = new Module( dep_path , options )
        parent_module.getDependenciesURI ( err , module_guids ) ->
            _.extend( use_modules , module_guids ) unless err
            utils.proc.setImmediate ()->
                seriesCallback( err )

    _done = ( err ) ->
        if err
            doneCallback( err )
            return

        getSource(module, {
            use_modules         : use_modules
            no_dependencies     : !!options.no_dependencies
            render_dependencies : options.render_dependencies
        }, (err, result) ->
            doneCallback(err, result, module))

    utils.async.series _list , _iter , _done

