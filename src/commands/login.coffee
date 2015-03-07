env = require('../env')
utils = require '../util'
_ = require 'underscore'
async = require 'async'
prompt = require 'prompt'


exports.usage = "登录至源服务器"


exports.set_options = ( optimist ) ->
    optimist


exports.run = ( options ) ->
    

    prompt.start()

    prompt.get schema , ( err , result ) ->

        return if err 

        utils.http.put env.getRegistryUrl('/user/signin') , {
                username : result.username 
                password : result.password
            }, ( err , body , res ) ->
                if err then return utils.logger.error( err )
                body = JSON.parse body 
                unless body.ret then return utils.logger.error( body.errmsg )
                unless body.data then return utils.logger.error( "出现未知错误，请联系管理员." )
                unless body.data.name is result.username then return utils.logger.error( "出现未知错误，请联系管理员." )

                utils.file.io.write utils.path.join( utils.path.get_user_home() , ".fekit.pas" ) , body.data.password_md5
                env.set "user" , body.data.name

                utils.logger.log "#{body.data.name} 已登录成功"



#=====================

schema = 
    properties : 
        username : 
            pattern : /^.+$/i 
            required: true
            description: 'username'
        password : 
            pattern : /^.+$/
            required: true
            description: 'password'
            hidden: true

