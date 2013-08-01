async = require 'async'
utils = require '../util'
env = require '../env'


exports.usage = "更新自身及更新已安装扩展"

exports.set_options = ( optimist ) ->
    optimist

exports.run = ( options ) ->
    
    tasks = []

    tasks.push ( done ) ->
        utils.proc.spawn 'npm' , [ 'fekit' , '-g' ] , () ->
            done()

    for i in env.getExtensions()
        tasks.push ((name) ->
                return ( done ) ->
                    utils.proc.spawn 'npm' , [ 'fekit-extension-' + name , '-g' ] , () ->
                        done()
            )(i.name)


    async.series tasks , ( err ) ->
        if err then return utils.logger.error( err ) 
        utils.logger.log '升级完成.' 


