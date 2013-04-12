_ = require 'underscore'
env = require '../env'
utils = require '../util'
async = require 'async'
Package = require '../package'

exports.usage = "安装 fekit 组件 "

exports.set_options = ( optimist ) ->
    optimist

exports.run = ( options ) ->

    start( options )


# ------------------------


doneCallback = ( err ) ->
    if err then utils.logger.error err.toString() 


start = ( options ) ->

    spec_pkg = options['_'][1]

    basepath = utils.path.closest options.cwd , Package.FEKIT_MODULE_DIR , true

    if !basepath then basepath = options.cwd

    if spec_pkg
        #单独安装
        spec_pkg = spec_pkg.split('@')

        p = new Package( spec_pkg[0] , spec_pkg[1] , basepath )
        # 安装检查
        p.preinstall ( err ) ->
            return doneCallback( err ) if err
            # 真正安装
            p.install ( err ) ->
                return doneCallback( err ) if err
                p.report()

    else
        #根据配置安装
        config = utils.config.parse utils.path.join( options.cwd , 'fekit.config' )
        deps = config.root.dependencies
        return if _.size( deps or {} ) is 0

        tasks = ( new Package( _name , _ver , basepath ) for _name , _ver of deps )

        # 真正安装
        check_all_done = ( err ) ->
            return doneCallback( err ) if err 
            async.each tasks 
                        , ( pkg , done ) ->
                            pkg.install ( err ) ->
                                done( err )
                        , ( err ) ->
                            pkg.report() for pkg in tasks
                            doneCallback()
        # 安装检查
        async.eachSeries tasks 
                        , ( pkg , done ) -> 
                            pkg.preinstall ( err ) ->
                                done( err )
                        , check_all_done







