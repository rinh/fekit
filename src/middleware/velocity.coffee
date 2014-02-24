# 解析 velocity 模板
urlrouter = require "urlrouter"
Velocity = require "velocityjs"
utils = require '../util'
sysurl = require "url"
syspath = require "path"


contentType = { 'Content-Type': "text/html;charset=UTF-8" }

module.exports = ( options ) ->

    ROOT = options.cwd
    
    return urlrouter (app) ->

        app.get /\.(vm|vmhtml)\b/ , ( req , res , next ) ->

            err = ( msg ) ->
                utils.logger.error msg
                res.writeHead 500, contentType
                res.end msg

            url = sysurl.parse( req.url )
            p = syspath.join( ROOT , url.pathname )
            txt = utils.file.io.read( p )
            dataPath = p.replace( '.vm' , '.json' )
            conf = utils.config.parse p

            _render = ( data , ctx , macros) ->
                return (new Velocity.Compile(Velocity.Parser.parse( data ))).render( ctx , macros)

            if utils.path.exists( dataPath )
                ctx = utils.file.io.readJSON( dataPath )
            else 
                ctx = {}

            ctx.esc = EscapeTool
            ctx.date = DateTool
            ctx.math = MathTool
            ctx.number = NumberTool

            macros = 
            
                load: ( path ) ->
                    return @jsmacros.parse.call @ , path
                ,
                parse: ( path ) ->
                    root = conf?.root?.development?.velocity_root
                    if root
                        root = utils.path.join( conf.fekit_root_dirname , root )
                        _p = utils.path.join( root , path.replace(/^\//,'./') )
                    else 
                        _p = utils.path.join( utils.path.dirname(p) , path )

                    content = utils.file.io.read( _p )
                    return _render content , @context , @macros
                ,
                ver: ( path ) ->
                    return ''

            res.writeHead 200, contentType
            res.end _render( txt , ctx , macros )


# ----------------------

EscapeTool = {}

EscapeTool.html = ( str ) ->
    return String( str ).replace( /&(?!\w+;)/g , '&amp;' )
    .replace( /</g , '&lt;' )
    .replace( />/g , '&gt;' )
    .replace( /"/g , '&quot;' )

EscapeTool.javascript = ( str ) ->
    return String( str ).replace( /\\/g , '\\\\' )
    .replace( /'/g , '\\\'' )
    .replace( /"/g , '\\\"' )
    .replace( /\//g , '//' )

EscapeTool.url = ( str ) ->
    return encodeURIComponent( str )

EscapeTool.java = ( str ) ->
    return String( str ).replace( /\\/g , '\\\\' )
    .replace( /\"/g , '\\\"' )

EscapeTool.json = ( str ) ->
    return String( str ).replace( /\\/g , '\\\\' )
    .replace( /\"/g , '\\\"' )
    .replace( /\//g , '//' )


# ----------------------

MathTool = {}

slice = ( arry , pos ) ->
    return Array.prototype.slice.call arry , pos

MathTool.add = ( num1 , num2 ) ->
    v = 0
    for tmp in arguments
        v += parseFloat(tmp)
    return v

MathTool.sub = ( num1 , num2 ) ->
    v = parseFloat( num1 )
    for tmp in slice( arguments , 1)
        v -= parseFloat(tmp)
    return v

MathTool.mul = ( num1 , num2 ) ->
    v = 1
    for tmp in arguments
        v *= parseFloat(~~tmp)
    return v

MathTool.div = ( num1 , num2 ) ->
    v = parseFloat(num1)
    for tmp in slice( arguments , 1)
        tmp = parseFloat(tmp)
        if tmp is 0
            return null
        v /= tmp
    return v

MathTool.max = ( num1 , num2 ) ->
    v = parseFloat(num1)
    for tmp in slice( arguments , 1 )
        tmp = parseFloat(tmp) 
        v < tmp and (v = tmp)
    return v

MathTool.min = ( num1 , num2 ) ->
    v = parseFloat(num1)
    for tmp in slice( arguments , 1 )
        tmp = parseFloat(tmp) 
        v > tmp and (v = tmp)
    return v

MathTool.pow = ( num1 , num2 ) ->
    if not num1 or not num2
        return null
    return Math.pow( num1 , num2 )

MathTool.floor = ( num1 , num2 ) ->
    if not num1 or not num2
        return null
    return Math.floor( num1 , num2 )

MathTool.idiv = ( num1 , num2 ) ->
    if not num1 or not num2 or ~~num2 is 0
        return null
    return ~~( ~~num1 / ~~num2 )

MathTool.mod = ( num1 , num2 ) ->
    if not num1 or not num2 or ~~num2 is 0
        return null
    return ~~( ~~num1 % ~~num2 )

MathTool.abs = ( num ) ->
    if not num
        return null
    return Math.abs( parseFloat( num ) )

MathTool.ceil = ( num ) ->
    if not num
        return null
    return ~~Math.ceil( parseFloat( num ) )

MathTool.random = () ->
    return Math.random()


# ----------------------

NumberTool = {}

NumberTool.interger = ( v ) ->
    return ~~v 

NumberTool.currency = ( v ) ->
    return '$' + v

NumberTool.percent = ( v ) ->
    return v * 100 + '%'

NumberTool.format = ( v ) ->
    return Math.round( v * 10 ) / 10

# ----------------------

DateTool = {}

DateTool.getSystemDate = () ->
    return new Date()

DateTool.getYear = () ->
    return new Date().getFullYear()

DateTool.getMonth = () ->
    return new Date().getMonth() + 1

DateTool.getDay = () ->
    return new Date().getDate()
    



