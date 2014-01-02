_ = require 'underscore'
utils = require './util'

CONFIG = {
    registry : 'registry.fekit.org'
}

#----------------------

cpath = utils.path.join( utils.path.get_user_home() , ".fekitrc" )

exports.getUserConfig = getUserConfig = () ->
    return utils.file.io.readJSON( cpath )

exports.setUserConfig = setUserConfig = ( config ) ->
    utils.file.io.write cpath , JSON.stringify( config )


exports.set = Set = ( key , value ) ->
    d = getUserConfig()
    d[key] = value
    setUserConfig( d )

exports.del = Del = ( key ) ->
    d = getUserConfig()
    delete d[key]
    setUserConfig( d )

#-----------------------

merge_user_config = () ->
    try 
        _.extend( CONFIG , getUserConfig() )
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


exports.getRegistryUrl = getRegistryUrl=  ( path ) ->
    return 'http://' + CONFIG['registry'].replace('http://','').replace(/\//g,'') + path 

exports.getUserPasspharse = () ->
    pharse_file = utils.path.join( utils.path.get_user_home() , ".fekit.pas" )
    return utils.file.io.read( pharse_file )


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
    return list unless up.exists dir 
    up.each_directory( dir , ( (p) -> 
        ext = require(p)
        if ext.path && ext.version
            list.push( _.extend( ext , {
                    name : up.fname(p) 
                }) )
    ) , false )
    return list

exports.get_user_pharse_path = () ->
    return utils.path.join( utils.path.get_user_home() , ".fekit.pas" )

###
#  检查当前环境是否登录
###
exports.authorize = authorize = ( cb ) ->

    errmsg = "该功能需要登录后使用. 请执行 fekit login 进行登录. 如果没有注册，请到 fekit源 网站进行注册."
    
    pharse_file = utils.path.join( utils.path.get_user_home() , ".fekit.pas" )
    unless utils.path.exists( pharse_file ) then return cb( errmsg )
    unless CONFIG['user'] then return cb( errmsg )

    utils.http.put getRegistryUrl('/user/login_private_key') , {
        username : CONFIG['user']
        password : utils.file.io.read( pharse_file )
    } , ( err , body ) ->
        if err then return cb( err ) 
        body = JSON.parse body
        unless body.ret then return cb( body.errmsg ) 
        cb( null , body.data )

exports.authenticate = ( cb ) ->

    authorize ( err , body ) ->

        if err then return utils.logger.error( err )

        cb null , body 


merge_user_config()