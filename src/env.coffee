_ = require 'underscore'
utils = require './util'

CONFIG = {
    registry : 'registry.fekit.org'
}

merge_user_config = () ->
    try 
        path = utils.path.join( utils.path.get_user_home() , ".fekitrc" )
        usr_conf = utils.file.io.readJSON path
        _.extend( CONFIG , usr_conf )
    catch err
        # nothing

exports.get = ( key ) ->
    CONFIG[key]


exports.each = ( cb ) ->
    cb( key , CONFIG[key] ) for key of CONFIG


merge_user_config()