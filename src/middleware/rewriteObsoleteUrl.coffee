utils = require "../util"

## 转换旧项目(qzz)的url，方便开发
module.exports = _rewriteObsoleteUrl = ( options ) ->
    
    reg = /-(\d{16})/

    unless options.transfer
        return ( req , res , next ) ->
            next()
    
    return ( req , res , next ) ->
        
        return next() unless utils.UrlConvert.PRODUCTION_REGEX.test( req.url )

        return next() if req.query.no_dependencies

        if reg.test( req.url )
            req.url = req.url.replace reg , '@$1'

        next()