utils = require '../util'
env = require '../env'

r = console.info
cpath = utils.path.join( utils.path.get_user_home() , ".fekitrc" )

exports.getCofnig = getConfig = () ->
    return utils.file.io.readJSON( cpath )

exports.setCofnig = setConfig = ( config ) ->
    utils.file.io.write cpath , JSON.stringify( config )


exports.set = Set = ( key , value ) ->
    d = getConfig()
    d[key] = value
    setConfig( d )

exports.del = Del = ( key ) ->
    d = getConfig()
    delete d[key]
    setConfig( d )


show = () ->
    r "\n"
    env.each ( key , value ) ->
        r ";   #{key}  =  \"#{value}\""
    r "\n"


exports.usage = "显示 fekit 的配置项"


exports.set_options = ( optimist ) ->
    optimist.alias 's' , 'set'
    optimist.describe 's' , '增加一个配置项 fekit -s [key] [value]'

    optimist.alias 'd' , 'delete'
    optimist.describe 'd' , '删除一个配置项 fekit -d [key]'


exports.run = ( options ) ->

    if options.set and options._[0] is 'config' and options._[1]
        key = options.set
        val = options._[1] or 0
        Set key , val
        utils.logger.log "已设置 #{key} 为 #{val}"

    else if options['delete'] 
    
        key = options['delete'] 
        Del key 
        utils.logger.log "已删除 #{key}"

    else 

        show()


    

