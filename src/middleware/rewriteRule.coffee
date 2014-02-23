rewrite = require "connect-url-rewrite"

_routeRules = ( options ) ->
    
    list = []
    rs = [].concat( options.route || [] )

    for n in rs
        r = n.split(":")
        list.push( "#{r[0]} #{r[1]}" )
        utils.logger.log "已由 #{r[0]} 转发至 #{r[1]}" 

    return list


module.exports = ( options ) -> 

    return rewrite( _routeRules( options ) )