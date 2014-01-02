_ = require 'underscore'
env = require '../env'
utils = require '../util'
async = require 'async'
Package = require '../package'

exports.usage = "安装 fekit 组件 "

exports.set_options = ( optimist ) ->

    optimist.alias 'c' , 'useconfig'
    optimist.describe 'c' , '强制使用配置文件中的版本范围。 如果没有配置文件或配置文件中没有配置，则不安装。安装后不改写配置文件。'

exports.run = ( options ) ->

    start( options )


# ------------------------


doneCallback = ( err ) ->
    if err then utils.logger.error err.toString() 

getPackageConfig = ( configPath , name ) ->
    return null unless utils.path.exists configPath
    config = utils.file.io.readJSON configPath
    deps = config.dependencies || {}
    return deps[name]

saveToConfig = ( configPath , name , version ) ->
    return unless utils.path.exists configPath
    config = utils.file.io.readJSON configPath
    deps = config.dependencies || {}
    deps[ name ] = version

    config.dependencies = deps

    utils.file.io.write configPath , JSON.stringify( config , {} , 4 )


start = ( options ) ->

    spec_pkg = options['_'][1]

    # 先寻找最近的fekit_modules目录 
    basepath = utils.path.closest options.cwd , Package.FEKIT_MODULE_DIR , true
    # 如果没有，再寻找最近的fekit.config
    basepath = utils.path.closest options.cwd , 'fekit.config' unless basepath 
    # 再没有，则使用当前目录
    basepath = options.cwd unless basepath

    config_path = utils.path.join( basepath , 'fekit.config' )

    if !basepath then basepath = options.cwd

    if spec_pkg
        #单独安装
        spec_pkg = spec_pkg.split('@')
        name = spec_pkg[0]
        ver = spec_pkg[1]

        if options.useconfig 
            ver = getPackageConfig( config_path , name )
            unless ver
                utils.logger.error("在 fekit.config 中找不到关于 #{name} 组件依赖配置.")
                return

        p = new Package( name , ver , basepath )
        # 安装检查
        p.preinstall ( err ) ->
            return doneCallback( err ) if err
            # 真正安装
            p.install ( err ) ->
                return doneCallback( err ) if err
                unless options.useconfig then saveToConfig( config_path , p.name , p.version )
                p.report()

    else
        #根据配置安装
        config = utils.config.parse config_path

        p = new Package()
        p.loadConfig( utils.path.dirname( config_path ) , config.root )
        # 安装检查
        p.preinstall ( err ) ->
            return doneCallback( err ) if err
            # 真正安装
            p.install ( err ) ->
                return doneCallback( err ) if err
                p.report()







