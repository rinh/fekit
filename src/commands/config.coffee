utils = require '../util'
env = require '../env'

r = console.info

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
        env.set key , val
        utils.logger.log "已设置 #{key} 为 #{val}"

    else if options['delete'] 
    
        key = options['delete'] 
        env.del key 
        utils.logger.log "已删除 #{key}"

    else 

        show()


    

