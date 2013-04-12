env = require '../env'

r = console.info

exports.usage = "显示 fekit 的配置项"


exports.set_options = ( optimist ) ->
    optimist


exports.run = ( options ) ->

    r "\n"

    env.each ( key , value ) ->

        r ";   #{key}  =  \"#{value}\""

    r "\n"