env = require('../env')
utils = require '../util'
_ = require 'underscore'
async = require 'async'
prompt = require 'prompt'


exports.usage = "登出"


exports.set_options = ( optimist ) ->
    optimist


exports.run = ( options ) ->
    
    user = env.get "user"

    if !user then return utils.logger.log "尚未登录"

    utils.file.rmrf utils.path.join( utils.path.get_user_home() , ".fekit.pas" )
    env.del "user"

    utils.logger.log "#{user} 已登出成功"

