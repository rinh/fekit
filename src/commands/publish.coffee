env = require '../env'
request = require 'request'
utils = require '../util'
_ = require 'underscore'
async = require 'async'
temp = require 'temp'

exports.usage = "发布当前项目为组件包"


exports.set_options = ( optimist ) ->
    optimist


exports.run = ( options ) ->

    lifecycle(
        _.extend( {} , options ) , 
        [
            check_fekit_config_file ,
            valid_fekit_config ,
            tar_package , 
            pre_publish_hook , 
            upload_package 
        ]
    )


assert = ( opts , check_prop ) ->
    unless opts[check_prop]
        throw "在 options 中需要有 #{check_prop} ."

lifecycle = ( options , list ) ->

    get = (key) ->
        if options[key]
            return options[key]
        else 
            throw "not found option key [#{key}]"

    _list = list.map ( func ) ->
        return ( callback ) ->
            try 
                func options , callback
            catch err 
                callback err

    async.series _list , ( err ) ->
        if err 
            utils.logger.error err.toString()
        else 
            utils.logger.log "done."



# 确认当前目录是否有配置文件
exports.check_fekit_config_file = check_fekit_config_file = ( opts , done ) ->
    
    env.authenticate ( err ) ->

        if err then return done(err)

        assert opts , 'cwd'

        p = utils.path.join opts.cwd , 'fekit.config'

        if utils.path.exists p 
            opts.fekit_config_path = p
            done()
        else
            done "not found fekit.config"
    

# 验证当前文件配置
exports.valid_fekit_config = valid_fekit_config = ( opts , done ) ->
    
    assert opts , 'fekit_config_path'

    p = opts.fekit_config_path

    json = utils.file.io.readJSON p 

    if !json or !json.name or !json.version 
        throw "fekit.config 格式不正确"

    if json.compiler isnt 'component'
        throw "如果需要发布组件，则 fekit.config 中的 compiler 必须为 component"

    opts.config = json

    done()


# 压缩当前文件包
exports.tar_package = tar_package = ( opts , done ) ->
    
    assert opts , 'cwd'

    tmp = temp.path()
    tmp_targz = tmp + ".tgz"
    
    utils.tar.pack opts.cwd , tmp_targz , ( err ) ->

        if err then return done(err)

        opts.tar_path = tmp_targz

        done()


# prepublish hook
exports.pre_publish_hook = pre_publish_hook = ( opts , done ) ->

    conf = utils.config.parse( opts.fekit_config_path ) 

    conf.doScript 'prepublish'

    done()


# publish
exports.upload_package = upload_package = ( opts , done ) ->

    url = env.getPackageUrl( opts.config.name )

    utils.logger.trace "tar file: #{opts.tar_path}"

    utils.http.put url , opts.tar_path , {
            username : env.get('user') 
            password_md5 : env.getUserPasspharse()
        } , ( err , body ) ->

            if err 
                utils.logger.error err
                done()
                return

            json = JSON.parse( body or "{}" )

            unless json.ret 
                utils.logger.error json.errmsg
            else
                utils.logger.log "publish success."

            done()





