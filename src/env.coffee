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


exports.getPackageUrl = ( name , version ) ->
    
    registry = CONFIG['registry']

    registry = registry.replace(/http:\/\//,'').replace(/\/.*/,'')

    "http://#{registry}/#{name}/" + ( if version then version else "" )

###
#  返回 ~/.fekit/.extensions/ 下的已安装扩展
#
#  其中文件内容为,例: 
#       svn.js     
#           exports.path = "xxx/xxx/.js"
#  
###
exports.getExtensions = () ->
    up = utils.path
    dir = up.join up.get_user_home() , ".fekit" , ".extensions"
    list = []
    up.each_directory( dir , ( (p) -> 
        ext = require(p)
        if ext.path && ext.version
            list.push( _.extend( ext , {
                    name : up.fname(p) 
                }) )
    ) , false )
    return list

merge_user_config()